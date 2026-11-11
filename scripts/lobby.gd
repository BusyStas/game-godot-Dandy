extends Node3D
## Lobby + run presentation: lobby, elevator cabin, per-run floor, shops, selection screen, HUD.
## Walk into an elevator to start a run. Keys:
##   WASD/mouse move+look, Shift sprint, E interact, F open a shop when standing near it
##   Enter confirms the selection screen; T completes a task (debug); Backspace aborts the run; X or Ctrl+C quits

const PlayerScript := preload("res://scripts/player.gd")
const SelectionScript := preload("res://scripts/selection_screen.gd")
const ShopScript := preload("res://scripts/shop_ui.gd")

const LOBBY_SPAWN := Vector3(0, 0.5, 10)
const CABIN_ORIGIN := Vector3(100, 0, 0)
const FLOOR_ORIGIN := Vector3(200, 0, 0)
const SHOP_RANGE := 5.0
const TITLE_SCENE := "res://scenes/title.tscn"

var _player: CharacterBody3D
var _env: Environment
var _hud: Label
var _msg: Label
var _msg_until_ms := 0
var _floor_root: Node3D
var _floor_elevator: Area3D
var _selection: CanvasLayer
var _shop: CanvasLayer
var _shops: Array = []   # [{pos: Vector3, category: String, name: String}]
var _near_shop := -1


func _ready() -> void:
	if not RoundManager.starter_chosen:
		get_tree().change_scene_to_file.call_deferred(TITLE_SCENE)
		return
	_add_environment()
	_add_floor_and_walls()
	_add_elevators()
	_add_shops()
	add_child(FloorBuilder.build_cabin(CABIN_ORIGIN))
	_add_player()
	_add_ui()
	RoundManager.state_changed.connect(_on_state_changed)
	RoundManager.floor_started.connect(_on_floor_started)
	RoundManager.floor_ended.connect(_on_floor_ended)
	RoundManager.player_died.connect(_on_player_died)
	RoundManager.notice.connect(func(t): _show_message(t, 6000))


func _process(_delta: float) -> void:
	if _hud == null:
		return
	_near_shop = -1
	if RoundManager.state == RoundManager.State.LOBBY and not _ui_open():
		for i in _shops.size():
			var p: Vector3 = _shops[i]["pos"]
			if Vector2(_player.global_position.x - p.x, _player.global_position.z - p.z).length() < SHOP_RANGE:
				_near_shop = i
	_refresh_hud()


func _unhandled_input(event: InputEvent) -> void:
	if _hud == null or not (event is InputEventKey and event.pressed):
		return
	match event.keycode:
		KEY_ENTER:
			if _selection.is_open():
				_selection.confirm()
		KEY_F:
			if _near_shop >= 0 and not _ui_open():
				_open_shop(_near_shop)
		KEY_T:
			RoundManager.report_task_done()
		KEY_BACKSPACE:
			RoundManager.reset()


# --- UI state ------------------------------------------------------------------

func _ui_open() -> bool:
	return _selection.is_open() or _shop.is_open()


func _sync_ui_lock() -> void:
	var open := _ui_open()
	_player.set("frozen", open)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if open else Input.MOUSE_MODE_CAPTURED


func _open_shop(index: int) -> void:
	_shop.open(_shops[index]["category"])
	_sync_ui_lock()


# --- run flow ------------------------------------------------------------------

func _on_state_changed(s: int) -> void:
	if s == RoundManager.State.LOBBY:
		_selection.close(false)
		_clear_floor()
		_set_panic(false)
		_teleport(LOBBY_SPAWN)
	elif s == RoundManager.State.COUNTDOWN:
		_clear_floor()
		_set_panic(false)
		_teleport(CABIN_ORIGIN + Vector3(0, 0.5, 0))
	elif s == RoundManager.State.SELECTION:
		_selection.open()
	elif s == RoundManager.State.PRE_FLOOR_ELEVATOR:
		_selection.close(true)   # auto-confirm if the timer ran out
		_player.call("apply_loadout")
		_clear_floor()
		_set_panic(false)
		_teleport(CABIN_ORIGIN + Vector3(0, 0.5, 0))
	elif s == RoundManager.State.PANIC:
		_set_panic(true)
	_sync_ui_lock()


func _on_floor_started(map_name: String, _floor_number: int) -> void:
	_clear_floor()
	var built := FloorBuilder.build_floor(map_name, FLOOR_ORIGIN, {
		"floor": RoundManager.floor_number,
		"machines": RoundManager.machine_count,
		"containers": RoundManager.container_count,
		"corruptions": RoundManager.corruption_count,
	})
	_floor_root = built["root"]
	_floor_elevator = built["elevator"]
	add_child(_floor_root)
	_teleport(built["spawn"])


func _on_floor_ended() -> void:
	if _floor_elevator and not _floor_elevator.overlaps_body(_player):
		RoundManager.kill_player("You didn't make it back to the elevator")
	else:
		_show_message("Floor cleared!", 3000)


