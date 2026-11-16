extends CharacterBody3D
## The Corruptions (mutated characters covered in Sonium, red glowing eyes). Stats come from GameData.CORRUPTIONS.
##   Fatal     sonia    hunts relentlessly, faster in panic. Instant kill.
##             serrani  wanders, runs to any noise he hears. Instant kill.
##             surrena  hides in a wall (ichor puddle marks the spot), pops out when you are close: shake free (A/D) or die.
##   Stalk     rencha   follows at a distance; once she has seen you: slowness for the floor + a chase. 2 damage.
##             cybot    follows Rencha, breaks machines (they leak Sonium), emits lots of light. 2 damage.
##             ivina    lives on the ceiling, drops on you (thorn minigame), grows poison plants. 2 damage.
##             bolten   very fast, dashes at you, lights up dark areas. 2 damage.
##   Friendler dreina   drops Sonium puddles that slow you and dim the screen; hard chunks stick and she chases harder. 1 damage.
## Interactions from the deck: Cybot + Rencha follow each other (Cybot breaking a machine next to Rencha boosts her),
## Surrena attacks Sonia if she is close, Serrani and Cybot have staring contests.
## "Healthiest player" targeting for Sonia needs multiplayer; solo, the player is always the target.

const KILL_RANGE := 1.3
const FOLLOW_RANGE := 5.0
const CHASE_SECONDS := 20.0

var kind := "serrani"
var bounds := Rect2(-18.0, -13.0, 36.0, 26.0)  ## global x/z area for wandering (set by FloorBuilder)

var _stats: Dictionary
var _player: Node3D
var _revealed := true
var _home := Vector3.ZERO
var _stun_until := 0.0
var _boost_until := 0.0
var _hit_cd := 0.0
var _sight_timer := 0.0
var _last_seen := -100.0
var _visual: Node3D
var _label: Label3D
var _wander := Vector3.ZERO

var _chase_until := 0.0
var _was_chasing := false
var _hurt_in_chase := false
var _follow_time := 0.0

var _heard_pos := Vector3.ZERO
var _heard_until := 0.0
var _was_hearing := false

var _grabbing := false
var _plant_timer := 8.0
var _plants: Array = []
var _drop_timer := 3.0
var _break_cd := 10.0
var _ivina_cool := 0.0
var _on_ceiling := true

var _inited := false
var _dash_end := 0.0
var _stare_with: Node = null
var _stare_until := 0.0
var _next_stare := 30.0
var _in_space := false
var _puddles: Array = []
var _mound: MeshInstance3D


func _ready() -> void:
	add_to_group("corruption")
	_stats = GameData.CORRUPTIONS[kind]
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)

	_visual = Node3D.new()
	add_child(_visual)
	_visual.add_child(CharacterModel.build(kind))
	_label = Label3D.new()
	_label.text = _stats["name"]
	_label.position.y = 2.5
	_label.font_size = 36
	_label.pixel_size = 0.01
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.layers = FloorBuilder.LABEL_LAYER
	_visual.add_child(_label)
	FloorBuilder.map_marker(_visual, Color(1.0, 0.1, 0.1), 1.1)

	# Cybot and Bolten give off lots of light (deck: "can emit lots of light, making them more visible")
	if kind == "cybot" or kind == "bolten":
		var lamp := OmniLight3D.new()
		lamp.position.y = 1.8
		lamp.omni_range = 11.0 if kind == "cybot" else 8.0
		lamp.light_energy = 2.2
		lamp.light_color = Color(1.0, 0.95, 0.75) if kind == "cybot" else Color(1.0, 0.85, 0.3)
		_visual.add_child(lamp)

	if kind == "surrena":
		_revealed = false
		_visual.visible = false
	elif kind == "shovelina":
		_mound = MeshInstance3D.new()   # a dirt mound shows where she is digging
		var mm := SphereMesh.new()
		mm.radius = 0.5
		mm.height = 0.5
		_mound.mesh = mm
		var dirt := StandardMaterial3D.new()
		dirt.albedo_color = Color(0.25, 0.15, 0.08)
		_mound.material_override = dirt
		add_child(_mound)
		_surface(false)
	_pick_wander()


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


