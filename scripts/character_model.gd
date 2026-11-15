class_name CharacterModel
extends RefCounted
## Builds the characters as drawn in the design deck: a black suit with white stripes, blue-cuffed
## gloves and a big flat cartoon head. Heads are painted at runtime into textures (no art files needed)
## and shown on a quad; bodies are simple boxes. The model faces -Z (Godot's forward).
## Kinds: sonia, serrani, surrena (the "Fatal" three), rencha, cybot, ivina, bolten (the "Stalk" class)
## and dreina (a "Friendler"). Enemies are drawn as Corrupted: black Sonium goo and glowing red eyes.

# kind -> [metres per pixel, pixel row of the head's bottom edge, pixel column of the head's centre, extra gap above the body]
const HEAD_SPEC := {
	"sonia": [0.0025, 190, 260, 0.0],
	"serrani": [0.0022, 290, 210, 0.0],
	"surrena": [0.0026, 295, 150, 0.0],
	"rencha": [0.0019, 205, 260, 0.1],
	"cybot": [0.0024, 260, 110, 0.0],
	"ivina": [0.0024, 262, 110, 0.0],
	"bolten": [0.0023, 245, 115, 0.0],
	"dreina": [0.0023, 265, 110, 0.0],
	"shovelina": [0.0024, 225, 110, 0.0],
	"lim": [0.0022, 230, 100, 0.0],
	"lem": [0.0022, 230, 100, 0.0],
	"limlem": [0.0022, 230, 100, 0.0],
	"minchei": [0.0024, 210, 115, 0.0],
}

# kind -> pixel positions (column, row) of the two eyes in the head texture, used for the red Corruption glow
const EYES := {
	"sonia": [Vector2(172, 109), Vector2(344, 109)],
	"serrani": [Vector2(110, 135), Vector2(210, 128)],
	"surrena": [Vector2(100, 112), Vector2(207, 115)],
	"rencha": [Vector2(250, 138), Vector2(360, 148)],
	"cybot": [Vector2(80, 160), Vector2(138, 160)],
	"ivina": [Vector2(85, 150), Vector2(138, 150)],
	"bolten": [Vector2(95, 120), Vector2(140, 104)],
	"dreina": [Vector2(80, 165), Vector2(140, 165)],
	"shovelina": [Vector2(75, 150), Vector2(145, 150)],
	"lim": [Vector2(65, 130), Vector2(135, 130)],
	"lem": [Vector2(65, 130), Vector2(135, 130)],
	"limlem": [Vector2(65, 130), Vector2(135, 130)],
	"minchei": [Vector2(85, 110), Vector2(150, 110)],
}

# body styles: torso, stripes (or null), belt, pants, arm, cuff, arm stripe, extra
const BODY_STYLES := {
	"fatal": {"torso": Color(0, 0, 0), "stripe": Color.WHITE, "belt": Color.WHITE, "pants": Color(0.35, 0.35, 0.35), "arm": Color(0, 0, 0), "cuff": Color(0.12, 0.3, 0.75), "arm_stripe": true},
	"rencha": {"torso": Color(0.27, 0.27, 0.27), "stripe": null, "belt": null, "pants": Color(0.62, 0.78, 0.92), "arm": Color(0.27, 0.27, 0.27), "cuff": Color(0.7, 0.7, 0.7), "arm_stripe": false},
	"cybot": {"torso": Color(0.27, 0.27, 0.27), "stripe": null, "belt": Color(0.45, 0.25, 0.05), "pants": Color(0.25, 0.45, 0.9), "arm": Color(0.3, 0.3, 0.3), "cuff": Color(0.8, 0.82, 0.85), "arm_stripe": false},
	"ivina": {"torso": Color(0.95, 0.95, 0.95), "stripe": Color.BLACK, "belt": Color.BLACK, "pants": Color(0.95, 0.95, 0.95), "arm": Color(0.95, 0.95, 0.95), "cuff": Color(0.4, 0.65, 0.3), "arm_stripe": true},
	"dreina": {"torso": Color(0.95, 0.95, 0.95), "stripe": Color.BLACK, "belt": Color.BLACK, "pants": Color(0.95, 0.95, 0.95), "arm": Color(0.95, 0.95, 0.95), "cuff": Color(0.25, 0.5, 0.95), "arm_stripe": true},
	"shovelina": {"torso": Color(0.87, 0.4, 0.37), "stripe": null, "belt": Color.BLACK, "pants": Color(0.25, 0.45, 0.85), "arm": Color(0.72, 0.85, 0.7), "cuff": Color.BLACK, "arm_stripe": false},
	"lim": {"torso": Color(0.15, 0.28, 0.1), "stripe": null, "belt": Color(0.93, 0.93, 0.93), "pants": Color(0.4, 0.0, 0.0), "arm": Color(0.15, 0.28, 0.1), "cuff": Color(0.95, 0.76, 0.18), "arm_stripe": false},
	"lem": {"torso": Color(0.5, 0.37, 0.0), "stripe": null, "belt": Color(0.93, 0.93, 0.93), "pants": Color(0.03, 0.2, 0.4), "arm": Color(0.5, 0.37, 0.0), "cuff": Color(0.4, 0.65, 0.3), "arm_stripe": false},
	"minchei": {"torso": Color(0.75, 0.45, 0.6), "stripe": null, "belt": null, "pants": Color(0.72, 0.85, 0.7), "arm": Color(0.55, 0.5, 0.75), "cuff": Color(0.55, 0.5, 0.75), "arm_stripe": false},
	"bolten": {"torso": Color(0.8, 0.02, 0.02), "stripe": Color.BLACK, "belt": Color.BLACK, "pants": Color(0.8, 0.02, 0.02), "arm": Color(0.8, 0.02, 0.02), "cuff": Color(1.0, 0.9, 0.1), "arm_stripe": false},
}

