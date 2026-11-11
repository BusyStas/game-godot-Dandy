extends Node
## Round loop + persistent player state (autoload).
## lobby -> elevator countdown -> selection -> pre-floor elevator (~15s) -> floor (tasks)
## -> panic mode -> return to elevator (90s) -> results -> next floor.
## Authority (rewards, task progress, deaths) should live on the server once networking exists.

signal state_changed(new_state: State)
signal floor_started(map_name: String, floor_number: int)
signal floor_ended          ## return timer ran out; listeners may kill the run
signal sonium_changed(total: int)
signal player_died(reason: String)
signal notice(text: String)

enum State { LOBBY, COUNTDOWN, SELECTION, PRE_FLOOR_ELEVATOR, FLOOR, PANIC, RETURN_TO_ELEVATOR, RESULTS }

const COUNTDOWN_SECONDS := 5.0       # PLACEHOLDER, not in the deck
const SELECTION_SECONDS := 30.0      # PLACEHOLDER, not in the deck
const PRE_FLOOR_SECONDS := 15.0
const RETURN_SECONDS := 90.0
const RESULTS_SECONDS := 5.0
const MACHINE_REWARD := 10
const CONTAINER_REWARD := 5
const CHALLENGE_BONUS := 100         # PLACEHOLDER: reward for beating a shop-character challenge floor
const SAVE_PATH := "user://save.cfg"

var state: State = State.LOBBY
var floor_number := 1
var current_map := ""
var task_kind := "machines"
var tasks_total := 0
var tasks_done := 0
var machine_count := 3
var container_count := 2
var corruption_count := 1
var slow_factor := 1.0   ## <1 once Rencha has seen the player on this floor

var sonium := 0
var best_floor := 0
var starter_chosen := false
var owned := {"characters": [], "skins": ["default"], "decorations": ["none"]}
var loadout := {"character": "recruit", "skin": "default", "utility": "none", "decoration": "none"}

var _timer: SceneTreeTimer
var _run_id := 0
var _spotted := {}


func _ready() -> void:
	_load()


func _unhandled_input(event: InputEvent) -> void:
	## Global shortcut: X quits the game from any screen.
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_X:
		_save()
		get_tree().quit()


# --- run flow -------------------------------------------------------------------

func start_run() -> void:
	if state != State.LOBBY:
		return
	_run_id += 1
	floor_number = 1
	_set_state(State.COUNTDOWN)
	_after(COUNTDOWN_SECONDS, _enter_selection)


func finish_selection() -> void:
	if state != State.SELECTION:
		return
	_set_state(State.PRE_FLOOR_ELEVATOR)
	_after(PRE_FLOOR_SECONDS, _begin_floor)


func reset() -> void:
	_run_id += 1
	_timer = null
	current_map = ""
	tasks_done = 0
	tasks_total = 0
	_spotted.clear()
	slow_factor = 1.0
	_set_state(State.LOBBY)


func time_left() -> float:
	if _timer == null:
		return 0.0
	return maxf(_timer.time_left, 0.0)


func in_floor() -> bool:
	return state == State.FLOOR or state == State.PANIC or state == State.RETURN_TO_ELEVATOR


func report_task_done() -> void:
	if state != State.FLOOR:
		return
	tasks_done += 1
	if tasks_done >= tasks_total:
		if current_map.begins_with("CL"):
			add_sonium(CHALLENGE_BONUS)
			notice.emit("Challenge beaten! +%d Sonium" % CHALLENGE_BONUS)
		_set_state(State.PANIC)
		_set_state(State.RETURN_TO_ELEVATOR)
		_after(RETURN_SECONDS, _end_floor)


# --- gameplay events ------------------------------------------------------------

func machine_fixed() -> void:
	add_sonium(MACHINE_REWARD)
	if task_kind == "machines":
		report_task_done()


func container_opened() -> void:
	add_sonium(CONTAINER_REWARD)
	if task_kind == "containers":
		report_task_done()


func corruption_spotted(id: int) -> void:
	if not in_floor() or _spotted.has(id):
		return
	_spotted[id] = true
	add_sonium(randi_range(1, 2))
	if task_kind == "spotted":
		report_task_done()


