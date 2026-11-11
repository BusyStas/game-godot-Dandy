class_name FloorBuilder
extends RefCounted
## Builds placeholder geometry: the elevator cabin and a themed floor for each map.
## Floors are procedural (walls, props by style, machines, containers, Corruptions) until
## hand-made scenes replace them.

const MachineScript := preload("res://scripts/machine.gd")
const ContainerScript := preload("res://scripts/container.gd")
const CorruptionScript := preload("res://scripts/corruption.gd")
const MirrorScript := preload("res://scripts/mirror.gd")


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


static func label(parent: Node, text: String, pos: Vector3, size := 48, color := Color.WHITE) -> void:
	var l := Label3D.new()
	l.text = text
	l.modulate = color
	l.position = pos
	l.font_size = size
	l.pixel_size = 0.01
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(l)


static func _emissive(parent: Node, pos: Vector3, size: Vector3, color: Color, energy := 1.5) -> void:
	var n := box(parent, pos, size, color, false)
	var mat := (n.get_child(0) as MeshInstance3D).material_override as StandardMaterial3D
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy


## Elevator doors seen from the outside (face +Z): frame, two steel sliding panels with a seam,
## a floor indicator above and a call button beside. pos = bottom-centre of the doors.
static func build_elevator_doors(parent: Node, pos: Vector3, width := 3.2, height := 3.0, indicator := true) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	parent.add_child(root)
	var frame := Color(0.12, 0.12, 0.14)
	var steel := Color(0.72, 0.74, 0.78)
	var steel_dark := Color(0.6, 0.62, 0.66)
	var fw := 0.2
	box(root, Vector3(0, height + fw / 2.0, 0), Vector3(width + fw * 2.0, fw, 0.16), frame, false)
	for sx in [-1.0, 1.0]:
		box(root, Vector3(sx * (width + fw) / 2.0, height / 2.0, 0), Vector3(fw, height, 0.16), frame, false)
	var half := width / 2.0
	for sx in [-1.0, 1.0]:
		box(root, Vector3(sx * half / 2.0, height / 2.0, 0.02), Vector3(half - 0.02, height, 0.08), steel, false)
		# brushed-steel inset
		box(root, Vector3(sx * half / 2.0, height / 2.0, 0.07), Vector3(half - 0.3, height - 0.4, 0.02), steel_dark, false)
	box(root, Vector3(0, height / 2.0, 0.07), Vector3(0.05, height, 0.04), Color(0.1, 0.1, 0.1), false)  # seam
	box(root, Vector3(0, 0.03, 0.05), Vector3(width, 0.06, 0.1), Color(0.3, 0.3, 0.32), false)  # threshold
	if indicator:
		box(root, Vector3(0, height + fw + 0.3, 0), Vector3(1.0, 0.4, 0.14), Color(0.03, 0.03, 0.03), false)
		label(root, "UP", Vector3(0, height + fw + 0.3, 0.1), 40, Color(0.2, 1.0, 0.3))
		# call button panel
		var px := width / 2.0 + fw + 0.45
		box(root, Vector3(px, 1.2, 0), Vector3(0.22, 0.5, 0.06), Color(0.2, 0.2, 0.22), false)
		_emissive(root, Vector3(px, 1.3, 0.05), Vector3(0.1, 0.1, 0.04), Color(1.0, 0.75, 0.2), 2.0)
		box(root, Vector3(px, 1.1, 0.05), Vector3(0.1, 0.1, 0.04), Color(0.7, 0.7, 0.7), false)
	return root