## --- public hooks used by other Corruptions and the minigames --------------------------------

func stun(seconds: float) -> void:
	_stun_until = _now() + seconds


func boost(seconds: float) -> void:
	_boost_until = _now() + seconds


func begin_stare(other: Node) -> void:
	_stare_with = other
	_stare_until = 0.0


func is_staring() -> bool:
	return _stare_with != null


func minigame_result(success: bool) -> void:
	match kind:
		"surrena":
			_grabbing = false
			if success:
				RoundManager.research_event("surrena", "shake_free")
				RoundManager.grant_invulnerability(2.0)
				RoundManager.notice.emit("You shook free of Surrena!")
				stun(3.0)
				_hide_in_wall()
			else:
				RoundManager.kill_player("Caught by Surrena")
		"ivina":
			if success:
				RoundManager.research_event("ivina", "thorns_ok")
				RoundManager.notice.emit("You dodged Ivina's thorns!")
			else:
				RoundManager.damage(int(_stats["damage"]), "Ivina's thorns")
				RoundManager.poison()
			_ivina_cool = 25.0
			_enter_ceiling()
		"shovelina":
			_grabbing = false
			if success:
				RoundManager.research_event("shovelina", "shake_free")
				RoundManager.grant_invulnerability(2.0)
				RoundManager.notice.emit("You kicked free of Shovelina!")
			else:
				RoundManager.damage(int(_stats["damage"]), "Shovelina")
			stun(3.0)
			_chase_until = 0.0
			_surface(false)
		"minchei":
			_grabbing = false
			if success:
				RoundManager.research_event("minchei", "drag_escape")
				RoundManager.grant_invulnerability(2.0)
				RoundManager.notice.emit("You escaped Minchei - and now she is mad!")
				stun(2.5)
				boost(10.0)   # deck: "She gets mad if you run away"
				_chase_until = _now() + float(_stats["detect_time"])
			else:
				_drag_player()
				stun(3.0)


## --- main loop ---------------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if not _inited:
		# first frame: the spawner has placed us, so remember where "home" is
		_inited = true
		_home = global_position
		if kind == "surrena":
			_make_ichor_puddle()
		elif kind == "ivina":
			_enter_ceiling()
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Node3D
		if _player == null:
			return
	if not RoundManager.in_floor():
		return
	var now := _now()
	var to_p := _player.global_position - global_position
	var dist := Vector2(to_p.x, to_p.z).length()
	var panic := RoundManager.state == RoundManager.State.PANIC or RoundManager.state == RoundManager.State.RETURN_TO_ELEVATOR

	_sight_timer -= delta
	if _sight_timer <= 0.0:
		_sight_timer = 0.25
		_check_sight(dist)
	_track_research(delta, dist, now)

	var stunned := now < _stun_until
	var target := global_position
	var speed := 0.0
	var mult := 1.5 if now < _boost_until else 1.0

	if not stunned and not _grabbing and RoundManager.minigame_active == false:
		match kind:
			"sonia":
				target = _sonia_target()
				speed = float(_stats["speed"]) * (1.4 if panic else 1.0)
			"serrani":
				var r := _serrani(dist, now)
				target = r[0]
				speed = r[1]
			"surrena":
				var r := _surrena(dist, now)
				target = r[0]
				speed = r[1]
			"rencha":
				var r := _rencha(dist, to_p, now)
				target = r[0]
				speed = r[1]
			"cybot":
				var r := _cybot(dist, delta, now)
				target = r[0]
				speed = r[1]
			"ivina":
				_ivina(dist, delta, now)
			"bolten":
				var r := _bolten(dist, now)
				target = r[0]
				speed = r[1]
			"dreina":
				var r := _dreina(dist, delta, now)
				target = r[0]
				speed = r[1]
			"shovelina":
				var r := _shovelina(dist, now)
				target = r[0]
				speed = r[1]
			"limlem":
				var r := _limlem(dist, now)
				target = r[0]
				speed = r[1]
			"minchei":
				var r := _minchei(dist, now)
				target = r[0]
				speed = r[1]
	_stare_update(dist, now)
	if _stare_with != null and not stunned:
		var r := _stare_move()
		target = r[0]
		speed = r[1]

	if kind != "ivina" or not _on_ceiling:
		_move_toward(target, speed * mult, delta)

	# contact
	if _revealed and not stunned and not _grabbing and not (kind == "ivina") and dist < KILL_RANGE and absf(to_p.y) < 2.0:
		_contact()


