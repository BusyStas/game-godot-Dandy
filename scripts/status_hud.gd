extends CanvasLayer
## Bottom-left health and status readout, plus the screen effects for dimming (Dreina's puddles)
## and poison.

var _hp: Label
var _status: Label
var _dim: ColorRect
var _poison: ColorRect


func _ready() -> void:
	layer = 3
	_dim = ColorRect.new()
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.color = Color(0, 0, 0, 0)
	add_child(_dim)
	_poison = ColorRect.new()
	_poison.set_anchors_preset(Control.PRESET_FULL_RECT)
	_poison.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_poison.color = Color(0.2, 0.8, 0.1, 0)
	add_child(_poison)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	box.offset_left = 16
	box.offset_top = -90
	box.offset_bottom = -16
	box.offset_right = 360
	add_child(box)
	_hp = Label.new()
	_hp.add_theme_font_size_override("font_size", 26)
	box.add_child(_hp)
	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 18)
	_status.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	box.add_child(_status)


func _process(delta: float) -> void:
	var live := RoundManager.in_floor()
	_hp.visible = live
	_status.visible = live
	if not live:
		_dim.color.a = 0.0
		_poison.color.a = 0.0
		return
	var hp := RoundManager.health
	_hp.text = "HP  %s%s  %d/%d" % ["#".repeat(maxi(hp, 0)), "-".repeat(maxi(RoundManager.MAX_HEALTH - hp, 0)), maxi(hp, 0), RoundManager.MAX_HEALTH]
	_hp.add_theme_color_override("font_color", Color(1, 0.3, 0.3) if hp <= 2 else Color.WHITE)
	var s: Array = []
	if RoundManager.is_poisoned():
		s.append("POISONED")
	if RoundManager.now() < RoundManager.sick_until:
		s.append("SICK")
	if RoundManager.is_chunked():
		s.append("CHUNK STUCK")
	if RoundManager.slow_factor < 1.0:
		s.append("SLOWED")
	_status.text = "  ".join(s)
	_dim.color.a = move_toward(_dim.color.a, RoundManager.dim_amount(), delta * 2.5)
	_poison.color.a = move_toward(_poison.color.a, 0.18 if RoundManager.is_poisoned() else 0.0, delta * 1.5)
