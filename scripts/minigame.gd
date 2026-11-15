extends CanvasLayer
## Escape minigames from the deck ("Corruption Basics 2"):
##   shake  - Surrena's grab: spam A and D alternately to shake free, or die.
##   thorns - Ivina's plants: hit every precise point where thorns impale you (click them), or get hurt and poisoned.
## Opened by RoundManager.minigame_requested; reports back with source.minigame_result(success).

signal opened
signal closed

const SHAKE_PRESSES := 18
const SHAKE_SECONDS := 4.0
const THORN_POINTS := 3
const THORN_SECONDS := 5.0

var _kind := ""
var _source: Node
var _until := 0.0
var _total := 1.0
var _presses := 0
var _last_key := 0
var _hits := 0

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


func _on_request(kind: String, source: Node, _data: Dictionary) -> void:
	_kind = kind
	_source = source
	_presses = 0
	_hits = 0
	_last_key = 0
	for c in _arena.get_children():
		c.queue_free()
	match kind:
		"shake":
			_title.text = "SURRENA HAS YOU!"
			_hint.text = "Mash A and D, one after the other, to shake free!"
			_total = SHAKE_SECONDS
			_bar.max_value = SHAKE_PRESSES
			_bar.value = 0
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


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _kind != "shake":
		return
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_A or event.keycode == KEY_D):
		get_viewport().set_input_as_handled()
		if event.keycode != _last_key:        # must alternate
			_last_key = event.keycode
			_presses += 1
			_bar.value = _presses
			if _presses >= SHAKE_PRESSES:
				_close(true)


func _process(_delta: float) -> void:
	if not visible:
		return
	var left := _until - RoundManager.now()
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
