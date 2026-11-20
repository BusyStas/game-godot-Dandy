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
signal monster_warning(kind: String, text: String)
signal health_changed(hp: int, max_hp: int)
signal minigame_requested(kind: String, source: Node, data: Dictionary)
signal research_changed

enum State { LOBBY, COUNTDOWN, SELECTION, PRE_FLOOR_ELEVATOR, FLOOR, PANIC, RETURN_TO_ELEVATOR, RESULTS }

const COUNTDOWN_SECONDS := 5.0       # PLACEHOLDER, not in the deck
const SELECTION_SECONDS := 30.0      # PLACEHOLDER, not in the deck
const PRE_FLOOR_SECONDS := 15.0
const RETURN_SECONDS := 90.0
const RESULTS_SECONDS := 5.0
const MACHINE_REWARD := 10
const CONTAINER_REWARD := 5
const CHALLENGE_BONUS := 100         # PLACEHOLDER: reward for beating a shop-character challenge floor
const MAX_HEALTH := 3                # deck: "a max of three health during the entire session of a run"
const HIT_COOLDOWN := 1.2            # seconds of invulnerability after taking damage
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
var chain: Array = []     ## FloorChain blocks of this run: floors must be reached one by one, in order
## Admins (Daniel and his father) get the Fatals unlocked: run with --admin, set SONIA_ADMIN=1, or put an admin.txt file in the project folder.
var is_admin := false
var best_tip := ""        ## hash of the last block of the run that set best_floor
var _chain_run_id := 0
var health := MAX_HEALTH
var minigame_active := false

# status effects (timestamps are seconds from Time.get_ticks_msec)
var poisoned_until := 0.0
var sick_until := 0.0
var dim_until := 0.0
var chunk_until := 0.0
var _invuln_until := 0.0
var _slows := {}          # key -> [factor, until]
var _poison_tick := 0.0

# research: kind -> {"p": [progress x4], "claimed": bool}
var research := {}
var immune_slow := false
var immune_poison := false
var speed_perk := 1.0
var research_mult := 1.0  # Shovelina research: quests finish at triple the pace
var sealant := false      # Cybot research utility: broken machines leak slower

var sonium := 0
var best_floor := 0
var starter_chosen := false
var owned := {"characters": [], "skins": ["default"], "decorations": ["none"]}
var loadout := {"character": "ghouliean", "skin": "default", "utility": "none", "decoration": "none"}

var _timer: SceneTreeTimer
var _run_id := 0
var _spotted := {}


func _ready() -> void:
	is_admin = "--admin" in OS.get_cmdline_user_args() or "--admin" in OS.get_cmdline_args() \
		or OS.get_environment("SONIA_ADMIN") == "1" or FileAccess.file_exists("res://admin.txt")
	for k in GameData.RESEARCH:
		research[k] = {"p": [0.0, 0.0, 0.0, 0.0], "claimed": false}
	_load()
	_apply_rewards()


func _process(delta: float) -> void:
	if not in_floor():
		return
	_poison_tick -= delta
	if _poison_tick <= 0.0:
		_poison_tick = 3.0
		if now() < poisoned_until and health > 1:
			health -= 1
			health_changed.emit(health, MAX_HEALTH)
			notice.emit("Poison! HP %d/%d" % [health, MAX_HEALTH])


func now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _unhandled_input(event: InputEvent) -> void:
	## Global shortcuts: X, or Ctrl+C like in DOS, quits the game from any screen.
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var ctrl_c: bool = event.keycode == KEY_C and event.ctrl_pressed
	if event.keycode == KEY_F11:
		var fs := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fs else DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	if event.keycode == KEY_X or ctrl_c:
		if ctrl_c:
			print("^C")
		_save()
		get_tree().quit()


# --- run flow -------------------------------------------------------------------

func start_run() -> void:
	if state != State.LOBBY:
		return
	_run_id += 1
	floor_number = 1   # every run starts at floor 1 and goes floor by floor
	chain = []
	_chain_run_id = (randi() << 16) ^ int(Time.get_ticks_usec())
	_clear_status()
	health = MAX_HEALTH
	health_changed.emit(health, MAX_HEALTH)
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
	_clear_status()
	minigame_active = false
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
	if slow_factor < 1.0 or immune_slow:
		return
	slow_factor = 0.8
	notice.emit("Rencha is stalking you - you feel slower.")


func spotted_count() -> int:
	return _spotted.size()


func warn_monster(kind: String) -> void:
	if state == State.FLOOR or state == State.PANIC or state == State.RETURN_TO_ELEVATOR:
		monster_warning.emit(kind, GameData.WARNINGS.get(kind, "A monster is near!"))