static var _tex_cache := {}


static func style_of(kind: String) -> String:
	match kind:
		"sonia", "serrani", "surrena":
			return "fatal"
	return kind


## An enemy: body + head, then black Sonium goo and red glowing eyes ("Corrupted").
static func build(kind: String) -> Node3D:
	var root := Node3D.new()
	if kind == "limlem":
		# two siblings who never split more than a few inches apart: Lim (lemon) and Lem (lime)
		for pair in [["lim", -0.36], ["lem", 0.36]]:
			var one := Node3D.new()
			one.scale = Vector3(0.82, 0.82, 0.82)
			one.position.x = pair[1]
			_body(one, pair[0])
			_head(one, pair[0])
			_corrupt(one, pair[0])
			root.add_child(one)
		return root
	_body(root, style_of(kind))
	_head(root, kind)
	_corrupt(root, kind)
	return root


static func _corrupt(root: Node3D, kind: String) -> void:
	# black goo blotches on the body
	for blot in [[Vector3(0.0, 0.95, 0.0), Vector3(0.5, 0.34, 0.33)], [Vector3(-0.2, 1.38, 0.0), Vector3(0.18, 0.2, 0.31)],
			[Vector3(0.22, 0.45, 0.0), Vector3(0.26, 0.5, 0.28)]]:
		_box(root, blot[0], blot[1], Color(0.02, 0.0, 0.03))
	# red glowing eyes in front of the head
	var spec: Array = HEAD_SPEC[kind]
	var scale: float = spec[0]
	for e in EYES[kind]:
		var pos := Vector3((float(spec[2]) - e.x) * scale, 1.45 + float(spec[3]) + (float(spec[1]) - e.y) * scale, -0.06)
		var m := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.05
		sm.height = 0.1
		m.mesh = sm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.05, 0.05)
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.0, 0.0)
		mat.emission_energy_multiplier = 3.0
		m.material_override = mat
		m.position = pos
		root.add_child(m)
	# the glow shows where the Corruption is in poor lighting
	var glow := OmniLight3D.new()
	glow.position = Vector3(0, 1.7, -0.3)
	glow.light_color = Color(1.0, 0.1, 0.05)
	glow.light_energy = 0.9
	glow.omni_range = 4.0
	root.add_child(glow)


## A plain figure for the player (used for the elevator mirror reflection): the same suit with a skin-coloured head.
static func build_player(skin: Color) -> Node3D:
	var root := Node3D.new()
	_body(root, "fatal")
	var head := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.2
	sm.height = 0.4
	head.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = skin
	head.material_override = mat
	head.position = Vector3(0, 1.68, 0)
	root.add_child(head)
	for sx in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		var em := SphereMesh.new()
		em.radius = 0.035
		em.height = 0.07
		eye.mesh = em
		var emat := StandardMaterial3D.new()
		emat.albedo_color = Color.BLACK
		eye.material_override = emat
		eye.position = Vector3(sx * 0.08, 1.71, -0.17)
		root.add_child(eye)
	return root


