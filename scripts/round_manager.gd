extends Node
## Round loop state machine (autoload). Mirrors the design deck:
## lobby -> elevator countdown -> selection -> pre-floor elevator (~15s)
## -> floor (tasks) -> panic mode -> return to elevator (90s) -> results -> next floor.
## Authority (rewards, task progress, deaths) should live on the server once networking exists.

signal state_changed(new_state: State)
signal floor_started(map_name: String, floor_number: int)
signal floor_ended          ## emitted when the return timer runs out; listeners may call reset() to kill the run
signal sonium_changed(total: int)

enum State { LOBBY, COUNTDOWN, SELECTION, PRE_FLOOR_ELEVATOR, FLOOR, PANIC, RETURN_TO_ELEVATOR, RESULTS }

const COUNTDOWN_SECONDS := 5.0       # placeholder, not specified in the deck
const SELECTION_SECONDS := 30.0      # placeholder, not specified in the deck
const PRE_FLOOR_SECONDS := 15.0
const RETURN_SECONDS := 90.0
const RESULTS_SECONDS := 5.0
const TASKS_PER_FLOOR := 3           # placeholder until per-map task setup exists
const SAVE_PATH := "user://save.cfg"

var state: State = State.LOBBY
var floor_number := 1
var current_map := ""
var tasks_total := 0
var tasks_done := 0
var sonium := 0

var _timer: SceneTreeTimer
var _run_id := 0  # bumps on start/reset so stale timers are ignored


func _ready() -> void:
	_load()


# --- public API ----------------------------------------------------------------

func start_run() -> void:
	if state != State.LOBBY:
		return
	_run_id += 1
	floor_number = 1
	_set_state(State.COUNTDOWN)
	_after(COUNTDOWN_SECONDS, _enter_selection)


func finish_selection() -> void:
	## Call when all players are ready (or the selection timer ends).
	if state != State.SELECTION:
		return
	_set_state(State.PRE_FLOOR_ELEVATOR)
	_after(PRE_FLOOR_SECONDS, _begin_floor)


func report_task_done() -> void:
	if state != State.FLOOR:
		return
	tasks_done += 1
	if tasks_done >= tasks_total:
		_set_state(State.PANIC)
		_set_state(State.RETURN_TO_ELEVATOR)
		_after(RETURN_SECONDS, _end_floor)


func add_sonium(amount: int) -> void:
	sonium += amount
	sonium_changed.emit(sonium)
	_save()


func time_left() -> float:
	if _timer == null:
		return 0.0
	return maxf(_timer.time_left, 0.0)


func reset() -> void:
	## Abort the current run and go back to the lobby state.
	_run_id += 1
	_timer = null
	current_map = ""
	tasks_done = 0
	tasks_total = 0
	_set_state(State.LOBBY)


# --- internals -----------------------------------------------------------------

func _enter_selection() -> void:
	_set_state(State.SELECTION)
	_after(SELECTION_SECONDS, finish_selection)


func _begin_floor() -> void:
	current_map = MapPicker.pick(floor_number)
	tasks_done = 0
	tasks_total = TASKS_PER_FLOOR
	_set_state(State.FLOOR)
	floor_started.emit(current_map, floor_number)


func _end_floor() -> void:
	floor_ended.emit()
	if state != State.RETURN_TO_ELEVATOR:
		return  # a listener ended the run (player died)
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
	cfg.save(SAVE_PATH)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		sonium = int(cfg.get_value("player", "sonium", 0))