func apply_slow() -> void:
	## Rencha's ability: once it has seen you, you are slowed for the rest of the floor.
	if slow_factor < 1.0:
		return
	slow_factor = 0.8
	notice.emit("Rencha is stalking you - you feel slower.")


func spotted_count() -> int:
	return _spotted.size()


func kill_player(reason: String) -> void:
	if not in_floor():
		return
	if floor_number > best_floor:
		best_floor = floor_number
		_save()
	player_died.emit("%s (floor %d, best %d)" % [reason, floor_number, best_floor])
	reset()


func add_sonium(amount: int) -> void:
	sonium += amount
	sonium_changed.emit(sonium)
	_save()


# --- shop / loadout -------------------------------------------------------------

func choose_starter(id: String) -> void:
	starter_chosen = true
	if not owned["characters"].has(id):
		owned["characters"].append(id)
	loadout["character"] = id
	_save()


func buy(category: String, id: String) -> bool:
	var items: Dictionary = GameData.items(category)
	if not items.has(id) or owned[category].has(id):
		return false
	var price: int = items[id]["price"]
	if sonium < price:
		return false
	sonium -= price
	owned[category].append(id)
	sonium_changed.emit(sonium)
	_save()
	return true


func set_loadout(key: String, id: String) -> void:
	loadout[key] = id
	_save()


# --- internals ------------------------------------------------------------------

func _enter_selection() -> void:
	_set_state(State.SELECTION)
	_after(SELECTION_SECONDS, finish_selection)


func _begin_floor() -> void:
	current_map = MapPicker.pick(floor_number)
	var th: Dictionary = GameData.theme(current_map)
	task_kind = th["task"]
	machine_count = clampi(3 + floori(floor_number / 8.0), 3, 6)
	container_count = 5 if task_kind == "containers" else 2
	corruption_count = clampi(1 + floori(floor_number / 6.0), 1, 4)
	if task_kind == "spotted":
		corruption_count = maxi(corruption_count, 2)
	if current_map.begins_with("CL"):
		corruption_count += 1
	match task_kind:
		"containers":
			tasks_total = container_count
		"spotted":
			tasks_total = corruption_count
		_:
			tasks_total = machine_count
	tasks_done = 0
	_spotted.clear()
	slow_factor = 1.0
	_set_state(State.FLOOR)
	floor_started.emit(current_map, floor_number)
	if GameData.LORE.has(current_map):
		notice.emit(GameData.LORE[current_map])


func _end_floor() -> void:
	floor_ended.emit()
	if state != State.RETURN_TO_ELEVATOR:
		return
	if floor_number > best_floor:
		best_floor = floor_number
		_save()
	_set_state(State.RESULTS)
	floor_number += 1
	_after(RESULTS_SECONDS, _next_floor)


func _next_floor() -> void:
	_set_state(State.PRE_FLOOR_ELEVATOR)
	_after(PRE_FLOOR_SECONDS, _begin_floor)


func _set_state(s: State) -> void:
	state = s
	print("[RoundManager] state -> %s (floor %d)" % [State.keys()[s], floor_number])
	state_changed.emit(s)


func _after(seconds: float, callback: Callable) -> void:
	var id := _run_id
	_timer = get_tree().create_timer(seconds)
	_timer.timeout.connect(func():
		if id == _run_id:
			callback.call())


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("player", "sonium", sonium)
	cfg.set_value("player", "best_floor", best_floor)
	cfg.set_value("player", "starter_chosen", starter_chosen)
	cfg.set_value("player", "owned_characters", owned["characters"])
	cfg.set_value("player", "owned_skins", owned["skins"])
	cfg.set_value("player", "owned_decorations", owned["decorations"])
	for k in loadout:
		cfg.set_value("loadout", k, loadout[k])
	cfg.save(SAVE_PATH)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	sonium = int(cfg.get_value("player", "sonium", 0))
	best_floor = int(cfg.get_value("player", "best_floor", 0))
	starter_chosen = bool(cfg.get_value("player", "starter_chosen", false))
	owned["characters"] = Array(cfg.get_value("player", "owned_characters", []))
	owned["skins"] = Array(cfg.get_value("player", "owned_skins", ["default"]))
	owned["decorations"] = Array(cfg.get_value("player", "owned_decorations", ["none"]))
	for k in loadout:
		loadout[k] = str(cfg.get_value("loadout", k, loadout[k]))