static func set_visual_layers(node: Node, layers: int) -> void:
	if node is VisualInstance3D:
		(node as VisualInstance3D).layers = layers
	for c in node.get_children():
		set_visual_layers(c, layers)


static func _body(root: Node3D, style: String) -> void:
	var st: Dictionary = BODY_STYLES[style]
	for sx in [-1.0, 1.0]:
		_box(root, Vector3(sx * 0.13, 0.4, 0), Vector3(0.22, 0.8, 0.24), st["pants"])
	_box(root, Vector3(0, 1.12, 0), Vector3(0.46, 0.66, 0.28), st["torso"])
	if st["stripe"] != null:
		for sx in [-1.0, 1.0]:
			_box(root, Vector3(sx * 0.1, 1.12, -0.145), Vector3(0.035, 0.6, 0.01), st["stripe"])
	if st["belt"] != null:
		_box(root, Vector3(0, 0.82, 0), Vector3(0.48, 0.06, 0.3), st["belt"])
	for sx in [-1.0, 1.0]:
		_arm(root, sx, st["arm"], st["cuff"], st["arm_stripe"], style == "rencha" and sx > 0.0)
	if style == "rencha":
		_box(root, Vector3(0, 1.5, 0), Vector3(0.1, 0.14, 0.1), Color(0.6, 0.6, 0.6))
	elif style == "cybot":
		_box(root, Vector3(0, 1.5, 0), Vector3(0.1, 0.14, 0.1), Color(0.8, 0.8, 0.8))


static func _box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	m.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	m.material_override = mat
	m.position = pos
	parent.add_child(m)


static func _arm(root: Node3D, sx: float, suit: Color, cuff: Color, striped: bool, raised: bool) -> void:
	var pivot := Node3D.new()
	pivot.position = Vector3(sx * 0.25, 1.38, 0)
	pivot.rotation_degrees.z = sx * (55.0 if raised else -25.0)
	root.add_child(pivot)
	_box(pivot, Vector3(sx * 0.31, 0, 0), Vector3(0.62, 0.11, 0.11), suit)
	if striped:
		_box(pivot, Vector3(sx * 0.31, 0, -0.057), Vector3(0.5, 0.03, 0.01), Color.WHITE)
	_box(pivot, Vector3(sx * 0.66, 0, 0), Vector3(0.1, 0.14, 0.14), cuff)


static func _head(root: Node3D, kind: String) -> void:
	var tex := _texture(kind)
	var spec: Array = HEAD_SPEC[kind]
	var scale: float = spec[0]
	var w := float(tex.get_width())
	var h := float(tex.get_height())
	var quad := QuadMesh.new()
	quad.size = Vector2(w * scale, h * scale)
	var m := MeshInstance3D.new()
	m.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.alpha_scissor_threshold = 0.5
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	m.material_override = mat
	# The quad is turned 180 degrees about Y so its front faces -Z; texture-right is then world -X.
	m.rotation_degrees.y = 180.0
	m.position = Vector3((float(spec[2]) - w / 2.0) * scale, 1.45 + float(spec[3]) + (float(spec[1]) - h / 2.0) * scale, -0.02)
	root.add_child(m)


# --- painting --------------------------------------------------------------------

static func _texture(kind: String) -> ImageTexture:
	if _tex_cache.has(kind):
		return _tex_cache[kind]
	var img: Image
	match kind:
		"sonia":
			img = _draw_sonia()
		"serrani":
			img = _draw_serrani()
		"surrena":
			img = _draw_surrena()
		"cybot":
			img = _draw_cybot()
		"ivina":
			img = _draw_ivina()
		"bolten":
			img = _draw_bolten()
		"dreina":
			img = _draw_dreina()
		"shovelina":
			img = _draw_shovelina()
		"lim", "limlem":
			img = _draw_lim(false)
		"lem":
			img = _draw_lim(true)
		"minchei":
			img = _draw_minchei()
		_:
			img = _draw_rencha()
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_tex_cache[kind] = tex
	return tex


static func image_for(kind: String) -> Image:
	## Exposed for tests / previews.
	return _texture(kind).get_image()


