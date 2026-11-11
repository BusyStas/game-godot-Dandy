extends Node3D
## A fixable machine. Stand close and press E. Kinds (from the deck):
##   regular   - hold E ~3 s
##   hard      - hold E ~6 s
##   treadmill - hold E ~5 s, progress drains quickly when you let go
##   clicker   - tap E 12 times
##   search    - hold E ~4 s, progress is hidden ("searching")
## Fixing grants Sonium; it only counts toward the floor task on "machines" floors.

const RANGE := 3.0
const KINDS := {
	"regular": {"goal": 3.0, "color": Color(0.7, 0.2, 0.2)},
	"hard": {"goal": 6.0, "color": Color(0.5, 0.1, 0.4)},
	"treadmill": {"goal": 5.0, "color": Color(0.8, 0.5, 0.1)},
	"clicker": {"goal": 12.0, "color": Color(0.2, 0.4, 0.8)},
	"search": {"goal": 4.0, "color": Color(0.3, 0.6, 0.6)},
}

var kind := "regular"
var progress := 0.0
var done := false

var _goal := 3.0
var _mat: StandardMaterial3D
var _label: Label3D


func _ready() -> void:
	_goal = KINDS[kind]["goal"]
	var body := StaticBody3D.new()
	body.position.y = 0.7
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.2, 1.4, 1.2)
	mesh.mesh = bm
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = KINDS[kind]["color"]
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


func _player() -> Node3D:
	return get_tree().get_first_node_in_group("player") as Node3D


func _near(p: Node3D) -> bool:
	return p != null and p.global_position.distance_to(global_position) < RANGE


func _process(delta: float) -> void:
	if done:
		return
	var p := _player()
	var near := _near(p)
	var holding := near and Input.is_physical_key_pressed(KEY_E) and not bool(p.get("frozen"))
	match kind:
		"clicker":
			pass  # progress comes from key taps in _unhandled_input
		"treadmill":
			if holding:
				progress += delta * float(p.get("fix_speed"))
				p.call("make_noise", 8.0)
			else:
				progress = maxf(0.0, progress - delta * 1.5)
		_:
			if holding:
				progress += delta * float(p.get("fix_speed"))
				p.call("make_noise", 8.0)
	if progress >= _goal:
		_finish()
	_update_label()


func _unhandled_input(event: InputEvent) -> void:
	if done or kind != "clicker":
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		var p := _player()
		if _near(p):
			progress += float(p.get("fix_speed"))
			p.call("make_noise", 10.0)


func _finish() -> void:
	done = true
	_mat.albedo_color = Color(0.2, 0.7, 0.3)
	RoundManager.machine_fixed()
	_update_label()


func _update_label() -> void:
	if done:
		_label.text = "Fixed"
		return
	var title := "%s machine" % kind.capitalize()
	match kind:
		"clicker":
			_label.text = "%s: tap E (%d/%d)" % [title, int(progress), int(_goal)]
		"search":
			_label.text = "%s: hold E%s" % [title, " (searching...)" if progress > 0.0 else ""]
		_:
			if progress > 0.0:
				_label.text = "%s: %d%%" % [title, int(progress / _goal * 100.0)]
			else:
				_label.text = "%s: hold E" % title