## Damage from a Corruption. Fatals (damage >= 999) kill instantly; others take health, with a short
## invulnerability window after each hit.
func damage(amount: int, source: String) -> void:
	if not in_floor():
		return
	if amount >= 999:
		kill_player("Caught by %s" % source)
		return
	if now() < _invuln_until:
		return
	health -= amount
	_invuln_until = now() + HIT_COOLDOWN
	health_changed.emit(health, MAX_HEALTH)
	notice.emit("%s hit you for %d! HP %d/%d" % [source, amount, maxi(health, 0), MAX_HEALTH])
	if health <= 0:
		kill_player("Killed by %s" % source)


func heal(amount: int) -> void:
	health = mini(health + amount, MAX_HEALTH)
	health_changed.emit(health, MAX_HEALTH)


func grant_invulnerability(seconds: float) -> void:
	_invuln_until = maxf(_invuln_until, now() + seconds)


func poison(seconds := 9.0) -> void:
	if immune_poison:
		return
	if now() >= poisoned_until:
		notice.emit("You are poisoned!")
	poisoned_until = now() + seconds


func make_sick(seconds := 15.0) -> void:
	sick_until = now() + seconds


func add_slow(key: String, factor: float, seconds: float) -> void:
	_slows[key] = [factor, now() + seconds]


func add_dim(seconds: float) -> void:
	dim_until = maxf(dim_until, now() + seconds)


func add_chunk(seconds: float) -> void:
	chunk_until = now() + seconds
	research_event("dreina", "chunked")


func is_chunked() -> bool:
	return now() < chunk_until


func is_poisoned() -> bool:
	return now() < poisoned_until


## 0..1 how dark the screen should be (Dreina's Sonium puddles make it harder to see).
func dim_amount() -> float:
	return 0.55 if now() < dim_until else 0.0


## Combined movement multiplier: Rencha's slowness, timed slows (puddles, plants), sickness and research perks.
func speed_factor() -> float:
	var f := slow_factor * speed_perk
	if now() < sick_until:
		f *= 0.85
	var t := now()
	for k in _slows.keys():
		if t < float(_slows[k][1]):
			f *= float(_slows[k][0])
	return f


func request_minigame(kind: String, source: Node, data := {}) -> bool:
	if minigame_active or not in_floor():
		return false
	minigame_active = true
	minigame_requested.emit(kind, source, data)
	return true


func end_minigame() -> void:
	minigame_active = false


# --- research ---------------------------------------------------------------------

## set_max: treat `amount` as a running total and keep the highest value (for "N seconds straight" tasks).
func research_event(kind: String, ev: String, amount := 1.0, set_max := false) -> void:
	if not in_floor() or not GameData.RESEARCH.has(kind):
		return
	var tasks: Array = GameData.RESEARCH[kind]["tasks"]
	var rec: Dictionary = research[kind]
	for i in tasks.size():
		if tasks[i]["ev"] != ev:
			continue
		var goal: float = tasks[i]["goal"]
		var before: float = rec["p"][i]
		if before >= goal:
			return
		var amt := amount * research_mult
		rec["p"][i] = minf(maxf(before, amt) if set_max else before + amt, goal)
		if rec["p"][i] >= goal:
			notice.emit("Research: %s - task %d done!" % [GameData.CORRUPTIONS[kind]["name"], i + 1])
			_save()
		research_changed.emit()
		return


func research_complete(kind: String) -> bool:
	var tasks: Array = GameData.RESEARCH[kind]["tasks"]
	for i in tasks.size():
		if float(research[kind]["p"][i]) < float(tasks[i]["goal"]):
			return false
	return true


func research_cost(kind: String) -> int:
	return int(GameData.RESEARCH[kind]["cost_jars"]) * GameData.JAR_SONIUM


func can_claim(kind: String) -> bool:
	return research_complete(kind) and not research[kind]["claimed"] and sonium >= research_cost(kind)


func claim_research(kind: String) -> bool:
	if not can_claim(kind):
		return false
	sonium -= research_cost(kind)
	research[kind]["claimed"] = true
	sonium_changed.emit(sonium)
	_apply_rewards()
	_save()
	research_changed.emit()
	return true


func title() -> String:
	var all := true
	for k in research:
		if not research[k]["claimed"]:
			all = false
	if all:
		return GameData.MASTER_TITLE
	for k in research:
		if research[k]["claimed"] and GameData.RESEARCH[k]["reward"] == "title":
			return str(GameData.RESEARCH[k]["reward_text"]).get_slice(" + ", 0).trim_prefix("Title: ")
	return ""