static func _new(w: int, h: int) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img


static func _color_at(c: Variant, x: int, y: int) -> Color:
	if c is Callable:
		return (c as Callable).call(x, y)
	return c


static func _ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, c: Variant) -> void:
	for y in range(maxi(0, int(cy - ry)), mini(img.get_height(), int(cy + ry) + 1)):
		for x in range(maxi(0, int(cx - rx)), mini(img.get_width(), int(cx + rx) + 1)):
			var dx := (x - cx) / rx
			var dy := (y - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(x, y, _color_at(c, x, y))


static func _rrect(img: Image, rx: int, ry: int, rw: int, rh: int, radius: float, c: Variant) -> void:
	for y in range(maxi(0, ry), mini(img.get_height(), ry + rh)):
		for x in range(maxi(0, rx), mini(img.get_width(), rx + rw)):
			var nx := clampf(x, rx + radius, rx + rw - radius)
			var ny := clampf(y, ry + radius, ry + rh - radius)
			if Vector2(x - nx, y - ny).length() <= radius:
				img.set_pixel(x, y, _color_at(c, x, y))


static func _poly(img: Image, pts: PackedVector2Array, c: Variant) -> void:
	var minx := 100000.0
	var miny := 100000.0
	var maxx := -100000.0
	var maxy := -100000.0
	for p in pts:
		minx = minf(minx, p.x)
		miny = minf(miny, p.y)
		maxx = maxf(maxx, p.x)
		maxy = maxf(maxy, p.y)
	for y in range(maxi(0, int(miny)), mini(img.get_height(), int(maxy) + 1)):
		for x in range(maxi(0, int(minx)), mini(img.get_width(), int(maxx) + 1)):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), pts):
				img.set_pixel(x, y, _color_at(c, x, y))


static func _shrink(pts: PackedVector2Array, factor: float) -> PackedVector2Array:
	var centre := Vector2.ZERO
	for p in pts:
		centre += p
	centre /= pts.size()
	var out := PackedVector2Array()
	for p in pts:
		out.append(centre.lerp(p, factor))
	return out


static func _draw_sonia() -> Image:
	var img := _new(460, 200)
	# syringe needle on the left, dark tip fading to light
	_poly(img, PackedVector2Array([Vector2(0, 95), Vector2(28, 80), Vector2(75, 80), Vector2(75, 110), Vector2(28, 110)]),
		func(x, _y): return Color.from_hsv(0.0, 0.0, lerpf(0.15, 0.85, x / 75.0)))
	# rainbow tabs on top of the head
	var tab_colors := [Color.RED, Color(1, 0.6, 0), Color.YELLOW, Color(0, 0.9, 0), Color.CYAN, Color.BLUE, Color(0.6, 0, 1)]
	var tab_x := [0.17, 0.28, 0.38, 0.49, 0.64, 0.76, 0.88]
	for i in 7:
		img.fill_rect(Rect2i(int(70 + tab_x[i] * 380), 4, 14, 34), tab_colors[i])
	_rrect(img, 70, 35, 380, 155, 22.0, Color(0.93, 0.93, 0.93))
	for ex in [172.0, 344.0]:
		_ellipse(img, ex, 109, 40, 40, Color.BLACK)
		_ellipse(img, ex, 109, 33, 33, Color.WHITE)
		_ellipse(img, ex, 109, 26, 26, Color.BLACK)
	_poly(img, PackedVector2Array([Vector2(226, 140), Vector2(271, 136), Vector2(249, 164)]), Color.BLACK)
	return img


static func _draw_serrani() -> Image:
	var img := _new(420, 300)
	img.fill_rect(Rect2i(330, 0, 9, 55), Color.BLACK)   # antennas
	img.fill_rect(Rect2i(352, 0, 9, 50), Color.BLACK)
	_rrect(img, 20, 45, 380, 245, 40.0, Color(0.25, 0.5, 0.9))                  # blue rim
	_rrect(img, 26, 51, 368, 233, 35.0, func(x, _y): return Color.from_hsv(0.0, 0.0, clampf((x - 26.0) / 368.0, 0.0, 1.0)))  # black->white frame
	_rrect(img, 48, 73, 324, 179, 30.0, Color(0.25, 0.5, 0.9))
	_rrect(img, 51, 76, 318, 173, 27.0, Color.BLACK)                            # screen
	_ellipse(img, 110, 135, 22, 17, Color.WHITE)
	_ellipse(img, 104, 137, 11, 11, Color.BLACK)
	_ellipse(img, 210, 128, 22, 17, Color.WHITE)
	_ellipse(img, 216, 130, 11, 11, Color.BLACK)
	var mouth := PackedVector2Array([Vector2(84, 165), Vector2(147, 156), Vector2(210, 159), Vector2(260, 174), Vector2(218, 216), Vector2(160, 234), Vector2(118, 210)])
	_poly(img, mouth, Color.WHITE)
	_poly(img, _shrink(mouth, 0.72), Color.BLACK)
	return img


