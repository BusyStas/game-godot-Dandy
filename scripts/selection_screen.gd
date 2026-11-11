extends CanvasLayer
## Pre-run selection UI: character, skin, utility, player-card decoration.
## open() shows it, confirm() commits the choices, close(false) hides without committing.

signal confirmed

const KEYS := ["character", "skin", "utility", "decoration"]
const TITLES := {"character": "Character", "skin": "Skin", "utility": "Utility", "decoration": "Card decoration"}

var _opts := {}


func _ready() -> void:
	layer = 10
	visible = false
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.65)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(440, 0)
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)
	var title := Label.new()
	title.text = "Choose your loadout"
	title.add_theme_font_size_override("font_size", 28)
	vb.add_child(title)
	for key in KEYS:
		var row := HBoxContainer.new()
		var l := Label.new()
		l.text = TITLES[key]
		l.custom_minimum_size = Vector2(150, 0)
		row.add_child(l)
		var ob := OptionButton.new()
		ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(ob)
		vb.add_child(row)
		_opts[key] = ob
	var hint := Label.new()
	hint.text = "Auto-confirms when the timer ends. Enter also confirms."
	vb.add_child(hint)
	var btn := Button.new()
	btn.text = "Ready"
	btn.pressed.connect(confirm)
	vb.add_child(btn)


func open() -> void:
	_fill("character", RoundManager.owned["characters"], GameData.CHARACTERS)
	_fill("skin", RoundManager.owned["skins"], GameData.SKINS)
	_fill("utility", GameData.UTILITIES.keys(), GameData.UTILITIES)
	_fill("decoration", RoundManager.owned["decorations"], GameData.DECORATIONS)
	visible = true


func is_open() -> bool:
	return visible


func confirm() -> void:
	if not visible:
		return
	close(true)
	confirmed.emit()


func close(commit: bool) -> void:
	if visible and commit:
		for key in KEYS:
			var ob: OptionButton = _opts[key]
			if ob.selected >= 0:
				RoundManager.set_loadout(key, str(ob.get_item_metadata(ob.selected)))
	visible = false


func _fill(key: String, ids: Array, data: Dictionary) -> void:
	var ob: OptionButton = _opts[key]
	ob.clear()
	var current: String = RoundManager.loadout[key]
	var select := 0
	for id in ids:
		var info: Dictionary = data[id]
		var text: String = info["name"]
		if info.has("desc") and info["desc"] != "":
			text += "  -  " + info["desc"]
		ob.add_item(text)
		ob.set_item_metadata(ob.item_count - 1, id)
		if id == current:
			select = ob.item_count - 1
	ob.select(select)