func _apply_rewards() -> void:
	immune_slow = research["rencha"]["claimed"]
	immune_poison = research["ivina"]["claimed"]
	speed_perk = 1.08 if research["bolten"]["claimed"] else 1.0
	sealant = research["cybot"]["claimed"]
	research_mult = 3.0 if research["shovelina"]["claimed"] else 1.0


func _clear_status() -> void:
	poisoned_until = 0.0
	sick_until = 0.0
	dim_until = 0.0
	chunk_until = 0.0
	_invuln_until = 0.0
	_slows.clear()


func kill_player(reason: String) -> void:
	if not in_floor():
		return
	if floor_number > best_floor:
		best_floor = floor_number
		best_tip = str(chain[-1]["hash"]) if not chain.is_empty() else ""
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
	if not FloorChain.append(chain, floor_number, current_map, _chain_run_id):
		push_error("Floor sequence check failed at floor %d (chain length %d)" % [floor_number, chain.size()])
		notice.emit("Floor sequence invalid - run cancelled.")
		reset()
		return
	var th: Dictionary = GameData.theme(current_map)
	task_kind = th["task"]
	machine_count = clampi(3 + floori(floor_number / 8.0), 3, 6)
	container_count = 5 if task_kind == "containers" else 2
	# deck: "the first couple floors have two Corruptions, then more"
	corruption_count = 2 if floor_number <= 2 else clampi(3 + floori((floor_number - 3) / 5.0), 3, 6)
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
	_clear_status()
	_set_state(State.FLOOR)
	floor_started.emit(current_map, floor_number)
	if GameData.LORE.has(current_map):
		notice.emit(GameData.LORE[current_map])


## Called when the player(s) stand inside the floor's elevator during the return phase: leave right away.
func elevator_reached() -> void:
	if state != State.RETURN_TO_ELEVATOR:
		return
	_run_id += 1   # cancels the pending return timer
	_end_floor()


func _end_floor() -> void:
	floor_ended.emit()
	if state != State.RETURN_TO_ELEVATOR:
		return
	if floor_number > best_floor:
		best_floor = floor_number
		best_tip = str(chain[-1]["hash"]) if not chain.is_empty() else ""
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
	cfg.set_value("player", "best_tip", best_tip)
	cfg.set_value("player", "best_seal", FloorChain.seal(best_floor, best_tip))
	cfg.set_value("player", "starter_chosen", starter_chosen)
	cfg.set_value("player", "owned_characters", owned["characters"])
	cfg.set_value("player", "owned_skins", owned["skins"])
	cfg.set_value("player", "owned_decorations", owned["decorations"])
	for k in loadout:
		cfg.set_value("loadout", k, loadout[k])
	for k in research:
		cfg.set_value("research", k, research[k]["p"])
		cfg.set_value("research_claimed", k, research[k]["claimed"])
	cfg.save(SAVE_PATH)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	sonium = int(cfg.get_value("player", "sonium", 0))
	best_floor = int(cfg.get_value("player", "best_floor", 0))
	best_tip = str(cfg.get_value("player", "best_tip", ""))
	if best_floor > 0 and str(cfg.get_value("player", "best_seal", "")) != FloorChain.seal(best_floor, best_tip):
		push_warning("best_floor in the save does not match its seal - reset to 0")
		best_floor = 0
		best_tip = ""
	starter_chosen = bool(cfg.get_value("player", "starter_chosen", false))
	owned["characters"] = Array(cfg.get_value("player", "owned_characters", []))
	owned["skins"] = Array(cfg.get_value("player", "owned_skins", ["default"]))
	owned["decorations"] = Array(cfg.get_value("player", "owned_decorations", ["none"]))
	for k in loadout:
		loadout[k] = str(cfg.get_value("loadout", k, loadout[k]))
	# the roster changed with the deck (stars, story characters): drop saved characters that no longer exist
	var kept: Array = []
	for id in owned["characters"]:
		if GameData.CHARACTERS.has(id) and (is_admin or not GameData.CHARACTERS[id].get("admin", false)):
			kept.append(id)
	owned["characters"] = kept
	if kept.is_empty():
		starter_chosen = false
	elif not GameData.CHARACTERS.has(loadout["character"]) or (GameData.CHARACTERS[loadout["character"]].get("admin", false) and not is_admin):
		loadout["character"] = kept[0]
	for k in research:
		var p: Array = Array(cfg.get_value("research", k, research[k]["p"]))
		if p.size() == 4:
			research[k]["p"] = p
		research[k]["claimed"] = bool(cfg.get_value("research_claimed", k, false))
