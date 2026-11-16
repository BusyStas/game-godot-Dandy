extends Node
## Crash diagnostics. Everything goes to logs/<pc name>/_log_errors.txt in the project folder (committed to git on
## purpose, one folder per computer so two people never conflict and the cause of a crash can be read from the repo).
## In an exported build, where the project folder is read-only, it falls back to user://logs/<pc name>/.
##  - script/engine errors and warnings are appended the moment they happen (via a Logger)
##  - breadcrumbs: state changes, floor starts (map, kinds) and a heartbeat every 5 s with the player position,
##    FPS, node/object counts and memory, so a crash on a high floor shows what the game was doing just before
## Every line is flushed immediately, so it survives a hard crash. The file is trimmed when it passes ~300 KB.

const FILE_NAME := "_log_errors.txt"
const MAX_BYTES := 300000
const KEEP_BYTES := 150000
const HEARTBEAT := 5.0

class _Catcher extends Logger:
	var sink: Callable
	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, script_backtraces: Array) -> void:
		var kind: String = ["ERROR", "WARNING", "SCRIPT ERROR", "SHADER ERROR"][clampi(error_type, 0, 3)]
		var text := "%s: %s %s\n    at %s:%d (%s)" % [kind, code, rationale, file, line, function]
		for bt in script_backtraces:
			text += "\n    " + str(bt).replace("\n", "\n    ")
		sink.call(text)
	func _log_message(_message: String, _error: bool) -> void:
		pass

var _path := ""
var _catcher: _Catcher
var _t := 0.0
var _mutex := Mutex.new()


func _ready() -> void:
	var sub := "logs/" + _pc_name()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + sub))
	_path = ProjectSettings.globalize_path("res://%s/%s" % [sub, FILE_NAME])
	if not _writable(_path):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://" + sub))
		_path = ProjectSettings.globalize_path("user://%s/%s" % [sub, FILE_NAME])
	_trim()
	_write("")
	_write("=== SESSION START %s | Godot %s | %s | %s ===" % [Time.get_datetime_string_from_system(), Engine.get_version_info()["string"], OS.get_name(), RenderingServer.get_video_adapter_name()])
	_catcher = _Catcher.new()
	_catcher.sink = _write
	OS.add_logger(_catcher)
	var rm := get_node_or_null("/root/RoundManager")
	if rm != null:
		rm.state_changed.connect(func(s): _write("state -> %s" % rm.State.keys()[s]))
		rm.floor_started.connect(func(map_name, f): _write("FLOOR START %d map=%s tasks=%s/%d corruptions=%d" % [f, map_name, rm.task_kind, rm.tasks_total, rm.corruption_count]))
		rm.player_died.connect(func(r): _write("player died: %s" % r))
	get_tree().node_added.connect(_on_node_added)


func _pc_name() -> String:
	var n := ""
	for key in ["COMPUTERNAME", "HOSTNAME", "HOST"]:
		n = OS.get_environment(key)
		if n != "":
			break
	if n == "":
		n = OS.get_model_name() if OS.get_model_name() != "GenericDevice" else "unknown-pc"
	var clean := ""
	for c in n.to_lower():
		clean += c if (c >= "a" and c <= "z") or (c >= "0" and c <= "9") or c == "-" or c == "_" else "-"
	return clean


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		_write("=== SESSION END (clean exit) ===")


func _on_node_added(n: Node) -> void:
	if n.is_in_group("corruption") or n.get("kind") != null and n is CharacterBody3D:
		call_deferred("_log_corruption", n)


func _log_corruption(n: Node) -> void:
	if is_instance_valid(n) and n.is_inside_tree():
		_write("  corruption spawned: %s at %s" % [str(n.get("kind")), str(n.global_position.snapped(Vector3(0.1, 0.1, 0.1)))])


func _process(delta: float) -> void:
	_t += delta
	if _t < HEARTBEAT:
		return
	_t = 0.0
	var rm := get_node_or_null("/root/RoundManager")
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var line := "hb fps=%d nodes=%d objects=%d mem=%.0fMB" % [Engine.get_frames_per_second(), int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), int(Performance.get_monitor(Performance.OBJECT_COUNT)), OS.get_static_memory_usage() / 1048576.0]
	line += " orphans=%d" % int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	if rm != null:
		line += " state=%s floor=%d hp=%d" % [rm.State.keys()[rm.state], rm.floor_number, rm.health]
		line += " corruptions=%d hazards=%d" % [get_tree().get_nodes_in_group("corruption").size(), get_tree().get_nodes_in_group("hazards").size()]
	if player != null:
		line += " pos=%s" % str(player.global_position.snapped(Vector3(0.1, 0.1, 0.1)))
	_write(line)


func _writable(path: String) -> bool:
	var f := FileAccess.open(path, FileAccess.READ_WRITE)
	if f == null:
		f = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.close()
	return true


func _trim() -> void:
	if not FileAccess.file_exists(_path):
		return
	var f := FileAccess.open(_path, FileAccess.READ)
	if f == null or f.get_length() <= MAX_BYTES:
		return
	f.seek(f.get_length() - KEEP_BYTES)
	var tail := f.get_as_text()
	f.close()
	var nl := tail.find("\n")
	var w := FileAccess.open(_path, FileAccess.WRITE)
	if w != null:
		w.store_string("(older entries trimmed)\n" + (tail.substr(nl + 1) if nl >= 0 else tail))
		w.close()


func _write(text: String) -> void:
	_mutex.lock()
	var f := FileAccess.open(_path, FileAccess.READ_WRITE)
	if f == null:
		f = FileAccess.open(_path, FileAccess.WRITE)
	if f != null:
		f.seek_end()
		f.store_line(("[%s] " % Time.get_time_string_from_system() if text != "" else "") + text)
		f.flush()
		f.close()
	_mutex.unlock()