func _contact() -> void:
	var dmg: int = int(_stats["damage"])
	if kind == "surrena":
		if not _grabbing and RoundManager.request_minigame("shake", self, {}):
			_grabbing = true
		return
	if kind == "shovelina":
		if not _grabbing and RoundManager.request_minigame("shake", self, {"title": "SHOVELINA HAS YOUR LEGS!", "presses": 12}):
			_grabbing = true
		return
	if kind == "minchei":
		if not _grabbing and RoundManager.request_minigame("drag", self, {}):
			_grabbing = true
		return
	if dmg >= 999:
		RoundManager.kill_player("Caught by %s" % _stats["name"])
		return
	if kind == "rencha" and _now() >= _chase_until:
		return   # she only hits while chasing
	var now := _now()
	if now < _hit_cd:
		return
	_hit_cd = now + 1.6
	_hurt_in_chase = true
	RoundManager.damage(dmg, _stats["name"])
	stun(1.2 if kind != "bolten" else 1.8)   # recoil, so you get a moment to run


## --- sight and research ------------------------------------------------------------------------

func _check_sight(dist: float) -> void:
	var sees: bool
	if kind == "ivina" or kind == "shovelina":
		sees = dist < float(_stats["sight"])
	else:
		sees = _revealed and dist < float(_stats["sight"]) and _has_los()
	if not sees:
		return
	var now := _now()
	if now - _last_seen > 15.0:
		RoundManager.warn_monster(kind)
		RoundManager.research_event(kind, "found")
	_last_seen = now
	RoundManager.corruption_spotted(get_instance_id())
	match kind:
		"rencha":
			RoundManager.apply_slow()
			if now >= _chase_until:
				_chase_until = now + CHASE_SECONDS
		"bolten", "cybot", "dreina", "shovelina", "minchei":
			if now >= _chase_until:
				_chase_until = now + float(_stats["detect_time"])   # deck: detection time = how long it keeps chasing after losing you


func _is_chasing(dist: float) -> bool:
	var now := _now()
	match kind:
		"sonia":
			return dist < 25.0
		"serrani":
			return now < _heard_until and dist < 25.0
		"surrena":
			return _revealed and not _grabbing
		"ivina":
			return false
	return now < _chase_until


func _track_research(delta: float, dist: float, now: float) -> void:
	# stalking: within 5 m for a while without leaving
	if dist < FOLLOW_RANGE and _revealed:
		_follow_time += delta
		RoundManager.research_event(kind, "follow", _follow_time, true)
	else:
		_follow_time = 0.0
	var chasing := _is_chasing(dist)
	if chasing:
		RoundManager.research_event(kind, "chased", delta)
		if kind == "rencha" and RoundManager.slow_factor < 1.0:
			RoundManager.research_event(kind, "chased_slowed", delta)
		if kind == "sonia" and not _was_chasing:
			RoundManager.research_event(kind, "chosen")   # solo stand-in for "chosen over another person"
	if kind == "bolten" and _was_chasing and not chasing and not _hurt_in_chase:
		RoundManager.research_event(kind, "survive_chase")
	if chasing and not _was_chasing:
		_hurt_in_chase = false
	_was_chasing = chasing


## --- per-kind behaviour: each returns [target position, speed] ----------------------------------

func _sonia_target() -> Vector3:
	return _player.global_position


func _serrani(dist: float, now: float) -> Array:
	var hear: float = minf(float(_player.call("current_noise")), float(_stats["hearing"]))
	if hear > dist:
		_heard_pos = _player.global_position
		_heard_until = now + 6.0
		if not _was_hearing:
			RoundManager.research_event("serrani", "heard")
		_was_hearing = true
	elif now >= _heard_until:
		_was_hearing = false
	if now < _heard_until:
		return [_heard_pos, 5.0]
	return [_wander_target(), float(_stats["speed"])]


