extends Node3D
## Floor hazards created by Corruptions. Polls the player's distance (no physics needed).
##   puddle - Dreina's Sonium puddle: slows you and makes it harder to see.
##   hard   - a puddle with a hard chunk of Dreina: step in and it sticks to you (she then chases harder).
##   plant  - Ivina's thorn plant: poisons and slows you.
## Set `type` before adding to the tree.

var type := "puddle"
var radius := 1.4
var lifetime := 20.0

var _born := 0.0
var _used := false


func _ready() -> void:
	add_to_group("hazards")
	_born = RoundManager.now()
	var m := MeshInstance3D.new()
	var mat := StandardMaterial3D.new()
	match type:
		"plant":
			radius = 1.1
			lifetime = 45.0
			var cone := CylinderMesh.new()
			cone.top_radius = 0.0
			cone.bottom_radius = 0.7
			cone.height = 1.4
			m.mesh = cone
			m.position.y = 0.7
			mat.albedo_color = Color(0.15, 0.55, 0.15)
			var thorn := MeshInstance3D.new()
			var tm := CylinderMesh.new()
			tm.top_radius = 0.0
			tm.bottom_radius = 0.18
			tm.height = 0.9
			thorn.mesh = tm
			thorn.position = Vector3(0.45, 0.45, 0.2)
			thorn.rotation_degrees.z = -25.0
			var tmat := StandardMaterial3D.new()
			tmat.albedo_color = Color(0.5, 0.15, 0.4)
			thorn.material_override = tmat
			add_child(thorn)
		_:
			var disc := CylinderMesh.new()
			disc.top_radius = radius
			disc.bottom_radius = radius
			disc.height = 0.05
			m.mesh = disc
			m.position.y = 0.03
			mat.albedo_color = Color(0.1, 0.3, 0.9, 0.8) if type == "puddle" else Color(0.05, 0.12, 0.5, 0.9)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.metallic = 0.4
			mat.roughness = 0.2
			if type == "hard":
				var chunk := MeshInstance3D.new()
				var sm := SphereMesh.new()
				sm.radius = 0.3
				sm.height = 0.6
				chunk.mesh = sm
				chunk.position.y = 0.3
				var cmat := StandardMaterial3D.new()
				cmat.albedo_color = Color(0.1, 0.2, 0.8)
				chunk.material_override = cmat
				add_child(chunk)
	m.material_override = mat
	add_child(m)
	# visible on the minimap
	FloorBuilder.map_marker(self, Color(0.2, 0.4, 1.0) if type != "plant" else Color(0.2, 0.8, 0.2), 0.6, 7.0)


func _process(_delta: float) -> void:
	var t := RoundManager.now()
	if t - _born > lifetime or not RoundManager.in_floor():
		queue_free()
		return
	var p := get_tree().get_first_node_in_group("player") as Node3D
	if p == null:
		return
	var d := Vector2(p.global_position.x - global_position.x, p.global_position.z - global_position.z).length()
	if d > radius:
		return
	match type:
		"puddle":
			RoundManager.add_slow("puddle", 0.55, 0.4)
			RoundManager.add_dim(0.5)
		"hard":
			if not _used:
				_used = true
				RoundManager.add_chunk(12.0)
				RoundManager.notice.emit("A chunk of Dreina is stuck on you - she is chasing harder!")
				queue_free()
		"plant":
			RoundManager.poison(6.0)
			RoundManager.add_slow("plant", 0.7, 0.4)
