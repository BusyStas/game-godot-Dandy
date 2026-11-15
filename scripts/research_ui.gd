extends CanvasLayer
## Corruption research (deck: "Corruption Research"). Each Corruption has four tasks; finish them,
## then Claim the reward. Press R in the lobby.

signal closed

var _list: VBoxContainer
var _wallet: Label
var _titleline: Label


func _ready() -> void:
	layer = 10
	visible = false
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 6)
	panel.add_child(outer)
	var head := Label.new()
	head.text = "Corruption Research"
	head.add_theme_font_size_override("font_size", 30)
	outer.add_child(head)
	_titleline = Label.new()
	outer.add_child(_titleline)
	_wallet = Label.new()
	outer.add_child(_wallet)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(900, 460)
	outer.add_child(scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 14)
	scroll.add_child(_list)
	var close_btn := Button.new()
	close_btn.text = "Close (R)"
	close_btn.pressed.connect(close)
	outer.add_child(close_btn)
	RoundManager.research_changed.connect(func(): if visible: _refresh())
	RoundManager.sonium_changed.connect(func(_t): if visible: _refresh())


func open() -> void:
	_refresh()
	visible = true


func is_open() -> bool:
	return visible


func close() -> void:
	if visible:
		visible = false
		closed.emit()


func _refresh() -> void:
	_wallet.text = "Sonium: %d   (1 jar = %d Sonium)" % [RoundManager.sonium, GameData.JAR_SONIUM]
	var t := RoundManager.title()
	_titleline.text = "Title: %s" % (t if t != "" else "none yet")
	for c in _list.get_children():
		c.queue_free()
	for kind in GameData.RESEARCH:
		var info: Dictionary = GameData.RESEARCH[kind]
		var cor: Dictionary = GameData.CORRUPTIONS[kind]
		var box := VBoxContainer.new()
		var name := Label.new()
		name.text = "Corrupted %s  (%s)" % [cor["name"], str(cor["cls"]).capitalize()]
		name.add_theme_font_size_override("font_size", 22)
		box.add_child(name)
		var tasks: Array = info["tasks"]
		for i in tasks.size():
			var p: float = RoundManager.research[kind]["p"][i]
			var goal: float = tasks[i]["goal"]
			var l := Label.new()
			l.text = "  Task %d: %s - %d/%d" % [i + 1, tasks[i]["text"], int(p), int(goal)]
			if p >= goal:
				l.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
			box.add_child(l)
		var row := HBoxContainer.new()
		var r := Label.new()
		var cost: int = int(info["cost_jars"])
		r.text = "  Reward: %s%s" % [info["reward_text"], ("  (costs %d jars)" % cost) if cost > 0 else ""]
		r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(r)
		var btn := Button.new()
		if RoundManager.research[kind]["claimed"]:
			btn.text = "Claimed"
			btn.disabled = true
		else:
			btn.text = "Claim"
			btn.disabled = not RoundManager.can_claim(kind)
			btn.pressed.connect(func(): RoundManager.claim_research(kind))
		row.add_child(btn)
		box.add_child(row)
		_list.add_child(box)
