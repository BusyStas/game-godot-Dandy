class_name CharacterModel
extends RefCounted
## Builds the characters as drawn in the design deck: a black suit with white stripes, blue-cuffed
## gloves and a big flat cartoon head. Heads are painted at runtime into textures (no art files needed)
## and shown on a quad; bodies are simple boxes. The model faces -Z (Godot's forward).
## Kinds: soria, serrani, surrena (the "Fatal" three) and rencha (a "Stalk" enemy).

# kind -> [metres per pixel, pixel row of the head's bottom edge, pixel column of the head's centre, extra gap above the body]
const HEAD_SPEC := {
	"soria": [0.0025, 190, 260, 0.0],
	"serrani": [0.0022, 290, 210, 0.0],
	"surrena": [0.0026, 295, 150, 0.0],
	"rencha": [0.0019, 205, 260, 0.1],
}

static var _tex_cache := {}


static func build(kind: String) -> Node3D:
	var root := Node3D.new()
	var fatal := kind != "rencha"
	var suit := Color(0, 0, 0) if fatal else Color(0.27, 0.27, 0.27)
	var pants := Color(0.35, 0.35, 0.35) if fatal else Color(0.62, 0.78, 0.92)
	var cuff := Color(0.12, 0.3, 0.75) if fatal else Color(0.7, 0.7, 0.7)

	for sx in [-1.0, 1.0]:
		_box(root, Vector3(sx * 0.13, 0.4, 0), Vector3(0.22, 0.8, 0.24), pants)
	_box(root, Vector3(0, 1.12, 0), Vector3(0.46, 0.66, 0.28), suit)
	if fatal:
		for sx in [-1.0, 1.0]:
			_box(root, Vector3(sx * 0.1, 1.12, -0.145), Vector3(0.035, 0.6, 0.01), Color.WHITE)
		_box(root, Vector3(0, 0.82, 0), Vector3(0.48, 0.06, 0.3), Color.WHITE)
	for sx in [-1.0, 1.0]:
		_arm(root, sx, suit, cuff, fatal, (not fatal) and sx > 0.0)
	if not fatal:
		_box(root, Vector3(0, 1.5, 0), Vector3(0.1, 0.14, 0.1), Color(0.6, 0.6, 0.6))
	_head(root, kind)
	return root


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
		"soria":
			img = _draw_soria()
		"serrani":
			img = _draw_serrani()
		"surrena":
			img = _draw_surrena()
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


static func _draw_soria() -> Image:
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
