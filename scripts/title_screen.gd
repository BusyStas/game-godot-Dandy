extends Control
## Loading/title screen. The "i" in Soria is her head sideways (a teal capsule lying down).
## First launch: pick one of the two starting characters. Afterwards: just start.

const LOBBY := "res://scenes/lobby.tscn"


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 18)
	center.add_child(vb)

	# Logo: "Sor" + sideways head + "a's Expeditions"
	var logo := HBoxContainer.new()
	logo.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(logo)
	logo.add_child(_logo_label("Sor"))
	var head := Control.new()
	head.custom_minimum_size = Vector2(70, 70)
	logo.add_child(head)
	var capsule := ColorRect.new()  # the head, lying on its side
	capsule.color = Color(0.2, 0.75, 0.7)
	capsule.size = Vector2(60, 24)
	capsule.position = Vector2(5, 34)
	head.add_child(capsule)
	var needle := ColorRect.new()
	needle.color = Color(0.8, 0.85, 0.9)
	needle.size = Vector2(10, 4)
	needle.position = Vector2(60, 44)
	head.add_child(needle)
	logo.add_child(_logo_label("a's Expeditions"))

	if RoundManager.starter_chosen:
		var start := Button.new()
		start.text = "Start"
		start.custom_minimum_size = Vector2(260, 56)
		start.pressed.connect(_go)
		vb.add_child(start)
		var info := Label.new()
		info.text = "Sonium: %d   Best floor: %d" % [RoundManager.sonium, RoundManager.best_floor]
		info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(info)
	else:
		var prompt := Label.new()
		prompt.text = "Choose your starting character"
		prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		prompt.add_theme_font_size_override("font_size", 24)
		vb.add_child(prompt)
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 20)
		vb.add_child(row)
		for id in GameData.STARTERS:
			var info: Dictionary = GameData.CHARACTERS[id]
			var b := Button.new()
			b.text = "%s\n%s" % [info["name"], info["desc"]]
			b.custom_minimum_size = Vector2(230, 100)
			b.pressed.connect(_pick.bind(id))
			row.add_child(b)


func _logo_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 64)
	return l


func _pick(id: String) -> void:
	RoundManager.choose_starter(id)
	_go()


func _go() -> void:
	get_tree().change_scene_to_file(LOBBY)
