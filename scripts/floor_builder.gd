class_name FloorBuilder
extends RefCounted
## Builds simple placeholder geometry: the elevator cabin and a generic floor.
## Real per-map scenes will replace build_floor() later.

const MachineScript := preload("res://scripts/machine.gd")


static func box(parent: Node, pos: Vector3, size: Vector3, color: Color, solid := true) -> Node3D:
	var root: Node3D
	if solid:
		root = StaticBody3D.new()
	else:
		root = Node3D.new()
	root.position = pos
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mesh.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	root.add_child(mesh)
	if solid:
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		cs.shape = bs
		root.add_child(cs)
	parent.add_child(root)
	return root


static func label(parent: Node, text: String, pos: Vector3, size := 48) -> void:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = size
	l.pixel_size = 0.01
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(l)


static func build_cabin(origin: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = origin
	var grey := Color(0.45, 0.45, 0.5)
	box(root, Vector3(0, -0.5, 0), Vector3(6, 1, 6), grey)
	box(root, Vector3(0, 2, -3), Vector3(6, 4, 0.5), grey)
	box(root, Vector3(0, 2, 3), Vector3(6, 4, 0.5), grey)
	box(root, Vector3(-3, 2, 0), Vector3(0.5, 4, 6), grey)
	box(root, Vector3(3, 2, 0), Vector3(0.5, 4, 6), grey)
	box(root, Vector3(0, 4.25, 0), Vector3(6, 0.5, 6), grey)
	label(root, "Elevator", Vector3(0, 3.2, 0))
	return root


## Returns {"root": Node3D, "elevator": Area3D, "spawn": Vector3}
static func build_floor(map_name: String, machine_count: int, origin: Vector3) -> Dictionary:
	var root := Node3D.new()
	root.position = origin
	var tint := Color.from_hsv(float(map_name.hash() % 360) / 360.0, 0.35, 0.55)
	var wall := Color(0.55, 0.55, 0.6)
	box(root, Vector3(0, -0.5, 0), Vector3(40, 1, 30), tint)
	box(root, Vector3(0, 2.5, -15), Vector3(40, 5, 1), wall)
	box(root, Vector3(0, 2.5, 15), Vector3(40, 5, 1), wall)
	box(root, Vector3(-20, 2.5, 0), Vector3(1, 5, 30), wall)
	box(root, Vector3(20, 2.5, 0), Vector3(1, 5, 30), wall)
	label(root, map_name, Vector3(0, 4.0, 0), 96)

	# Elevator you must return to
	box(root, Vector3(0, 1.5, -14.2), Vector3(4, 3, 0.4), Color(0.7, 0.7, 0.2), false)
	label(root, "ELEVATOR", Vector3(0, 3.6, -13.6))
	var elevator := Area3D.new()
	elevator.position = Vector3(0, 1.5, -12.0)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(5, 3, 4)
	cs.shape = bs
	elevator.add_child(cs)
	root.add_child(elevator)

	# Machines at random spots
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in machine_count:
		var m := Node3D.new()
		m.set_script(MachineScript)
		m.position = Vector3(rng.randf_range(-15.0, 15.0), 0.0, rng.randf_range(-6.0, 11.0))
		root.add_child(m)

	return {"root": root, "elevator": elevator, "spawn": origin + Vector3(0, 0.5, -11.5)}