## The elevator interior: 4x4 cabin, carpet, wood panels, handrails, lamp, control panel,
## doors on the +Z side and a large mirror on the back (-Z) wall. Origin = centre of the floor.
## The mirror node is named "Mirror".
static func build_cabin(origin: Vector3) -> Node3D:
	var root := Node3D.new()
	root.position = origin
	var steel := Color(0.62, 0.64, 0.68)
	var wood := Color(0.45, 0.28, 0.15)
	var half := 2.0
	var h := 3.0
	var t := 0.2
	# shell
	box(root, Vector3(0, -0.5, 0), Vector3(4 + 2 * t, 1, 4 + 2 * t), Color(0.3, 0.3, 0.32))
	box(root, Vector3(0, h + t / 2.0, 0), Vector3(4 + 2 * t, t, 4 + 2 * t), Color(0.85, 0.85, 0.82))
	box(root, Vector3(0, h / 2.0, -half - t / 2.0), Vector3(4 + 2 * t, h, t), steel)
	box(root, Vector3(0, h / 2.0, half + t / 2.0), Vector3(4 + 2 * t, h, t), steel)
	box(root, Vector3(-half - t / 2.0, h / 2.0, 0), Vector3(t, h, 4), steel)
	box(root, Vector3(half + t / 2.0, h / 2.0, 0), Vector3(t, h, 4), steel)
	# carpet, thin so it does not block walking
	box(root, Vector3(0, 0.01, 0), Vector3(3.8, 0.02, 3.8), Color(0.5, 0.08, 0.1), false)
	box(root, Vector3(0, 0.02, 0), Vector3(3.2, 0.02, 3.2), Color(0.38, 0.05, 0.08), false)
	# wood wainscoting on the side walls and the door wall
	for sx in [-1.0, 1.0]:
		box(root, Vector3(sx * (half - 0.03), 0.65, 0), Vector3(0.06, 1.3, 3.9), wood, false)
		box(root, Vector3(sx * (half - 0.04), 1.32, 0), Vector3(0.08, 0.05, 3.9), Color(0.75, 0.6, 0.25), false)
		# handrail
		box(root, Vector3(sx * (half - 0.14), 1.0, 0), Vector3(0.05, 0.05, 3.0), Color(0.85, 0.85, 0.88), false)
		for sz in [-1.4, 1.4]:
			box(root, Vector3(sx * (half - 0.08), 1.0, sz), Vector3(0.12, 0.05, 0.05), Color(0.85, 0.85, 0.88), false)
	box(root, Vector3(0, 0.65, half - 0.03), Vector3(3.9, 1.3, 0.06), wood, false)
	box(root, Vector3(0, 0.65, -half + 0.03), Vector3(3.9, 1.3, 0.06), wood, false)
	# ceiling lamp panel + real light
	_emissive(root, Vector3(0, h - 0.03, 0), Vector3(1.6, 0.05, 1.6), Color(1.0, 0.96, 0.85), 2.5)
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0, h - 0.4, 0)
	lamp.omni_range = 7.0
	lamp.light_energy = 1.3
	lamp.light_color = Color(1.0, 0.95, 0.85)
	root.add_child(lamp)
	# control panel on the right wall, near the doors
	var panel := Node3D.new()
	panel.position = Vector3(half - 0.08, 1.35, 1.0)
	root.add_child(panel)
	box(panel, Vector3.ZERO, Vector3(0.05, 0.9, 0.36), Color(0.15, 0.15, 0.17), false)
	for r in 4:
		for c in 2:
			var lit := (r * 2 + c) == 5
			_emissive(panel, Vector3(-0.04, 0.3 - r * 0.15, -0.08 + c * 0.16), Vector3(0.04, 0.09, 0.09),
				Color(1.0, 0.7, 0.2) if lit else Color(0.75, 0.75, 0.78), 1.5 if lit else 0.2)
	# doors on the +Z wall, facing into the cabin
	var door_holder := Node3D.new()
	door_holder.position = Vector3(0, 0, half - 0.06)
	door_holder.rotation.y = PI
	root.add_child(door_holder)
	build_elevator_doors(door_holder, Vector3.ZERO, 2.4, 2.6, false)
	# the large mirror on the back wall, with a thin steel frame
	var mp := Vector3(0, 1.45, -half + 0.065)
	var ms: float = MirrorScript.SIZE
	var fr := Color(0.8, 0.8, 0.84)
	box(root, mp + Vector3(0, ms / 2.0 + 0.04, -0.01), Vector3(ms + 0.16, 0.08, 0.06), fr, false)
	box(root, mp + Vector3(0, -ms / 2.0 - 0.04, -0.01), Vector3(ms + 0.16, 0.08, 0.06), fr, false)
	for sx in [-1.0, 1.0]:
		box(root, mp + Vector3(sx * (ms / 2.0 + 0.04), 0, -0.01), Vector3(0.08, ms, 0.06), fr, false)
	var mirror := Node3D.new()
	mirror.name = "Mirror"
	mirror.set_script(MirrorScript)
	mirror.position = mp
	root.add_child(mirror)
	return root