func _surrena(dist: float, now: float) -> Array:
	# aggressive when Sonia is close: pop out of the wall and stun her
	var sonia := _nearest("sonia", 14.0)
	if sonia != null:
		if not _revealed:
			_reveal(now)
		if sonia.global_position.distance_to(global_position) < 1.8:
			sonia.call("stun", 4.0)
			_hide_in_wall()
			return [global_position, 0.0]
		return [sonia.global_position, 7.0]
	if not _revealed:
		if dist < float(_stats["sight"]) and _has_los():   # solo: the player is always "alone"
			_reveal(now)
			RoundManager.warn_monster(kind)
		return [global_position, 0.0]
	return [_player.global_position, 9.0 if now < _dash_end else 3.0]


func _reveal(now: float) -> void:
	_revealed = true
	_visual.visible = true
	_dash_end = now + 3.0
	_last_seen = now


func _hide_in_wall() -> void:
	_revealed = false
	_visual.visible = false
	global_position = _home


func _rencha(dist: float, to_p: Vector3, now: float) -> Array:
	var chasing := now < _chase_until
	if chasing:
		return [_player.global_position, float(_stats["speed"])]
	if dist > 7.5:
		return [_player.global_position, 3.5]
	if dist < 5.0:
		return [global_position - to_p.normalized() * 3.0, 2.5]
	return [global_position, 0.0]


func _cybot(dist: float, delta: float, now: float) -> Array:
	if now < _chase_until:
		return [_player.global_position, float(_stats["speed"])]
	_break_cd -= delta
	var rencha := _nearest("rencha", 200.0)
	var machine := _machine_target()
	if machine != null and _break_cd <= 0.0:
		var md := global_position.distance_to(machine.global_position)
		if md < 2.2:
			machine.call("break_machine")
			_break_cd = 25.0
			if _player.global_position.distance_to(machine.global_position) < 14.0:
				RoundManager.research_event("cybot", "saw_break")
			if rencha != null and rencha.global_position.distance_to(global_position) < 7.0:
				rencha.call("boost", 8.0)   # deck: Cybot breaking a machine next to Rencha gives her a speed boost
			return [global_position, 0.0]
		return [machine.global_position, 2.6]
	if rencha != null and rencha.global_position.distance_to(global_position) > 3.5:
		return [rencha.global_position, 3.0]   # follows Rencha
	return [_wander_target(), 1.8]


func _machine_target() -> Node3D:
	var best: Node3D = null
	var best_d := 1e9
	for m in get_tree().get_nodes_in_group("machines"):
		if bool(m.get("done")) or bool(m.get("broken")):
			continue
		var d := global_position.distance_to((m as Node3D).global_position)
		if d < best_d:
			best_d = d
			best = m
	return best


func _ivina(dist: float, delta: float, now: float) -> void:
	_ivina_cool = maxf(0.0, _ivina_cool - delta)
	# grow poison plants around herself
	_plant_timer -= delta
	if _plant_timer <= 0.0:
		_plant_timer = 14.0
		_grow_plant()
	if _on_ceiling and _ivina_cool <= 0.0 and dist < 4.5 and not RoundManager.minigame_active:
		# she drops from the ceiling right above you
		global_position = Vector3(_player.global_position.x, 2.2, _player.global_position.z)
		_on_ceiling = false
		_visual.rotation.z = 0.0
		if RoundManager.request_minigame("thorns", self, {}):
			RoundManager.warn_monster(kind)
		else:
			_enter_ceiling()


func _grow_plant() -> void:
	if _plants.size() >= 6:
		var old: Node = _plants.pop_front()
		if is_instance_valid(old):
			old.queue_free()
	var plant := Node3D.new()
	plant.set_script(load("res://scripts/hazard.gd"))
	plant.set("type", "plant")
	var spot := Vector3(
		clampf(_home.x + randf_range(-10.0, 10.0), bounds.position.x, bounds.end.x), 0.0,
		clampf(_home.z + randf_range(-10.0, 10.0), bounds.position.y, bounds.end.y))
	get_parent().add_child(plant)
	plant.global_position = spot
	_plants.append(plant)


