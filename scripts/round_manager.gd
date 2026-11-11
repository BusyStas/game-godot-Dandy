extends Node
## Round loop state machine (autoload). Mirrors the design deck:
## lobby -> elevator countdown -> selection -> pre-floor elevator (~15s)
## -> floor (tasks) -> panic mode -> return to elevator (90s) -> results -> lobby.
## Authority (rewards, task progress, deaths) should live on the server.

signal state_changed(new_state: State)
signal floor_started(map_name: String, floor_number: int)

enum State { LOBBY, COUNTDOWN, SELECTION, PRE_FLOOR_ELEVATOR, FLOOR, PANIC, RETURN_TO_ELEVATOR, RESULTS }

const COUNTDOWN_SECONDS := 5.0       # placeholder, not specified in the deck
const SELECTION_SECONDS := 30.0      # placeholder, not specified in the deck
const PRE_FLOOR_SECONDS := 15.0
const RETURN_SECONDS := 90.0

var state: State = State.LOBBY
var floor_number := 1
var current_map := ""
var tasks_total := 0
var tasks_done := 0

var _timer: SceneTreeTimer


func start_run() -> void:
	floor_number = 1
	_set_state(State.COUNTDOWN)
	_after(COUNTDOWN_SECONDS, func(): _set_state(State.SELECTION))


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


func _begin_floor() -> void:
	current_map = MapPicker.pick(floor_number)
	tasks_done = 0
	tasks_total = 3  # placeholder; real value comes from the map's task setup
	_set_state(State.FLOOR)
	floor_started.emit(current_map, floor_number)


func _end_floor() -> void:
	# TODO: kill players not in their elevator, then show results.
	_set_state(State.RESULTS)
	floor_number += 1
	_after(5.0, func(): _set_state(State.PRE_FLOOR_ELEVATOR); _after(PRE_FLOOR_SECONDS, _begin_floor))


func _set_state(s: State) -> void:
	state = s
	state_changed.emit(s)


func _after(seconds: float, callback: Callable) -> void:
	_timer = get_tree().create_timer(seconds)
	_timer.timeout.connect(callback)
