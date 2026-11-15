extends Node3D
## A healing item. Press E next to it. Sonia can poison them: a poisoned one gives illness
## (slows you for a while) instead of healing. You cannot tell which is which.

const RANGE := 2.2

var poisoned := false
var _used := false
var _label: Label3D


func _ready() -> void:
	add_to_group("medkits")
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.7, 0.45, 0.5)
	m.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.95, 0.95)
	m.material_override = mat
	m.position.y = 0.25
	add_child(m)
	for sz in [Vector3(0.45, 0.06, 0.12), Vector3(0.12, 0.06, 0.45)]:
		var c := MeshInstance3D.new()
		var cm := BoxMesh.new()
		cm.size = sz
		c.mesh = cm
		var cmat := StandardMaterial3D.new()
		cmat.albedo_color = Color(0.9, 0.1, 0.1)
		c.material_override = cmat
		c.position.y = 0.5
		add_child(c)
	_label = Label3D.new()
	_label.text = "Medkit: press E"
	_label.position.y = 1.2
	_label.font_size = 32
	_label.pixel_size = 0.01
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.layers = FloorBuilder.LABEL_LAYER
	add_child(_label)
	FloorBuilder.map_marker(self, Color(0.2, 1.0, 0.6), 0.6, 7.0, true)


func _unhandled_input(event: InputEvent) -> void:
	if _used or not (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E):
		return
	var p := get_tree().get_first_node_in_group("player") as Node3D
	if p == null or p.global_position.distance_to(global_position) > RANGE or not RoundManager.in_floor():
		return
	_used = true
	if poisoned:
		RoundManager.make_sick(15.0)
		RoundManager.notice.emit("The medkit was poisoned! You feel ill.")
	else:
		RoundManager.heal(2)
		RoundManager.notice.emit("Medkit: +2 HP")
	queue_free()
