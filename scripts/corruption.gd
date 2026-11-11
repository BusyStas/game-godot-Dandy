extends CharacterBody3D
## The deck's three "Fatal" enemies. All kill instantly on touch.
##   soria   - hunts the player relentlessly (and faster once panic mode starts). Late floors only.
##   serrani - wanders until he hears noise (sprinting, repairing), then runs to where it came from.
##   surrena - hides inside the walls, then bursts out when the player is close.
## "Healthiest player" targeting for Soria needs multiplayer; solo, the player is always the target.

const KILL_RANGE := 1.3
const SIGHT_RANGE := 14.0

var kind := "serrani"
var bounds := Rect2(-18.0, -13.0, 36.0, 26.0)  ## x/z area for wandering

var _player: Node3D
var _revealed := true
var _dash_until := 0.0
var _heard_pos := Vector3.ZERO
var _heard_until := 0.0
var _wander := Vector3.ZERO
var _sight_timer := 0.0
var _visual: Node3D
var _label: Label3D


func _ready() -> void:
	add_to_group("corruption")
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)

	var colors := {"soria": Color(0.2, 0.65, 0.85), "serrani": Color(0.55, 0.3, 0.7), "surrena": Color(0.85, 0.2, 0.4)}
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colors.get(kind, Color(0.5, 0.5, 0.5))
	_visual = Node3D.new()
	add_child(_visual)
	var body := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.4
	cm.height = 1.5
	body.mesh = cm
	body.position.y = 0.75
	body.material_override = mat
	_visual.add_child(body)
	var head := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.3
	sm.height = 0.6
	head.mesh = sm
	head.position.y = 1.75
	head.material_override = mat
	_visual.add_child(head)
	_label = Label3D.new()
	_label.text = kind.capitalize()
	_label.position.y = 2.5
	_label.font_size = 36
	_label.pixel_size = 0.01
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_visual.add_child(_label)

	_revealed = kind != "surrena"
	_visual.visible = _revealed
	_pick_wander()


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _physics_process(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Node3D
		if _player == null:
			return
	var to_p := _player.global_position - global_position
	var dist := Vector2(to_p.x, to_p.z).length()

	_sight_timer -= delta
	if _sight_timer <= 0.0:
		_sight_timer = 0.25
		if dist < SIGHT_RANGE and _has_los():
			RoundManager.corruption_spotted(get_instance_id())

	var panic := RoundManager.state == RoundManager.State.PANIC or RoundManager.state == RoundManager.State.RETURN_TO_ELEVATOR
	var target := global_position
	var speed := 0.0
	match kind:
		"soria":
			target = _player.global_position
			speed = 3.2 * (1.4 if panic else 1.0)
		"serrani":
			if float(_player.call("current_noise")) > dist:
				_heard_pos = _player.global_position
				_heard_until = _now() + 6.0
			if _now() < _heard_until:
				target = _heard_pos
				speed = 5.0
			else:
				target = _wander_target()
				speed = 1.8
		"surrena":
			if not _revealed:
				if dist < 7.0 and _has_los():
					_revealed = true
					_visual.visible = true
					_dash_until = _now() + 3.0
			else:
				target = _player.global_position
				speed = 9.0 if _now() < _dash_until else 3.0

	_move_toward(target, speed, delta)
	if _revealed and dist < KILL_RANGE:
		RoundManager.kill_player("Caught by %s" % kind.capitalize())


func _wander_target() -> Vector3:
	if Vector2(_wander.x - global_position.x, _wander.z - global_position.z).length() < 1.5:
		_pick_wander()
	return _wander


func _pick_wander() -> void:
	# bounds is in global x/z coordinates (set by FloorBuilder)
	_wander = Vector3(
		randf_range(bounds.position.x, bounds.end.x),
		0.0,
		randf_range(bounds.position.y, bounds.end.y))


func _move_toward(pos: Vector3, speed: float, delta: float) -> void:
	var dir := pos - global_position
	dir.y = 0.0
	if speed <= 0.0 or dir.length() < 0.2:
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		dir = dir.normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		look_at(Vector3(pos.x, global_position.y, pos.z), Vector3.UP)
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()


func _has_los() -> bool:
	var space := get_world_3d().direct_space_state
	var from := global_position + Vector3(0, 1.5, 0)
	var to := _player.global_position + Vector3(0, 1.2, 0)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid(), _player.get_rid()]
	return space.intersect_ray(query).is_empty()