func _on_player_died(reason: String) -> void:
	_show_message("YOU DIED\n%s" % reason, 7000)


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
	var defs := [
		{"pos": Vector3(-17, 0.75, -2), "size": Vector3(3, 1.5, 6), "color": Color(0.2, 0.5, 0.8), "category": "characters", "name": "Shop 1: Characters (Soria)"},
		{"pos": Vector3(17, 0.75, -6), "size": Vector3(3, 1.5, 6), "color": Color(0.2, 0.7, 0.4), "category": "skins", "name": "Shop 2: Skins (Serrani)"},
		{"pos": Vector3(17, 0.75, 4), "size": Vector3(3, 1.5, 6), "color": Color(0.8, 0.5, 0.2), "category": "decorations", "name": "Shop 3: Player Cards"},
	]
	for d in defs:
		FloorBuilder.box(self, d["pos"], d["size"], d["color"])
		FloorBuilder.label(self, d["name"], d["pos"] + Vector3(0, 2.3, 0), 36)
		_shops.append({"pos": d["pos"], "category": d["category"], "name": d["name"]})
	FloorBuilder.label(self, "Starting area", Vector3(0, 3, 10), 36)


func _add_player() -> void:
	_player = CharacterBody3D.new()
	_player.set_script(PlayerScript)
	_player.position = LOBBY_SPAWN
	add_child(_player)


# --- HUD -------------------------------------------------------------------------

func _add_ui() -> void:
	var layer := CanvasLayer.new()
	_hud = Label.new()
	_hud.position = Vector2(16, 16)
	_hud.add_theme_font_size_override("font_size", 20)
	layer.add_child(_hud)
	_msg = Label.new()
	_msg.position = Vector2(16, 380)
	_msg.add_theme_font_size_override("font_size", 30)
	layer.add_child(_msg)
	add_child(layer)

	_selection = SelectionScript.new()
	add_child(_selection)
	_shop = ShopScript.new()
	add_child(_shop)
	_shop.closed.connect(_sync_ui_lock)
	_selection.confirmed.connect(func():
		_sync_ui_lock()
		RoundManager.finish_selection())


func _show_message(text: String, duration_ms: int) -> void:
	_msg.text = text
	_msg_until_ms = Time.get_ticks_msec() + duration_ms


func _refresh_hud() -> void:
	if Time.get_ticks_msec() > _msg_until_ms:
		_msg.text = ""
	var s: int = RoundManager.state
	var ch: Dictionary = GameData.CHARACTERS.get(RoundManager.loadout["character"], GameData.CHARACTERS["recruit"])
	var skin: Dictionary = GameData.SKINS.get(RoundManager.loadout["skin"], GameData.SKINS["default"])
	var deco: Dictionary = GameData.DECORATIONS.get(RoundManager.loadout["decoration"], GameData.DECORATIONS["none"])
	var util: Dictionary = GameData.UTILITIES.get(RoundManager.loadout["utility"], GameData.UTILITIES["none"])
	var lines: Array = [
		"%s | %s | card: %s | %s" % [ch["name"], skin["name"], deco["name"], util["name"]],
		"Sonium: %d   Best floor: %d" % [RoundManager.sonium, RoundManager.best_floor],
		"State: %s" % RoundManager.State.keys()[s],
	]
	if s != RoundManager.State.LOBBY:
		lines.append("Floor: %d" % RoundManager.floor_number)
	if RoundManager.current_map != "":
		lines.append("Map: %s" % RoundManager.current_map)
		lines.append(_task_line())
	match s:
		RoundManager.State.LOBBY:
			if _near_shop >= 0:
				lines.append("Press F to open %s" % _shops[_near_shop]["name"])
			else:
				lines.append("WASD move, Shift sprint, mouse look, Tab frees mouse. Walk into an elevator.")
		RoundManager.State.COUNTDOWN, RoundManager.State.PRE_FLOOR_ELEVATOR:
			lines.append("Time: %d s" % ceili(RoundManager.time_left()))
		RoundManager.State.SELECTION:
			lines.append("Pick your loadout. Auto-confirms in %d s" % ceili(RoundManager.time_left()))
		RoundManager.State.FLOOR:
			lines.append("Beware the Corruptions. Sprinting and repairing are loud.")
		RoundManager.State.PANIC, RoundManager.State.RETURN_TO_ELEVATOR:
			lines.append("RUN BACK TO THE ELEVATOR! %d s left" % ceili(RoundManager.time_left()))
	if RoundManager.slow_factor < 1.0:
		lines.append("Slowed by Rencha for this floor")
	lines.append("Backspace: return to lobby   X or Ctrl+C: quit")
	_hud.text = "\n".join(lines)


func _task_line() -> String:
	var what := ""
	match RoundManager.task_kind:
		"containers":
			what = "Open every storage container (hold E)"
		"spotted":
			what = "Get spotted by every Corruption"
		_:
			what = "Fix the machines (E)"
	return "Task: %s  [%d / %d]" % [what, RoundManager.tasks_done, RoundManager.tasks_total]