func _enter_ceiling() -> void:
	_on_ceiling = true
	global_position = Vector3(_home.x, 4.9, _home.z)
	velocity = Vector3.ZERO
	_visual.rotation.z = PI   # hanging upside down


func _bolten(dist: float, now: float) -> Array:
	if now < _chase_until:
		return [_player.global_position, float(_stats["speed"])]
	return [_wander_target(), 4.5]


func _dreina(dist: float, delta: float, now: float) -> Array:
	_drop_timer -= delta
	if _drop_timer <= 0.0 and dist < 30.0:
		_drop_timer = 3.5
		_drop_puddle()
	var chunked := RoundManager.is_chunked()
	if chunked:
		return [_player.global_position, float(_stats["speed"]) * 1.5]
	if now < _chase_until or dist < 15.0:
		return [_player.global_position, float(_stats["speed"])]
	return [_wander_target(), 2.0]


func _surface(show: bool) -> void:
	_revealed = show
	_visual.visible = show
	if _mound != null:
		_mound.visible = not show


## Shovelina digs under the ground toward noise and anyone near, then pops up to grab your legs.
func _shovelina(dist: float, now: float) -> Array:
	var hear: float = minf(float(_player.call("current_noise")), float(_stats["hearing"]))
	if hear > dist and now >= _chase_until:
		_chase_until = now + 4.0
	if _revealed and dist > 7.5:
		_surface(false)
	elif not _revealed and dist < 5.5:
		_surface(true)
	if now < _chase_until:
		return [_player.global_position, float(_stats["speed"])]
	return [_wander_target(), 2.0]


## Lim & Lem sit in one spot and punish anyone who invades their space.
func _limlem(dist: float, now: float) -> Array:
	if _in_space and dist > 6.5:
		_in_space = false
		if not _hurt_in_chase:
			RoundManager.research_event("limlem", "space_escape")
	if dist < 3.2:
		_in_space = true
		_chase_until = now + 1.0
	var from_home := Vector2(global_position.x - _home.x, global_position.z - _home.z).length()
	if now < _chase_until and from_home < 7.0:
		return [_player.global_position, float(_stats["speed"])]
	return [_home, 3.0]


## Minchei is blind: she roams, feels for noise and anything close, and drags it to the other Corruptions.
func _minchei(dist: float, now: float) -> Array:
	var hear: float = minf(float(_player.call("current_noise")), float(_stats["hearing"]))
	if hear > dist:
		_heard_pos = _player.global_position
		_heard_until = now + 5.0
	if now < _chase_until:
		return [_player.global_position, float(_stats["speed"]) + 0.6]
	if now < _heard_until:
		return [_heard_pos, float(_stats["speed"])]
	return [_wander_target(), 2.0]


## A failed escape: she drags you next to another Corruption (a Fatal if one is around).
func _drag_player() -> void:
	var best: Node3D = null
	for c in get_tree().get_nodes_in_group("corruption"):
		if c == self or not (c is Node3D):
			continue
		var cls: String = GameData.CORRUPTIONS[c.get("kind")]["cls"]
		if best == null or (cls == "fatal" and GameData.CORRUPTIONS[best.get("kind")]["cls"] != "fatal"):
			best = c
	RoundManager.damage(int(_stats["damage"]), "Minchei")
	if best != null:
		_player.global_position = best.global_position + Vector3(1.8, 0.2, 0.0)
		RoundManager.notice.emit("Minchei dragged you to %s!" % GameData.CORRUPTIONS[best.get("kind")]["name"])


func _drop_puddle() -> void:
	var puddle := Node3D.new()
	puddle.set_script(load("res://scripts/hazard.gd"))
	# occasionally she drops a hard chunk of herself into the puddle
	puddle.set("type", "hard" if randf() < 0.25 else "puddle")
	get_parent().add_child(puddle)
	puddle.global_position = Vector3(global_position.x, 0.0, global_position.z)
	# keep only her most recent puddles so a long chase cannot pile up nodes
	_puddles.append(puddle)
	while _puddles.size() > 14:
		var old = _puddles.pop_front()
		if is_instance_valid(old):
			old.queue_free()