static func _draw_surrena() -> Image:
	var img := _new(300, 300)
	var pts := PackedVector2Array()
	for i in 20:
		var ang := i * TAU / 20.0 - PI / 2.0
		var r := 145.0 if i % 2 == 0 else 118.0
		pts.append(Vector2(150, 150) + Vector2(cos(ang), sin(ang)) * r)
	_poly(img, pts, func(_x, y): return Color(1.0, 0.12, 0.0).lerp(Color(1.0, 0.92, 0.0), clampf(y / 300.0, 0.0, 1.0)))
	_ellipse(img, 100, 112, 36, 34, Color.WHITE)
	_ellipse(img, 100, 114, 27, 27, Color.BLACK)
	_ellipse(img, 207, 115, 33, 31, Color.WHITE)
	_ellipse(img, 207, 117, 24, 24, Color.BLACK)
	_poly(img, PackedVector2Array([Vector2(85, 190), Vector2(155, 182), Vector2(225, 187), Vector2(188, 212), Vector2(152, 208), Vector2(120, 217)]), Color.BLACK)
	return img


static func _draw_rencha() -> Image:
	var img := _new(520, 260)
	var grey := Color(0.62, 0.62, 0.62)
	_ellipse(img, 80, 130, 75, 75, grey)                 # ring end of the wrench
	_ellipse(img, 80, 130, 38, 38, Color(0, 0, 0, 0))
	_rrect(img, 110, 98, 300, 78, 10.0, grey)             # handle / face
	_ellipse(img, 430, 128, 78, 78, grey)                # open jaw
	_ellipse(img, 492, 125, 60, 50, Color(0, 0, 0, 0))
	_ellipse(img, 250, 138, 40, 27, Color.WHITE)
	_ellipse(img, 250, 140, 31, 20, Color.BLACK)
	_ellipse(img, 360, 148, 40, 27, Color.WHITE)
	_ellipse(img, 360, 150, 31, 20, Color.BLACK)
	_poly(img, PackedVector2Array([Vector2(300, 176), Vector2(336, 172), Vector2(318, 196)]), Color.BLACK)
	return img


static func _eye(img: Image, cx: float, cy: float, rx: float, ry: float) -> void:
	_ellipse(img, cx, cy, rx, ry, Color.WHITE)
	_ellipse(img, cx + 1, cy + 2, rx * 0.72, ry * 0.72, Color.BLACK)


static func _draw_cybot() -> Image:
	var img := _new(220, 270)
	_rrect(img, 38, 0, 144, 84, 6.0, Color(0.05, 0.05, 0.05))     # top hat
	_rrect(img, 22, 70, 176, 26, 5.0, Color(1.0, 0.6, 0.05))      # orange hat band
	_rrect(img, 34, 100, 152, 160, 10.0, Color(0.82, 0.82, 0.82)) # square head
	_rrect(img, 66, 148, 30, 26, 4.0, Color.BLACK)                # eyes
	_rrect(img, 124, 148, 30, 26, 4.0, Color.BLACK)
	_rrect(img, 72, 154, 12, 12, 2.0, Color.WHITE)
	_rrect(img, 130, 154, 12, 12, 2.0, Color.WHITE)
	_rrect(img, 88, 206, 44, 12, 4.0, Color.BLACK)                # mouth
	return img


