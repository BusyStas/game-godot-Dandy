extends Node3D
## Programmatic lobby: floor, walls, 4 elevators, 3 shop counters, player, and a debug HUD.
## Walk into an elevator to start a run. Debug keys:
##   Enter     - ready up during the selection screen
##   T         - complete one task while on a floor
##   Backspace - abort the run and return to the lobby state

const PlayerScript := preload("res://scripts/player.gd")

var _hud: Label


func _ready() -> void:
	_add_environment()
	_add_floor_and_walls()
	_add_elevators()
	_add_shops()
	_add_player()
	_add_hud()
	RoundManager.state_changed.connect(func(_s): _refresh_hud())
	RoundManager.floor_started.connect(func(_m, _f): _refresh_hud())
	_refresh_hud()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	match event.keycode:
		KEY_ENTER:
			RoundManager.finish_selection()
		KEY_T:
			RoundManager.report_task_done()
			_refresh_hud()
		KEY_BACKSPACE:
			RoundManager.reset()


# --- building blocks -------------------------------------------------------

func _add_environment() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 30, 0)
	add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.08, 0.09, 0.12)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.5, 0.5, 0.55)
	add_child(env)


func _box(pos: Vector3, size: Vector3, color: Color, solid := true) -> Node3D:
	var root: Node3D
	if solid:
		root = StaticBody3D.new()
	else:
		root = Node3D.new()
	root.position = pos
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mesh.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	root.add_child(mesh)
	if solid:
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		cs.shape = bs
		root.add_child(cs)
	add_child(root)
	return root


func _label(text: String, pos: Vector3, size := 48) -> void:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = size
	l.pixel_size = 0.01
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(l)


func _add_floor_and_walls() -> void:
	_box(Vector3(0, -0.5, 0), Vector3(40, 1, 30), Color(0.25, 0.27, 0.3))
	var wall := Color(0.55, 0.55, 0.6)
	_box(Vector3(0, 2.5, -15), Vector3(40, 5, 1), wall)   # back (elevator wall)
	_box(Vector3(0, 2.5, 15), Vector3(40, 5, 1), wall)    # front
	_box(Vector3(-20, 2.5, 0), Vector3(1, 5, 30), wall)   # left
	_box(Vector3(20, 2.5, 0), Vector3(1, 5, 30), wall)    # right


func _add_elevators() -> void:
	for i in 4:
		var x := -9.0 + i * 6.0
		_box(Vector3(x, 1.5, -14.2), Vector3(3.5, 3, 0.4), Color(0.7, 0.7, 0.2), false)
		_label("Elevator %d" % (i + 1), Vector3(x, 3.6, -13.8))
		var trigger := Area3D.new()
		trigger.position = Vector3(x, 1.5, -12.5)
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(3.5, 3, 3)
		cs.shape = bs
		trigger.add_child(cs)
		trigger.body_entered.connect(_on_elevator_entered.bind(i + 1))
		add_child(trigger)


func _add_shops() -> void:
	_box(Vector3(-17, 0.75, -2), Vector3(3, 1.5, 6), Color(0.2, 0.5, 0.8))
	_label("Shop 1: Characters (Soria)", Vector3(-17, 3, -2), 36)
	_box(Vector3(17, 0.75, -6), Vector3(3, 1.5, 6), Color(0.2, 0.7, 0.4))
	_label("Shop 2: Skins (Serrani)", Vector3(17, 3, -6), 36)
	_box(Vector3(17, 0.75, 4), Vector3(3, 1.5, 6), Color(0.8, 0.5, 0.2))
	_label("Shop 3: Player Cards", Vector3(17, 3, 4), 36)
	_label("Starting area", Vector3(0, 3, 10), 36)


func _add_player() -> void:
	var player := CharacterBody3D.new()
	player.set_script(PlayerScript)
	player.position = Vector3(0, 0.5, 10)
	add_child(player)


# --- run flow + HUD ---------------------------------------------------------

func _on_elevator_entered(body: Node3D, elevator_number: int) -> void:
	if body is CharacterBody3D and RoundManager.state == RoundManager.State.LOBBY:
		print("Entered elevator %d - starting run" % elevator_number)
		RoundManager.start_run()


func _add_hud() -> void:
	var layer := CanvasLayer.new()
	_hud = Label.new()
	_hud.position = Vector2(16, 16)
	_hud.add_theme_font_size_override("font_size", 22)
	layer.add_child(_hud)
	add_child(layer)


func _refresh_hud() -> void:
	var s: int = RoundManager.state
	var lines := ["State: %s" % RoundManager.State.keys()[s]]
	if s != RoundManager.State.LOBBY:
		lines.append("Floor: %d" % RoundManager.floor_number)
	if RoundManager.current_map != "":
		lines.append("Map: %s" % RoundManager.current_map)
		lines.append("Tasks: %d / %d" % [RoundManager.tasks_done, RoundManager.tasks_total])
	match s:
		RoundManager.State.LOBBY:
			lines.append("WASD move, mouse look, Tab frees mouse. Walk into an elevator.")
		RoundManager.State.SELECTION:
			lines.append("Press Enter to ready up")
		RoundManager.State.FLOOR:
			lines.append("Press T to complete a task (debug)")
	lines.append("Backspace: return to lobby")
	_hud.text = "\n".join(lines)