## --- Serrani <-> Cybot staring contests (deck: "Corruption Basics 3") ---------------------------

func _stare_update(dist: float, now: float) -> void:
	# Serrani starts a contest now and then if Cybot is on the floor and you are not close
	if kind == "serrani" and _stare_with == null and now >= _next_stare and dist > 14.0:
		var cy := _nearest("cybot", 200.0)
		if cy != null and not bool(cy.call("is_staring")):
			_stare_with = cy
			_stare_until = 0.0
			cy.call("begin_stare", self)
	if _stare_with == null:
		return
	if not is_instance_valid(_stare_with):
		_stare_with = null
		return
	var other_d := global_position.distance_to((_stare_with as Node3D).global_position)
	if _stare_until == 0.0 and other_d < 3.5:
		_stare_until = now + 30.0
		_stare_with.set("_stare_until", now + 30.0)
	# interrupted: you get close or make noise near them -> both get a speed boost
	var noisy := float(_player.call("current_noise")) > dist
	if dist < 6.0 or (noisy and dist < 20.0):
		boost(15.0)
		_stare_with.call("boost", 15.0)
		_end_stare()
	elif _stare_until > 0.0 and now >= _stare_until:
		_end_stare()   # uninterrupted: you got about half a minute of peace


func _end_stare() -> void:
	var other := _stare_with
	_stare_with = null
	_stare_until = 0.0
	_next_stare = _now() + 120.0
	if other != null and is_instance_valid(other) and other.get("_stare_with") != null:
		other.set("_stare_with", null)
		other.set("_stare_until", 0.0)


func _stare_move() -> Array:
	if not is_instance_valid(_stare_with):
		return [global_position, 0.0]
	var op := (_stare_with as Node3D).global_position
	if _stare_until > 0.0:
		look_at(Vector3(op.x, global_position.y, op.z), Vector3.UP)
		return [global_position, 0.0]
	return [op, 2.5]


## --- helpers -------------------------------------------------------------------------------

func _nearest(other_kind: String, max_dist: float) -> Node3D:
	var best: Node3D = null
	var best_d := max_dist
	for c in get_tree().get_nodes_in_group("corruption"):
		if c == self or c.get("kind") != other_kind:
			continue
		var d := global_position.distance_to((c as Node3D).global_position)
		if d < best_d:
			best_d = d
			best = c
	return best


func _make_ichor_puddle() -> void:
	# an ichor puddle on the wall warns that Surrena lies inside (deck: "Corruption Basics 2")
	var dl := global_position.x - bounds.position.x
	var dr := bounds.end.x - global_position.x
	var dz := bounds.end.y - global_position.z
	var pos := global_position
	var rot := 0.0
	if dz <= dl and dz <= dr:
		pos = Vector3(global_position.x, 1.3, bounds.end.y + 1.45)
		rot = PI                    # wall at +z faces -z
	elif dl < dr:
		pos = Vector3(bounds.position.x - 1.45, 1.3, global_position.z)
		rot = -PI / 2.0             # wall at -x faces +x
	else:
		pos = Vector3(bounds.end.x + 1.45, 1.3, global_position.z)
		rot = PI / 2.0
	var quad := QuadMesh.new()
	quad.size = Vector2(1.7, 1.2)
	var m := MeshInstance3D.new()
	m.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.0, 0.35)
	mat.emission_enabled = true
	mat.emission = Color(0.4, 0.0, 0.5)
	mat.emission_energy_multiplier = 0.6
	mat.metallic = 0.5
	mat.roughness = 0.1
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.material_override = mat
	m.top_level = true
	add_child(m)
	m.global_position = pos
	m.rotation.y = rot
	# a darker drip below it
	var drip := MeshInstance3D.new()
	var dq := QuadMesh.new()
	dq.size = Vector2(0.35, 0.8)
	drip.mesh = dq
	drip.material_override = mat
	drip.position = Vector3(0.2, -0.9, 0.001)
	m.add_child(drip)


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
