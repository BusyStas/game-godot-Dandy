extends CanvasLayer
## Shop window for the three lobby shops (characters / skins / decorations).
## Buy with Sonium, then Equip. Everything persists via RoundManager.

signal closed

const HEADINGS := {
	"characters": "Shop 1 - Characters (Soria)",
	"skins": "Shop 2 - Skins (Serrani)",
	"decorations": "Shop 3 - Player Card Decorations",
}
const LOADOUT_KEY := {"characters": "character", "skins": "skin", "decorations": "decoration"}

var _category := ""
var _list: VBoxContainer
var _title: Label
var _wallet: Label


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
	vb.custom_minimum_size = Vector2(560, 0)
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 28)
	vb.add_child(_title)
	_wallet = Label.new()
	vb.add_child(_wallet)
	_list = VBoxContainer.new()
	vb.add_child(_list)
	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(close)
	vb.add_child(close_btn)
	RoundManager.sonium_changed.connect(func(_t): if visible: _refresh())


func open(category: String) -> void:
	_category = category
	_title.text = HEADINGS[category]
	_refresh()
	visible = true


func is_open() -> bool:
	return visible


func close() -> void:
	if visible:
		visible = false
		closed.emit()


func _refresh() -> void:
	_wallet.text = "Sonium: %d" % RoundManager.sonium
	for c in _list.get_children():
		c.queue_free()
	var items: Dictionary = GameData.items(_category)
	var key: String = LOADOUT_KEY[_category]
	for id in items:
		var info: Dictionary = items[id]
		var row := HBoxContainer.new()
		var l := Label.new()
		l.text = "%s  -  %s" % [info["name"], info["desc"]]
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		var btn := Button.new()
		var owned: bool = RoundManager.owned[_category].has(id)
		if owned:
			if RoundManager.loadout[key] == id:
				btn.text = "Equipped"
				btn.disabled = true
			else:
				btn.text = "Equip"
				btn.pressed.connect(_equip.bind(key, id))
		else:
			btn.text = "Buy %d" % int(info["price"])
			btn.disabled = RoundManager.sonium < int(info["price"])
			btn.pressed.connect(_buy.bind(id))
		row.add_child(btn)
		_list.add_child(row)


func _buy(id: String) -> void:
	if RoundManager.buy(_category, id):
		_refresh()


func _equip(key: String, id: String) -> void:
	RoundManager.set_loadout(key, id)
	_refresh()
