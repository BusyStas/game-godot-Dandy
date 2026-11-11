class_name GameData
extends RefCounted
## Static game content. Anything marked PLACEHOLDER was not specified in the design deck.

# PLACEHOLDER: the deck says there are two starting characters (designs TBD) and a character shop.
const STARTERS := ["recruit", "scout"]

const CHARACTERS := {
	"recruit": {"name": "Recruit", "price": 60, "desc": "Balanced all-rounder.", "speed": 1.0, "fix": 1.0, "quiet": 1.0},
	"scout": {"name": "Scout", "price": 60, "desc": "Runs 15% faster.", "speed": 1.15, "fix": 1.0, "quiet": 1.0},
	"engineer": {"name": "Engineer", "price": 100, "desc": "Fixes machines 30% faster.", "speed": 1.0, "fix": 1.3, "quiet": 1.0},
	"ghost": {"name": "Ghost", "price": 250, "desc": "Makes half the noise.", "speed": 1.0, "fix": 1.0, "quiet": 0.5},
}

const SKINS := {
	"default": {"name": "Default", "price": 0, "desc": "Plain.", "color": Color(0.8, 0.8, 0.8)},
	"ocean": {"name": "Ocean", "price": 50, "desc": "Blue.", "color": Color(0.2, 0.45, 0.9)},
	"forest": {"name": "Forest", "price": 50, "desc": "Green.", "color": Color(0.2, 0.7, 0.35)},
	"gold": {"name": "Gold", "price": 200, "desc": "Shiny.", "color": Color(0.95, 0.8, 0.2)},
}

const DECORATIONS := {
	"none": {"name": "None", "price": 0, "desc": "Empty player card."},
	"star": {"name": "Star", "price": 30, "desc": "A star on your card."},
	"crown": {"name": "Crown", "price": 80, "desc": "A crown on your card."},
	"flame": {"name": "Flame", "price": 120, "desc": "A flame on your card."},
}

# PLACEHOLDER: the deck says utilities are "talked about later". These are all free.
const UTILITIES := {
	"none": {"name": "None", "desc": "No utility."},
	"boots": {"name": "Sprint Boots", "desc": "+20% move speed."},
	"lantern": {"name": "Lantern", "desc": "A light that follows you."},
	"earplugs": {"name": "Earplugs", "desc": "Corruptions hear you 40% less."},
}

# Per-map look and task. task: machines | containers | spotted.
const MAP_THEMES := {
	"Library": {"floor": Color(0.35, 0.25, 0.18), "prop": Color(0.45, 0.3, 0.15), "style": "rows"},
	"Laboratory": {"floor": Color(0.75, 0.8, 0.85), "prop": Color(0.9, 0.9, 0.95), "style": "tables"},
	"Train Station": {"floor": Color(0.3, 0.3, 0.33), "prop": Color(0.5, 0.5, 0.55), "style": "pillars", "w": 52.0},
	"Kitchen": {"floor": Color(0.8, 0.8, 0.75), "prop": Color(0.6, 0.6, 0.65), "style": "tables"},
	"Warehouse": {"floor": Color(0.2, 0.2, 0.22), "prop": Color(0.5, 0.35, 0.2), "style": "rows", "task": "containers", "w": 50.0, "d": 34.0},
	"Aquarium": {"floor": Color(0.1, 0.3, 0.5), "prop": Color(0.2, 0.6, 0.8), "style": "pool", "task": "spotted"},
	"Diner": {"floor": Color(0.6, 0.15, 0.15), "prop": Color(0.85, 0.85, 0.8), "style": "tables"},
	"Museum": {"floor": Color(0.6, 0.55, 0.45), "prop": Color(0.75, 0.7, 0.6), "style": "pillars", "task": "containers"},
	"Art Gallery": {"floor": Color(0.85, 0.85, 0.85), "prop": Color(0.9, 0.8, 0.5), "style": "scatter", "task": "containers"},
	"Rainbow Room": {"floor": Color(0.5, 0.2, 0.6), "prop": Color(0.9, 0.5, 0.2), "style": "scatter", "task": "spotted"},
	"School": {"floor": Color(0.65, 0.6, 0.35), "prop": Color(0.5, 0.35, 0.2), "style": "rows"},
	"Factory": {"floor": Color(0.22, 0.22, 0.25), "prop": Color(0.55, 0.4, 0.1), "style": "rows", "w": 50.0, "d": 34.0},
	"Gardens": {"floor": Color(0.2, 0.5, 0.2), "prop": Color(0.1, 0.35, 0.1), "style": "scatter"},
	"Playhouse": {"floor": Color(0.85, 0.5, 0.65), "prop": Color(0.3, 0.6, 0.9), "style": "scatter", "task": "spotted"},
	"Gift Shop": {"floor": Color(0.7, 0.4, 0.2), "prop": Color(0.8, 0.7, 0.3), "style": "rows", "task": "containers"},
	"CH1 Floor": {"floor": Color(0.15, 0.1, 0.1), "prop": Color(0.4, 0.1, 0.1), "style": "scatter"},
	"CH2 Floor": {"floor": Color(0.1, 0.12, 0.18), "prop": Color(0.2, 0.3, 0.5), "style": "pillars"},
	"CH3 Floor": {"floor": Color(0.12, 0.16, 0.12), "prop": Color(0.2, 0.45, 0.25), "style": "tables"},
	"CH4 Floor": {"floor": Color(0.18, 0.12, 0.2), "prop": Color(0.5, 0.2, 0.5), "style": "rows"},
	"CL1 Floor": {"floor": Color(0.25, 0.2, 0.1), "prop": Color(0.7, 0.55, 0.2), "style": "scatter", "task": "containers"},
	"CL2 Floor": {"floor": Color(0.2, 0.1, 0.25), "prop": Color(0.6, 0.3, 0.7), "style": "pool", "task": "spotted"},
	"CL3 Floor": {"floor": Color(0.1, 0.2, 0.25), "prop": Color(0.3, 0.6, 0.7), "style": "tables"},
	"LR1 Floor": {"floor": Color(0.1, 0.1, 0.12), "prop": Color(0.3, 0.3, 0.35), "style": "pillars"},
	"LR2 Floor": {"floor": Color(0.08, 0.08, 0.1), "prop": Color(0.25, 0.25, 0.3), "style": "rows"},
}

# PLACEHOLDER lore text for the two lore floors.
const LORE := {
	"LR1 Floor": "A torn page: 'Soria's work was meant to heal us. The Incident began on this floor.'",
	"LR2 Floor": "A scratched note: 'Serrani ran. Surrena looked for him. Nobody came back for Soria.'",
}


static func theme(map_name: String) -> Dictionary:
	var t := {
		"floor": Color(0.3, 0.3, 0.35), "wall": Color(0.55, 0.55, 0.6), "prop": Color(0.4, 0.3, 0.25),
		"style": "scatter", "task": "machines", "w": 40.0, "d": 30.0,
	}
	if MAP_THEMES.has(map_name):
		t.merge(MAP_THEMES[map_name], true)
	return t


static func items(category: String) -> Dictionary:
	match category:
		"characters":
			return CHARACTERS
		"skins":
			return SKINS
		"decorations":
			return DECORATIONS
	return {}