## Returns {"root": Node3D, "elevator": Area3D, "spawn": Vector3}.
## cfg: {"floor": int, "machines": int, "containers": int, "corruptions": int}
static func build_floor(map_name: String, origin: Vector3, cfg: Dictionary) -> Dictionary:
	var th: Dictionary = GameData.theme(map_name)
	var w: float = th["w"]
	var d: float = th["d"]
	var root := Node3D.new()
	root.position = origin
	var wall_col: Color = th["wall"]

	box(root, Vector3(0, -0.5, 0), Vector3(w, 1, d), th["floor"])
	box(root, Vector3(0, 2.5, -d / 2.0), Vector3(w, 5, 1), wall_col)
	box(root, Vector3(0, 2.5, d / 2.0), Vector3(w, 5, 1), wall_col)
	box(root, Vector3(-w / 2.0, 2.5, 0), Vector3(1, 5, d), wall_col)
	box(root, Vector3(w / 2.0, 2.5, 0), Vector3(1, 5, d), wall_col)
	label(root, map_name, Vector3(0, 4.2, 0), 96)

	# The elevator you must return to
	build_elevator_doors(root, Vector3(0, 0, -d / 2.0 + 0.55), 3.2, 3.0, true)
	label(root, "ELEVATOR", Vector3(0, 4.6, -d / 2.0 + 1.0), 48)
	var elevator := Area3D.new()
	elevator.position = Vector3(0, 1.5, -d / 2.0 + 3.0)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(5, 3, 5)
	cs.shape = bs
	elevator.add_child(cs)
	root.add_child(elevator)
	var spawn_local := Vector3(0, 0.5, -d / 2.0 + 3.5)

	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var rects: Array = []
	_add_props(root, th["style"], th["prop"], w, d, rng, rects)

	for i in int(cfg["machines"]):
		var m := Node3D.new()
		m.set_script(MachineScript)
		m.set("kind", _pick_machine_kind(rng, int(cfg["floor"])))
		m.position = _free_point(rng, w, d, rects, spawn_local, 6.0)
		root.add_child(m)
		_reserve(rects, m.position, 4.0)

	for i in int(cfg["containers"]):
		var c := Node3D.new()
		c.set_script(ContainerScript)
		c.position = _free_point(rng, w, d, rects, spawn_local, 8.0)
		root.add_child(c)
		_reserve(rects, c.position, 3.0)

	var wander_bounds := Rect2(origin.x - w / 2.0 + 2.0, origin.z - d / 2.0 + 8.0, w - 4.0, d - 10.0)
	for i in int(cfg["corruptions"]):
		var kind := _pick_corruption_kind(rng, int(cfg["floor"]))
		var cr := CharacterBody3D.new()
		cr.set_script(CorruptionScript)
		cr.set("kind", kind)
		cr.set("bounds", wander_bounds)
		if kind == "surrena":
			cr.position = _wall_point(rng, w, d)
		else:
			cr.position = _free_point(rng, w, d, rects, spawn_local, 16.0)
		root.add_child(cr)

	return {"root": root, "elevator": elevator, "spawn": origin + spawn_local}


# --- helpers --------------------------------------------------------------------

static func _pick_machine_kind(rng: RandomNumberGenerator, f: int) -> String:
	var pool := ["regular", "regular", "regular"]
	if f >= 2:
		pool.append("clicker")
	if f >= 4:
		pool.append("hard")
		pool.append("search")
	if f >= 6:
		pool.append("treadmill")
	return pool[rng.randi() % pool.size()]


static func _pick_corruption_kind(rng: RandomNumberGenerator, f: int) -> String:
	var pool := ["serrani", "serrani", "serrani", "surrena", "surrena"]
	if f >= 4:
		pool.append("rencha")
		pool.append("rencha")
	if f >= 8:
		pool.append("soria")
		pool.append("soria")
	return pool[rng.randi() % pool.size()]


static func _reserve(rects: Array, pos: Vector3, size: float) -> void:
	rects.append(Rect2(pos.x - size / 2.0, pos.z - size / 2.0, size, size))


