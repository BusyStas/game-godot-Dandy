extends CanvasLayer
## Flashing red alarm shown when a monster appears: red screen-edge glow, big banner and a siren beep.

const SHOW_SECONDS := 3.5

var _glow: ColorRect
var _banner: Label
var _until_ms := 0
var _beep: AudioStreamPlayer


func _ready() -> void:
	layer = 4
	_glow = ColorRect.new()
	_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glow.color = Color(0.9, 0.0, 0.0, 0.0)
	add_child(_glow)

	_banner = Label.new()
	_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner.offset_left = -520
	_banner.offset_right = 520
	_banner.offset_top = 60
	_banner.offset_bottom = 220
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override("font_size", 44)
	_banner.add_theme_color_override("font_color", Color(1.0, 0.15, 0.1))
	_banner.add_theme_color_override("font_outline_color", Color.BLACK)
	_banner.add_theme_constant_override("outline_size", 10)
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_banner)

	_beep = AudioStreamPlayer.new()
	_beep.stream = _make_siren()
	_beep.volume_db = -6.0
	add_child(_beep)
	visible = false
	RoundManager.monster_warning.connect(show_warning)
	RoundManager.state_changed.connect(func(s):
		if s == RoundManager.State.LOBBY or s == RoundManager.State.COUNTDOWN:
			_until_ms = 0
			visible = false)
	RoundManager.player_died.connect(func(_r):
		_until_ms = 0
		visible = false)


func show_warning(_kind: String, text: String) -> void:
	_banner.text = "!! WARNING !!\n%s" % text
	_until_ms = Time.get_ticks_msec() + int(SHOW_SECONDS * 1000.0)
	visible = true
	_beep.play()


func is_showing() -> bool:
	return visible


func _process(_delta: float) -> void:
	if not visible:
		return
	if Time.get_ticks_msec() > _until_ms:
		visible = false
		return
	var t := Time.get_ticks_msec() / 1000.0
	var pulse := 0.5 + 0.5 * sin(t * 12.0)
	_glow.color.a = 0.10 + 0.22 * pulse
	_banner.modulate.a = 0.55 + 0.45 * pulse


## Two-tone siren, ~0.8 s, generated so no audio asset is needed.
static func _make_siren() -> AudioStreamWAV:
	var rate := 22050
	var samples := int(rate * 0.8)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var t := float(i) / rate
		var freq := 880.0 if int(t / 0.2) % 2 == 0 else 640.0
		var v := 1.0 if fmod(t * freq, 1.0) < 0.5 else -1.0
		var env := clampf(minf(t, 0.8 - t) * 40.0, 0.0, 1.0)
		data.encode_s16(i * 2, int(v * env * 9000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	return w
