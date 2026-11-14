extends CanvasLayer
## Top-right corner minimap: a second camera looks straight down at the player (north is up)
## and renders the real geometry plus the icons on visual layer 3 (you, monsters, machines,
## containers, the elevator). Shown in the lobby and on floors, hidden inside the cabin.

const BOX := 232            ## outer size in UI pixels
const VIEW_METRES := 44.0   ## how much world the map shows
const HEIGHT := 40.0

var _vp: SubViewport
var _cam: Camera3D
var _player: Node3D


func _ready() -> void:
	layer = 2
	var frame := Panel.new()
	frame.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	frame.offset_left = -BOX - 16
	frame.offset_right = -16
	frame.offset_top = 16
	frame.offset_bottom = 16 + BOX
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.02, 0.03, 0.9)
	sb.border_color = Color(0.85, 0.85, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	frame.add_theme_stylebox_override("panel", sb)
	add_child(frame)

	var cont := SubViewportContainer.new()
	cont.stretch = true
	cont.set_anchors_preset(Control.PRESET_FULL_RECT)
	cont.offset_left = 4
	cont.offset_top = 4
	cont.offset_right = -4
	cont.offset_bottom = -4
	frame.add_child(cont)

	_vp = SubViewport.new()
	_vp.size = Vector2i(BOX - 8, BOX - 8)
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	cont.add_child(_vp)

	_cam = Camera3D.new()
	_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_cam.size = VIEW_METRES
	_cam.far = 120.0
	_cam.rotation_degrees = Vector3(-90, 0, 0)   # look down, north (-Z) at the top
	_cam.cull_mask = 1 | 4                       # world + minimap icons; no labels, no mirror figure
	_vp.add_child(_cam)
	_cam.current = true

	var tag := Label.new()
	tag.text = "N"
	tag.position = Vector2(BOX / 2.0 - 4, 2)
	tag.add_theme_font_size_override("font_size", 14)
	frame.add_child(tag)


func _process(_delta: float) -> void:
	var s: int = RoundManager.state
	var show_map: bool = s == RoundManager.State.LOBBY or s == RoundManager.State.FLOOR \
		or s == RoundManager.State.PANIC or s == RoundManager.State.RETURN_TO_ELEVATOR
	visible = show_map
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if show_map else SubViewport.UPDATE_DISABLED
	if not show_map:
		return
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Node3D
		if _player == null:
			return
	var p := _player.global_position
	_cam.global_position = Vector3(p.x, HEIGHT, p.z)


func camera() -> Camera3D:
	return _cam
