extends Node3D
## Lobby + run presentation. Builds the lobby, an elevator cabin, and (per run) a floor.
## Walk into an elevator to start a run. Debug keys:
##   Enter     - ready up during the selection screen
##   T         - complete one task while on a floor
##   Backspace - abort the run and return to the lobby

const PlayerScript := preload("res://scripts/player.gd")

const LOBBY_SPAWN := Vector3(0, 0.5, 10)
const CABIN_ORIGIN := Vector3(100, 0, 0)
const FLOOR_ORIGIN := Vector3(200, 0, 0)

var _player: CharacterBody3D
var _env: Environment
var _hud: Label
var _msg: Label
var _msg_until_ms := 0
var _floor_root: Node3D
var _floor_elevator: Area3D


func _ready() -> void:
	_add_environment()
	_add_floor_and_walls()
	_add_elevators()
	_add_shops()
	add_child(FloorBuilder.build_cabin(CABIN_ORIGIN))
	_add_player()
	_add_hud()
	RoundManager.state_changed.connect(_on_state_changed)
	RoundManager.floor_started.connect(_on_floor_started)
	RoundManager.floor_ended.connect(_on_floor_ended)


func _process(_delta: float) -> void:
	_refresh_hud()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	match event.keycode:
		KEY_ENTER:
			RoundManager.finish_selection()
		KEY_T:
			RoundManager.report_task_done()
		KEY_BACKSPACE:
			RoundManager.reset()


# --- run flow ------------------------------------------------------------------

func _on_state_changed(s: int) -> void:
	match s:
		RoundManager.State.LOBBY:
			_clear_floor()
			_set_panic(false)
			_teleport(LOBBY_SPAWN)
		RoundManager.State.COUNTDOWN, RoundManager.State.PRE_FLOOR_ELEVATOR:
			_clear_floor()
			_set_panic(false)
			_teleport(CABIN_ORIGIN + Vector3(0, 0.5, 0))
		RoundManager.State.PANIC:
			_set_panic(true)


func _on_floor_started(map_name: String, _floor_number: int) -> void:
	_clear_floor()
	var built := FloorBuilder.build_floor(map_name, RoundManager.tasks_total, FLOOR_ORIGIN)
	_floor_root = built["root"]
	_floor_elevator = built["elevator"]
	add_child(_floor_root)
	_teleport(built["spawn"])


func _on_floor_ended() -> void:
	if _floor_elevator and not _floor_elevator.overlaps_body(_player):
		_show_message("You didn't make it back to the elevator. You died.", 5000)
		RoundManager.reset()
	else:
		_show_message("Floor cleared!", 3000)


func _clear_floor() -> void:
	if _floor_root:
		_floor_root.queue_free()
		_floor_root = null
		_floor_elevator = null


func _teleport(pos: Vector3) -> void:
	if _player:
		_player.global_position = pos
		_player.velocity = Vector3.ZERO


func _set_panic(on: bool) -> void:
	_env.ambient_light_color = Color(0.9, 0.3, 0.3) if on else Color(0.5, 0.5, 0.55)


func _on_elevator_entered(body: Node3D, elevator_number: int) -> void:
	if body is CharacterBody3D and RoundManager.state == RoundManager.State.LOBBY:
		print("Entered elevator %d - starting run" % elevator_number)
		RoundManager.start_run()


# --- lobby geometry --------------------------------------------------------------

func _add_environment() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 30, 0)
	add_child(sun)
	var we := WorldEnvironment.new()
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.background_color = Color(0.08, 0.09, 0.12)
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color(0.5, 0.5, 0.55)
	we.environment = _env
	add_child(we)


