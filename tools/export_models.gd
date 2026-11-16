extends SceneTree
## Writes every Corruption's painted head to assets/characters/<kind>.png so the art exists as files.
## Run:  godot --headless --path . -s tools/export_models.gd
func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/characters")
	for kind in ["sonia", "serrani", "surrena", "rencha", "cybot", "ivina", "bolten", "dreina", "shovelina", "lim", "lem", "minchei"]:
		var img: Image = CharacterModel.image_for(kind)
		img.save_png("res://assets/characters/%s_head.png" % kind)
		print("wrote ", kind)
	quit()
