extends CanvasLayer
## Escape minigames from the deck ("Corruption Basics 2"):
##   shake  - Surrena's grab: spam A and D alternately to shake free, or die.
##   drag   - Minchei's grasp: mash A/D AND hit SPACE while the needle is in the green zone.
##   thorns - Ivina's plants: hit every precise point where thorns impale you (click them), or get hurt and poisoned.
## Opened by RoundManager.minigame_requested; reports back with source.minigame_result(success).

signal opened
signal closed

const SHAKE_PRESSES := 18
const SHAKE_SECONDS := 4.0
const DRAG_PRESSES := 10
const DRAG_HITS := 2
const DRAG_SECONDS := 7.0
const THORN_POINTS := 3
const THORN_SECONDS := 5.0

var _kind := ""
var _source: Node
var _until := 0.0
var _total := 1.0
var _presses := 0
var _last_key := 0
var _hits := 0
var _need := SHAKE_PRESSES
var _track: Control
var _needle: ColorRect
var _zone: ColorRect

var _title: Label
var _hint: Label
var _bar: ProgressBar
var _time_bar: ProgressBar
var _arena: Control


func _ready() -> void:
	layer = 8
	visible = false
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	var bg := ColorRect.new()
	bg.color = Color(0.3, 0.0, 0.0, 0.45)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_CENTER_TOP)
	vb.offset_left = -300
	vb.offset_right = 300
	vb.offset_top = 90
	vb.add_theme_constant_override("separation", 8)
	root.add_child(vb)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 40)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_title)
	_hint = Label.new()
	_hint.add_theme_font_size_override("font_size", 22)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_hint)
	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(0, 26)
	vb.add_child(_bar)
	_time_bar = ProgressBar.new()
	_time_bar.custom_minimum_size = Vector2(0, 14)
	_time_bar.show_percentage = false
	vb.add_child(_time_bar)
	_track = Control.new()
	_track.custom_minimum_size = Vector2(0, 34)
	_track.visible = false
	vb.add_child(_track)
	var tbg := ColorRect.new()
	tbg.color = Color(0.1, 0.1, 0.1, 0.85)
	tbg.size = Vector2(600, 34)
	_track.add_child(tbg)
	_zone = ColorRect.new()
	_zone.color = Color(0.1, 0.8, 0.2, 0.9)
	_zone.position = Vector2(240, 0)
	_zone.size = Vector2(120, 34)
	_track.add_child(_zone)
	_needle = ColorRect.new()
	_needle.color = Color.WHITE
	_needle.size = Vector2(8, 34)
	_track.add_child(_needle)
	_arena = Control.new()
	_arena.set_anchors_preset(Control.PRESET_FULL_RECT)
	_arena.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_arena)
	RoundManager.minigame_requested.connect(_on_request)
	RoundManager.state_changed.connect(func(s):
		if s == RoundManager.State.LOBBY and visible:
			_close(null))
	RoundManager.player_died.connect(func(_r):
		if visible:
			_close(null))


func is_open() -> bool:
	return visible


func _on_request(kind: String, source: Node, data: Dictionary) -> void:
	_kind = kind
	_source = source
	_presses = 0
	_hits = 0
	_last_key = 0
	_track.visible = false
	for c in _arena.get_children():
		c.queue_free()
	match kind:
		"shake":
			_need = int(data.get("presses", SHAKE_PRESSES))
			_title.text = str(data.get("title", "SURRENA HAS YOU!"))
			_hint.text = "Mash A and D, one after the other, to shake free!"
			_total = SHAKE_SECONDS
			_bar.max_value = _need
			_bar.value = 0
		"drag":
			_title.text = "MINCHEI HAS YOU!"
			_hint.text = "Mash A and D - and press SPACE when the needle is in the green!  (timing 0/%d)" % DRAG_HITS
			_total = DRAG_SECONDS
			_bar.max_value = DRAG_PRESSES
			_bar.value = 0
			_track.visible = true
		"thorns":
			_title.text = "IVINA'S THORNS!"
			_hint.text = "Click every red point where a thorn would impale you!"
			_total = THORN_SECONDS
			_bar.max_value = THORN_POINTS
			_bar.value = 0
			_spawn_points()
	_time_bar.max_value = _total
	_until = RoundManager.now() + _total
	visible = true
	opened.emit()


func _spawn_points() -> void:
	var size := get_viewport().get_visible_rect().size
	for i in THORN_POINTS:
		var b := Button.new()
		b.text = "X"
		b.custom_minimum_size = Vector2(72, 72)
		b.size = Vector2(72, 72)
		b.add_theme_font_size_override("font_size", 28)
		b.add_theme_color_override("font_color", Color(1, 0.1, 0.1))
		b.position = Vector2(randf_range(120.0, size.x - 200.0), randf_range(260.0, size.y - 160.0))
		b.mouse_filter = Control.MOUSE_FILTER_STOP
		b.pressed.connect(_hit_point.bind(b))
		_arena.add_child(b)


func _hit_point(b: Button) -> void:
	b.queue_free()
	_hits += 1
	_bar.value = _hits
	if _hits >= THORN_POINTS:
		_close(true)


func _needle_x() -> float:
	return (sin(RoundManager.now() * 3.4) * 0.5 + 0.5) * 592.0


func _unhandled_input(event: InputEvent) -> void:
	if not visible or (_kind != "shake" and _kind != "drag"):
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_A or event.keycode == KEY_D:
		get_viewport().set_input_as_handled()
		if event.keycode != _last_key:        # must alternate
			_last_key = event.keycode
			_presses += 1
			_bar.value = _presses
	elif _kind == "drag" and event.keycode == KEY_SPACE:
		get_viewport().set_input_as_handled()
		var x := _needle_x()
		if x >= _zone.position.x - 4.0 and x <= _zone.position.x + _zone.size.x:
			_hits += 1
			_hint.text = "Mash A and D - and press SPACE when the needle is in the green!  (timing %d/%d)" % [_hits, DRAG_HITS]
	if _kind == "shake" and _presses >= _need:
		_close(true)
	elif _kind == "drag" and _presses >= DRAG_PRESSES and _hits >= DRAG_HITS:
		_close(true)


func _process(_delta: float) -> void:
	if not visible:
		return
	var left := _until - RoundManager.now()
	if _kind == "drag":
		_needle.position.x = _needle_x()
	_time_bar.value = maxf(left, 0.0)
	if left <= 0.0:
		_close(false)


func _close(success: Variant) -> void:
	visible = false
	for c in _arena.get_children():
		c.queue_free()
	RoundManager.end_minigame()
	var src := _source
	_source = null
	closed.emit()
	if success != null and src != null and is_instance_valid(src):
		src.call("minigame_result", bool(success))