func _add_floor_and_walls() -> void:
	FloorBuilder.box(self, Vector3(0, -0.5, 0), Vector3(40, 1, 30), Color(0.25, 0.27, 0.3))
	var wall := Color(0.55, 0.55, 0.6)
	FloorBuilder.box(self, Vector3(0, 2.5, -15), Vector3(40, 5, 1), wall)
	FloorBuilder.box(self, Vector3(0, 2.5, 15), Vector3(40, 5, 1), wall)
	FloorBuilder.box(self, Vector3(-20, 2.5, 0), Vector3(1, 5, 30), wall)
	FloorBuilder.box(self, Vector3(20, 2.5, 0), Vector3(1, 5, 30), wall)


func _add_elevators() -> void:
	for i in 4:
		var x := -9.0 + i * 6.0
		FloorBuilder.box(self, Vector3(x, 1.5, -14.2), Vector3(3.5, 3, 0.4), Color(0.7, 0.7, 0.2), false)
		FloorBuilder.label(self, "Elevator %d" % (i + 1), Vector3(x, 3.6, -13.8))
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
	FloorBuilder.box(self, Vector3(-17, 0.75, -2), Vector3(3, 1.5, 6), Color(0.2, 0.5, 0.8))
	FloorBuilder.label(self, "Shop 1: Characters (Soria)", Vector3(-17, 3, -2), 36)
	FloorBuilder.box(self, Vector3(17, 0.75, -6), Vector3(3, 1.5, 6), Color(0.2, 0.7, 0.4))
	FloorBuilder.label(self, "Shop 2: Skins (Serrani)", Vector3(17, 3, -6), 36)
	FloorBuilder.box(self, Vector3(17, 0.75, 4), Vector3(3, 1.5, 6), Color(0.8, 0.5, 0.2))
	FloorBuilder.label(self, "Shop 3: Player Cards", Vector3(17, 3, 4), 36)
	FloorBuilder.label(self, "Starting area", Vector3(0, 3, 10), 36)


func _add_player() -> void:
	_player = CharacterBody3D.new()
	_player.set_script(PlayerScript)
	_player.position = LOBBY_SPAWN
	add_child(_player)


# --- HUD -------------------------------------------------------------------------

func _add_hud() -> void:
	var layer := CanvasLayer.new()
	_hud = Label.new()
	_hud.position = Vector2(16, 16)
	_hud.add_theme_font_size_override("font_size", 22)
	layer.add_child(_hud)
	_msg = Label.new()
	_msg.position = Vector2(16, 300)
	_msg.add_theme_font_size_override("font_size", 32)
	layer.add_child(_msg)
	add_child(layer)


func _show_message(text: String, duration_ms: int) -> void:
	_msg.text = text
	_msg_until_ms = Time.get_ticks_msec() + duration_ms


func _refresh_hud() -> void:
	if Time.get_ticks_msec() > _msg_until_ms:
		_msg.text = ""
	var s: int = RoundManager.state
	var lines := ["State: %s" % RoundManager.State.keys()[s], "Sonium: %d" % RoundManager.sonium]
	if s != RoundManager.State.LOBBY:
		lines.append("Floor: %d" % RoundManager.floor_number)
	if RoundManager.current_map != "":
		lines.append("Map: %s" % RoundManager.current_map)
		lines.append("Tasks: %d / %d" % [RoundManager.tasks_done, RoundManager.tasks_total])
	match s:
		RoundManager.State.LOBBY:
			lines.append("WASD move, mouse look, Tab frees mouse. Walk into an elevator.")
		RoundManager.State.COUNTDOWN, RoundManager.State.PRE_FLOOR_ELEVATOR:
			lines.append("Time: %d s" % ceili(RoundManager.time_left()))
		RoundManager.State.SELECTION:
			lines.append("Selection screen (not built yet). Press Enter to ready up. Auto-starts in %d s" % ceili(RoundManager.time_left()))
		RoundManager.State.FLOOR:
			lines.append("Hold E near a machine to fix it. (T completes a task - debug)")
		RoundManager.State.PANIC, RoundManager.State.RETURN_TO_ELEVATOR:
			lines.append("RUN BACK TO THE ELEVATOR! %d s left" % ceili(RoundManager.time_left()))
	lines.append("Backspace: return to lobby")
	_hud.text = "\n".join(lines)
