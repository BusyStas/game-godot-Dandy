extends Node3D
## A real mirror. A hidden camera sits at the viewer's position reflected through the mirror plane,
## renders the cabin through an off-axis frustum that exactly matches the mirror's rectangle,
## and the result is shown on the mirror quad flipped left-right. A figure standing where the
## player stands (visible only to the mirror camera) gives you a reflection to look at.
## The node's local +Z must point out of the mirror, into the room.

const SIZE := 2.2   # square mirror, metres
const PIXELS := 512
const FIGURE_LAYER := 2

var active := false:
	set(value):
		active = value
		if _vp:
			_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if value else SubViewport.UPDATE_DISABLED
		if _figure:
			_figure.visible = value
var skin_color := Color(0.8, 0.8, 0.8):
	set(value):
		skin_color = value
		if is_inside_tree():
			_rebuild_figure()

var _vp: SubViewport
var _cam: Camera3D
var _figure: Node3D


func _ready() -> void:
	_vp = SubViewport.new()
	_vp.size = Vector2i(PIXELS, PIXELS)
	_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_vp)
	_cam = Camera3D.new()
	_cam.projection = Camera3D.PROJECTION_FRUSTUM
	_cam.keep_aspect = Camera3D.KEEP_WIDTH
	_cam.size = SIZE
	_cam.far = 80.0
	_vp.add_child(_cam)
	_cam.current = true

	var quad := QuadMesh.new()
	quad.size = Vector2(SIZE, SIZE)
	var m := MeshInstance3D.new()
	m.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = _vp.get_texture()
	mat.albedo_color = Color(0.93, 0.97, 1.0)          # faint cool tint, like real glass
	mat.uv1_scale = Vector3(-1, 1, 1)                  # mirror image: flip left-right
	mat.uv1_offset = Vector3(1, 0, 0)
	m.material_override = mat
	add_child(m)
	_rebuild_figure()
	_figure.visible = active


func _rebuild_figure() -> void:
	if _figure:
		_figure.queue_free()
	_figure = CharacterModel.build_player(skin_color)
	CharacterModel.set_visual_layers(_figure, FIGURE_LAYER)
	_figure.top_level = true
	_figure.visible = active
	add_child(_figure)


func _process(_delta: float) -> void:
	if not active:
		return
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null or not player.has_method("camera"):
		return
	var eye: Camera3D = player.call("camera")
	update_mirror(eye.global_position)
	_figure.global_transform = Transform3D(Basis(Vector3.UP, player.global_rotation.y), player.global_position)


## Positions the mirror camera for a viewer at `viewer_pos` (world space). Public so it can be tested.
func update_mirror(viewer_pos: Vector3) -> void:
	var n := global_transform.basis.z.normalized()
	var plane_pt := global_position
	var d := (viewer_pos - plane_pt).dot(n)
	if d < 0.05:
		return  # viewer is behind or on the mirror
	var cam_pos := viewer_pos - 2.0 * d * n
	var basis := Basis.looking_at(n, Vector3.UP)   # camera looks straight through the mirror, into the room
	_cam.global_transform = Transform3D(basis, cam_pos)
	var to_centre := plane_pt - cam_pos
	_cam.near = d                                  # clips everything behind the mirror plane (the wall)
	_cam.frustum_offset = Vector2(to_centre.dot(basis.x), to_centre.dot(basis.y))


func mirror_camera() -> Camera3D:
	return _cam
