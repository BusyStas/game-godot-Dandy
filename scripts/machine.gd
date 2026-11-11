extends Node3D
## A fixable machine. Stand within range and hold E for FIX_SECONDS to fix it.
## Fixing grants Sonium and counts as one completed task.

const FIX_SECONDS := 3.0
const RANGE := 3.0
const REWARD := 10

var progress := 0.0
var done := false

var _mat: StandardMaterial3D
var _label: Label3D


func _ready() -> void:
	var body := StaticBody3D.new()
	body.position.y = 0.7
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.2, 1.4, 1.2)
	mesh.mesh = bm
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.7, 0.2, 0.2)
	mesh.material_override = _mat
	body.add_child(mesh)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = bm.size
	cs.shape = bs
	body.add_child(cs)
	add_child(body)

	_label = Label3D.new()
	_label.position.y = 2.0
	_label.font_size = 40
	_label.pixel_size = 0.01
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_label)
	_update_label()


func _process(delta: float) -> void:
	if done:
		return
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	var near := player.global_position.distance_to(global_position) < RANGE
	if near and Input.is_physical_key_pressed(KEY_E):
		progress += delta
		if progress >= FIX_SECONDS:
			_finish()
	_update_label()


func _finish() -> void:
	done = true
	_mat.albedo_color = Color(0.2, 0.7, 0.3)
	RoundManager.add_sonium(REWARD)
	RoundManager.report_task_done()
	_update_label()


func _update_label() -> void:
	if done:
		_label.text = "Fixed"
	elif progress > 0.0:
		_label.text = "Fixing %d%%" % int(progress / FIX_SECONDS * 100.0)
	else:
		_label.text = "Machine (hold E)"
