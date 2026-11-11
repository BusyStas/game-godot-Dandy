extends Node3D
## A hidden storage container. Hold E for a moment to open it: +Sonium for the opener.
## Counts toward the floor task on "containers" floors.

const RANGE := 2.5
const OPEN_SECONDS := 1.0

var opened := false

var _progress := 0.0
var _mat: StandardMaterial3D
var _label: Label3D


func _ready() -> void:
	var body := StaticBody3D.new()
	body.position.y = 0.4
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.0, 0.8, 1.0)
	mesh.mesh = bm
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.45, 0.3, 0.15)
	mesh.material_override = _mat
	body.add_child(mesh)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = bm.size
	cs.shape = bs
	body.add_child(cs)
	add_child(body)

	_label = Label3D.new()
	_label.position.y = 1.4
	_label.font_size = 36
	_label.pixel_size = 0.01
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.visible = false  # containers are hidden: only show the prompt up close
	add_child(_label)


func _process(delta: float) -> void:
	if opened:
		return
	var p := get_tree().get_first_node_in_group("player") as Node3D
	var near := p != null and p.global_position.distance_to(global_position) < RANGE
	_label.visible = near
	if near:
		_label.text = "Container: hold E" if _progress <= 0.0 else "Opening %d%%" % int(_progress / OPEN_SECONDS * 100.0)
		if Input.is_physical_key_pressed(KEY_E) and not bool(p.get("frozen")):
			_progress += delta
			p.call("make_noise", 5.0)
			if _progress >= OPEN_SECONDS:
				_open()
		else:
			_progress = maxf(0.0, _progress - delta)


func _open() -> void:
	opened = true
	_mat.albedo_color = Color(0.3, 0.6, 0.3)
	_label.visible = true
	_label.text = "Opened"
	RoundManager.container_opened()