static func _prop(root: Node, pos: Vector3, size: Vector3, color: Color, rects: Array, solid := true) -> void:
	box(root, pos, size, color, solid)
	rects.append(Rect2(pos.x - size.x / 2.0 - 1.5, pos.z - size.z / 2.0 - 1.5, size.x + 3.0, size.z + 3.0))


static func _free_point(rng: RandomNumberGenerator, w: float, d: float, rects: Array, spawn_local: Vector3, min_spawn_dist: float) -> Vector3:
	var p := Vector3.ZERO
	for attempt in 60:
		p = Vector3(rng.randf_range(-w / 2.0 + 2.0, w / 2.0 - 2.0), 0.0, rng.randf_range(-d / 2.0 + 9.0, d / 2.0 - 2.0))
		if Vector2(p.x - spawn_local.x, p.z - spawn_local.z).length() < min_spawn_dist:
			continue
		var blocked := false
		for r in rects:
			if (r as Rect2).has_point(Vector2(p.x, p.z)):
				blocked = true
				break
		if not blocked:
			return p
	return p


static func _wall_point(rng: RandomNumberGenerator, w: float, d: float) -> Vector3:
	match rng.randi() % 3:
		0:
			return Vector3(-w / 2.0 + 1.5, 0.0, rng.randf_range(-d / 2.0 + 10.0, d / 2.0 - 2.0))
		1:
			return Vector3(w / 2.0 - 1.5, 0.0, rng.randf_range(-d / 2.0 + 10.0, d / 2.0 - 2.0))
	return Vector3(rng.randf_range(-w / 2.0 + 3.0, w / 2.0 - 3.0), 0.0, d / 2.0 - 1.5)


static func _add_props(root: Node, style: String, color: Color, w: float, d: float, rng: RandomNumberGenerator, rects: Array) -> void:
	var z0 := -d / 2.0 + 9.0  # keep the elevator area clear
	var z1 := d / 2.0 - 2.0
	match style:
		"rows":
			var seg := ((z1 - z0) - 4.0) / 2.0
			var x := -w / 2.0 + 7.0
			while x < w / 2.0 - 4.0:
				_prop(root, Vector3(x, 1.1, z0 + seg / 2.0), Vector3(1.5, 2.2, seg), color, rects)
				_prop(root, Vector3(x, 1.1, z1 - seg / 2.0), Vector3(1.5, 2.2, seg), color, rects)
				x += 7.0
		"pillars":
			var x := -w / 2.0 + 6.0
			while x < w / 2.0 - 4.0:
				var z := z0 + 2.0
				while z < z1 - 1.0:
					_prop(root, Vector3(x, 2.0, z), Vector3(1.2, 4.0, 1.2), color, rects)
					z += 8.0
				x += 9.0
		"tables":
			var x := -w / 2.0 + 6.0
			while x < w / 2.0 - 4.0:
				var z := z0 + 2.0
				while z < z1 - 1.0:
					var jitter := Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.0, 1.0))
					_prop(root, Vector3(x, 0.45, z) + jitter, Vector3(2.6, 0.9, 1.6), color, rects)
					z += 7.0
				x += 9.0
		"pool":
			var zc := (z0 + z1) / 2.0
			box(root, Vector3(0, 0.05, zc), Vector3(w * 0.35, 0.1, 6.0), color, false)
			rects.append(Rect2(-w * 0.175 - 1.0, zc - 4.0, w * 0.35 + 2.0, 8.0))
			for sx in [-1.0, 1.0]:
				for sz in [z0 + 3.0, z1 - 3.0]:
					_prop(root, Vector3(sx * (w / 2.0 - 5.0), 2.0, sz), Vector3(1.4, 4.0, 1.4), color, rects)
		_:  # scatter
			for i in 12:
				var size := Vector3(rng.randf_range(1.0, 3.0), rng.randf_range(1.0, 2.5), rng.randf_range(1.0, 3.0))
				var pos := Vector3(rng.randf_range(-w / 2.0 + 3.0, w / 2.0 - 3.0), size.y / 2.0, rng.randf_range(z0, z1 - 1.0))
				_prop(root, pos, size, color, rects)