static func _draw_ivina() -> Image:
	var img := _new(220, 270)
	var leaf := func(_x, y): return Color(0.4, 0.5, 0.3).lerp(Color(0.62, 0.75, 0.5), clampf(y / 262.0, 0.0, 1.0))
	_poly(img, PackedVector2Array([Vector2(150, 0), Vector2(60, 120), Vector2(170, 130)]), leaf)  # pointed leaf tip
	_ellipse(img, 112, 175, 78, 88, leaf)
	_eye(img, 86, 150, 20, 16)
	_eye(img, 140, 148, 20, 16)
	_poly(img, PackedVector2Array([Vector2(98, 200), Vector2(126, 198), Vector2(112, 214)]), Color.BLACK)
	return img


static func _draw_bolten() -> Image:
	var img := _new(220, 250)
	var yellow := Color(1.0, 0.85, 0.05)
	_poly(img, PackedVector2Array([Vector2(105, 0), Vector2(30, 120), Vector2(90, 112), Vector2(50, 245), Vector2(190, 95), Vector2(125, 105), Vector2(180, 0)]), yellow)
	_eye(img, 93, 125, 17, 14)
	_eye(img, 142, 106, 17, 14)
	_poly(img, PackedVector2Array([Vector2(100, 170), Vector2(138, 150), Vector2(124, 178)]), Color.BLACK)
	return img


static func _draw_dreina() -> Image:
	var img := _new(250, 280)
	var blue := Color(0.25, 0.5, 0.95)
	_poly(img, PackedVector2Array([Vector2(112, 20), Vector2(36, 135), Vector2(188, 135)]), blue)   # droplet tip
	_ellipse(img, 112, 180, 85, 92, blue)
	_ellipse(img, 175, 38, 42, 32, Color(0.1, 0.1, 0.85))     # blue blob on top
	_ellipse(img, 222, 70, 22, 22, Color(0.2, 0.3, 0.95))
	_eye(img, 80, 168, 20, 17)
	_eye(img, 142, 168, 20, 17)
	_poly(img, PackedVector2Array([Vector2(98, 205), Vector2(150, 200), Vector2(124, 226)]), Color.BLACK)
	return img


static func _draw_shovelina() -> Image:
	var img := _new(220, 260)
	_rrect(img, 40, 100, 140, 125, 6, Color(0.35, 0.35, 0.35))        # grey head
	_rrect(img, 36, 0, 148, 108, 4, Color(1.0, 1.0, 0.0))              # tall yellow hat
	_poly(img, PackedVector2Array([Vector2(50, 60), Vector2(110, 22), Vector2(170, 70), Vector2(160, 78), Vector2(110, 40), Vector2(60, 72)]), Color.BLACK)
	_eye(img, 75, 150, 13, 13)
	_ellipse(img, 145, 150, 18, 8, Color.BLACK)                         # winking eye
	_poly(img, PackedVector2Array([Vector2(85, 178), Vector2(140, 172), Vector2(125, 200), Vector2(100, 198)]), Color.BLACK)
	return img


static func _draw_lim(lime: bool) -> Image:
	var img := _new(200, 260)
	var head := Color(0.42, 0.66, 0.3) if lime else Color(0.95, 0.76, 0.18)
	_ellipse(img, 100, 130, 76, 100, head)
	_poly(img, PackedVector2Array([Vector2(60, 40), Vector2(100, 0), Vector2(142, 40), Vector2(126, 78), Vector2(74, 78)]), Color(0.15, 0.3, 0.1))
	_eye(img, 65, 130, 17, 17)
	_eye(img, 135, 130, 17, 17)
	_poly(img, PackedVector2Array([Vector2(75, 178), Vector2(125, 172), Vector2(112, 184), Vector2(85, 184)]), Color.BLACK)
	return img


static func _draw_minchei() -> Image:
	var img := _new(230, 240)
	var skin := Color(0.55, 0.5, 0.75)
	_rrect(img, 30, 40, 170, 170, 28, skin)                             # mitten-shaped head
	_rrect(img, 30, 0, 170, 60, 26, Color(0.62, 0.0, 1.0))             # bright purple hair
	_poly(img, PackedVector2Array([Vector2(0, 80), Vector2(40, 40), Vector2(60, 70), Vector2(30, 120)]), Color(0.62, 0.0, 1.0))
	_eye(img, 85, 110, 22, 22)
	_eye(img, 150, 110, 22, 22)
	_poly(img, PackedVector2Array([Vector2(75, 160), Vector2(160, 158), Vector2(135, 195), Vector2(100, 195)]), Color.BLACK)
	return img
