class_name GameData
extends RefCounted
## Static game content. Anything marked PLACEHOLDER was not specified in the design deck.

# PLACEHOLDER: the deck says there are two starting characters (designs TBD) and a character shop.
const STARTERS := ["recruit", "scout"]

const CHARACTERS := {
	# deck: bought characters cost about 500 (worst) to 4000 (best) Sonium; stars run 1 (worst) to 5 (best).
	# Sonia, Serrani and Surrena are admin-only and never sold. The roster here is a PLACEHOLDER until Daniel lists the real ones.
	"recruit": {"name": "Recruit", "price": 500, "desc": "Balanced all-rounder.", "speed": 1.0, "fix": 1.0, "quiet": 1.0, "stars": {"Speed": 2, "Fixing": 2, "Stealth": 2}},
	"scout": {"name": "Scout", "price": 500, "desc": "Runs 15% faster.", "speed": 1.15, "fix": 1.0, "quiet": 1.0, "stars": {"Speed": 3, "Fixing": 1, "Stealth": 2}},
	"engineer": {"name": "Engineer", "price": 1500, "desc": "Fixes machines 30% faster.", "speed": 1.0, "fix": 1.3, "quiet": 1.0, "stars": {"Speed": 2, "Fixing": 4, "Stealth": 2}},
	"ghost": {"name": "Ghost", "price": 4000, "desc": "Makes half the noise.", "speed": 1.0, "fix": 1.0, "quiet": 0.5, "stars": {"Speed": 3, "Fixing": 2, "Stealth": 5}},
}

## "Balanced all-rounder.  Speed ★★☆☆☆  Fixing ..." for the shop and the selection screen.
static func desc_with_stars(info: Dictionary) -> String:
	var text: String = str(info.get("desc", ""))
	if info.has("stars"):
		for k in info["stars"]:
			var n: int = int(info["stars"][k])
			text += "   %s %s%s" % [k, "★".repeat(n), "☆".repeat(5 - n)]
	return text

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

# --- Corruptions (deck: "Corruption Basics" and "Corruption Spawning") ----------------------
# cls: fatal (instant kill) | stalk (2 damage) | friendler (1 damage). speed/sight/hearing are in
# m/s and metres. min_floor and weight come from the deck's spawn table ("odds at or after floor 20";
# the deck gives no earlier odds, so these are used at every floor). The deck's other table rows are
# "WIP", so only Dreina (a Friendler, floor 0) fills the always-available slot for now.
const CORRUPTIONS := {
	"sonia": {"name": "Sonia", "cls": "fatal", "speed": 3.2, "sight": 14.0, "hearing": 8.0, "detect_time": 10.0, "damage": 999, "min_floor": 20, "weight": 1.0},
	"serrani": {"name": "Serrani", "cls": "fatal", "speed": 1.8, "sight": 12.0, "hearing": 25.0, "detect_time": 6.0, "damage": 999, "min_floor": 20, "weight": 1.0},
	"surrena": {"name": "Surrena", "cls": "fatal", "speed": 3.0, "sight": 7.0, "hearing": 6.0, "detect_time": 5.0, "damage": 999, "min_floor": 20, "weight": 1.0},
	"rencha": {"name": "Rencha", "cls": "stalk", "speed": 3.8, "sight": 14.0, "hearing": 10.0, "detect_time": 20.0, "damage": 2, "min_floor": 10, "weight": 1.5},
	"cybot": {"name": "Cybot 1.2.7", "cls": "stalk", "speed": 3.0, "sight": 12.0, "hearing": 14.0, "detect_time": 12.0, "damage": 2, "min_floor": 10, "weight": 1.5},
	"ivina": {"name": "Ivina", "cls": "stalk", "speed": 2.5, "sight": 10.0, "hearing": 8.0, "detect_time": 0.0, "damage": 2, "min_floor": 10, "weight": 1.5},
	"bolten": {"name": "Bolten", "cls": "stalk", "speed": 8.0, "sight": 16.0, "hearing": 12.0, "detect_time": 10.0, "damage": 2, "min_floor": 10, "weight": 1.5},
	"dreina": {"name": "Dreina", "cls": "friendler", "speed": 3.5, "sight": 12.0, "hearing": 10.0, "detect_time": 10.0, "damage": 1, "min_floor": 5, "weight": 2.5},
	"shovelina": {"name": "Shovelina", "cls": "friendler", "speed": 2.8, "sight": 10.0, "hearing": 12.0, "detect_time": 6.0, "damage": 1, "min_floor": 5, "weight": 2.5},
	"limlem": {"name": "Lim & Lem", "cls": "friendler", "speed": 6.0, "sight": 12.0, "hearing": 6.0, "detect_time": 0.0, "damage": 1, "min_floor": 5, "weight": 2.5},
	"littay": {"name": "Littay", "cls": "friendler", "speed": 3.0, "sight": 12.0, "hearing": 10.0, "detect_time": 10.0, "damage": 1, "min_floor": 10, "weight": 2.5},
	"minchei": {"name": "Minchei", "cls": "friendler", "speed": 2.6, "sight": 4.0, "hearing": 14.0, "detect_time": 12.0, "damage": 1, "min_floor": 5, "weight": 2.5},
}

# The deck's table still has unfinished ("WIP") rows. They keep their share of the odds; until they exist, a WIP
# roll spawns one of the finished Friendlers (any floor) as a stand-in. [min_floor, rarity]
static func wip_rows() -> Array:
	var rows: Array = [[5, 2.5], [5, 2.5]]
	for i in 8:
		rows.append([0, 3.5])
	for i in 10:
		rows.append([0, 4.55])
	return rows

const WIP_STAND_INS := ["dreina", "shovelina", "limlem", "minchei", "littay"]

# Short alarm text shown by the monster warning.
const WARNINGS := {
	"sonia": "SONIA is hunting you - RUN!",
	"serrani": "SERRANI is close - stop sprinting, stay quiet!",
	"surrena": "SURRENA burst out of the wall - RUN!",
	"rencha": "RENCHA has seen you - you are slowed and chased!",
	"cybot": "CYBOT 1.2.7 is nearby - he breaks machines!",
	"ivina": "IVINA is above you - watch the ceiling!",
	"bolten": "BOLTEN is coming fast - RUN!",
	"dreina": "DREINA is chasing you - avoid the Sonium puddles!",
	"shovelina": "SHOVELINA is digging toward you - keep moving!",
	"limlem": "LIM & LEM - do not get close to them!",
	"littay": "LITTAY is roaming - he drags people to the darkest part of the map!",
	"minchei": "MINCHEI is roaming - she can drag you to a Fatal!",
}

# --- Research (deck: "Corruption Research"). 4 tasks per Corruption; the first two are the same for
# all of them, tasks 3 and 4 are specific. Tasks 3 for everyone but Sonia and Rencha are PLACEHOLDERS.
# ev = the event name tracked in RoundManager.research_event; goal = how many (or seconds).
const RESEARCH := {
	"sonia": {"tasks": [
		{"ev": "found", "goal": 10, "text": "Find Corrupted Sonia ten times"},
		{"ev": "follow", "goal": 30, "text": "Follow Corrupted Sonia for half a minute (within 5 m)"},
		{"ev": "chosen", "goal": 1, "text": "Get chosen over another person in a chase"},
		{"ev": "chased", "goal": 60, "text": "Get chased by Corrupted Sonia for a whole minute"}],
		"cost_jars": 0, "reward": "title", "reward_text": "Title: Sonia Scholar + a guide on dodging Sonia"},
	"serrani": {"tasks": [
		{"ev": "found", "goal": 10, "text": "Find Corrupted Serrani ten times"},
		{"ev": "follow", "goal": 30, "text": "Follow Corrupted Serrani for half a minute (within 5 m)"},
		{"ev": "heard", "goal": 5, "text": "Get heard by Serrani five times"},
		{"ev": "chased", "goal": 30, "text": "Get chased by Corrupted Serrani for half a minute"}],
		"cost_jars": 0, "reward": "title", "reward_text": "Title: Noise Whisperer + a guide on staying quiet"},
	"surrena": {"tasks": [
		{"ev": "found", "goal": 10, "text": "Find Corrupted Surrena ten times"},
		{"ev": "follow", "goal": 30, "text": "Follow Corrupted Surrena for half a minute (within 5 m)"},
		{"ev": "shake_free", "goal": 3, "text": "Shake free of Surrena's grasp three times"},
		{"ev": "chased", "goal": 30, "text": "Get chased by Corrupted Surrena for half a minute"}],
		"cost_jars": 0, "reward": "title", "reward_text": "Title: Wall Walker + a guide to ichor puddles"},
	"rencha": {"tasks": [
		{"ev": "found", "goal": 10, "text": "Get spotted by Corrupted Rencha ten times"},
		{"ev": "follow", "goal": 30, "text": "Follow Corrupted Rencha for half a minute (within 5 m)"},
		{"ev": "chased_slowed", "goal": 30, "text": "Stay in a chase for half a minute while slowed"},
		{"ev": "chased", "goal": 30, "text": "Get chased by Corrupted Rencha for around half a minute"}],
		"cost_jars": 5, "reward": "immune_slow", "reward_text": "Immunity to Rencha's slowness"},
	"cybot": {"tasks": [
		{"ev": "found", "goal": 10, "text": "Find Corrupted Cybot ten times"},
		{"ev": "follow", "goal": 30, "text": "Follow Corrupted Cybot for half a minute (within 5 m)"},
		{"ev": "saw_break", "goal": 3, "text": "Watch Cybot break a machine three times"},
		{"ev": "chased", "goal": 30, "text": "Get chased by Corrupted Cybot for half a minute"}],
		"cost_jars": 0, "reward": "utility", "reward_text": "Utility: Machine Sealant (broken machines leak 50% slower)"},
	"ivina": {"tasks": [
		{"ev": "found", "goal": 10, "text": "Find Corrupted Ivina ten times"},
		{"ev": "follow", "goal": 30, "text": "Follow Corrupted Ivina for half a minute (within 5 m)"},
		{"ev": "thorns_ok", "goal": 3, "text": "Pass Ivina's thorn minigame three times"},
		{"ev": "chased", "goal": 30, "text": "Get chased by Corrupted Ivina for half a minute"}],
		"cost_jars": 10, "reward": "immune_poison", "reward_text": "Immunity to Ivina's poison"},
	"bolten": {"tasks": [
		{"ev": "found", "goal": 10, "text": "Find Corrupted Bolten ten times"},
		{"ev": "follow", "goal": 30, "text": "Follow Corrupted Bolten for half a minute (within 5 m)"},
		{"ev": "survive_chase", "goal": 3, "text": "Survive three Bolten chases (get away unhurt)"},
		{"ev": "chased", "goal": 30, "text": "Get chased by Corrupted Bolten for half a minute"}],
		"cost_jars": 0, "reward": "speed", "reward_text": "Perk: +8% move speed"},
	"shovelina": {"tasks": [
		{"ev": "found", "goal": 10, "text": "Find Corrupted Shovelina ten times"},
		{"ev": "follow", "goal": 30, "text": "Follow Corrupted Shovelina for half a minute (within 5 m)"},
		{"ev": "shake_free", "goal": 3, "text": "Shake free of Shovelina's grasp three times"},
		{"ev": "chased", "goal": 30, "text": "Get chased by Corrupted Shovelina for half a minute"}],
		"cost_jars": 0, "reward": "research_speed", "reward_text": "Research quests finish at triple the pace"},
	"limlem": {"tasks": [
		{"ev": "found", "goal": 10, "text": "Find Corrupted Lim & Lem ten times"},
		{"ev": "follow", "goal": 30, "text": "Follow Corrupted Lim & Lem for half a minute (within 5 m)"},
		{"ev": "space_escape", "goal": 3, "text": "Step into Lim & Lem's space and get away unhurt three times"},
		{"ev": "chased", "goal": 30, "text": "Get chased by Corrupted Lim & Lem for half a minute"}],
		"cost_jars": 0, "reward": "title", "reward_text": "Title: Personal Space + a guide on keeping your distance"},
	"littay": {"tasks": [
		{"ev": "found", "goal": 10, "text": "Find Corrupted Littay ten times"},
		{"ev": "follow", "goal": 30, "text": "Follow Corrupted Littay for half a minute (within 5 m)"},
		{"ev": "tank_escape", "goal": 2, "text": "Climb out of Littay's ichor tank twice"},
		{"ev": "chased", "goal": 30, "text": "Get chased by Corrupted Littay for half a minute"}],
		"cost_jars": 0, "reward": "title", "reward_text": "Title: Night Owl + a guide to the dark parts of the map"},
	"minchei": {"tasks": [
		{"ev": "found", "goal": 10, "text": "Find Corrupted Minchei ten times"},
		{"ev": "follow", "goal": 30, "text": "Follow Corrupted Minchei for half a minute (within 5 m)"},
		{"ev": "drag_escape", "goal": 3, "text": "Escape Minchei's grasp three times"},
		{"ev": "chased", "goal": 30, "text": "Get chased by Corrupted Minchei for half a minute"}],
		"cost_jars": 0, "reward": "title", "reward_text": "Title: Mitten Tamer + a guide on getting away from Minchei"},
	"dreina": {"tasks": [
		{"ev": "found", "goal": 10, "text": "Find Corrupted Dreina ten times"},
		{"ev": "follow", "goal": 30, "text": "Follow Corrupted Dreina for half a minute (within 5 m)"},
		{"ev": "chunked", "goal": 2, "text": "Get a Sonium chunk stuck on you twice"},
		{"ev": "chased", "goal": 30, "text": "Get chased by Corrupted Dreina for half a minute"}],
		"cost_jars": 0, "reward": "title", "reward_text": "Title: Puddle Jumper + a guide on Sonium puddles"},
}
const JAR_SONIUM := 10   # PLACEHOLDER: the deck says "jars of Sonium (explained later)"; one jar is 10 Sonium here.
const MASTER_TITLE := "Master Researcher"


## Weighted random Corruption kind for a floor, using the deck's spawn table and floor requirements.
static func pick_corruption(rng: RandomNumberGenerator, floor_number: int) -> String:
	var kinds: Array = []
	var weights: Array = []
	var total := 0.0
	# deck: higher floors make rarer Corruptions more likely and common ones rarer, until Fatals spawn almost always
	var boost := pow(1.07, maxf(0.0, float(floor_number) - 10.0))
	for k in CORRUPTIONS:
		if floor_number >= int(CORRUPTIONS[k]["min_floor"]):
			var w := float(CORRUPTIONS[k]["weight"])
			if CORRUPTIONS[k]["cls"] != "friendler":
				w *= boost
			if CORRUPTIONS[k]["cls"] == "fatal":
				w *= pow(1.12, maxf(0.0, float(floor_number) - 20.0))   # Fatals eventually spawn almost always
			kinds.append(k)
			weights.append(w)
			total += w
	for row in wip_rows():
		if floor_number >= int(row[0]):
			kinds.append("")   # unfinished row: stand-in below
			weights.append(float(row[1]))
			total += float(row[1])
	var roll := rng.randf() * total
	var chosen := ""
	for i in kinds.size():
		roll -= float(weights[i])
		if roll <= 0.0:
			chosen = kinds[i]
			break
	if chosen == "":
		var options: Array = []
		for k in WIP_STAND_INS:
			if floor_number >= int(CORRUPTIONS[k]["min_floor"]):
				options.append(k)
		if options.is_empty():
			options.append("dreina")
		chosen = options[rng.randi() % options.size()]
	return chosen


# PLACEHOLDER lore text for the two lore floors.
const LORE := {
	"LR1 Floor": "A torn page: 'Sonia's work was meant to heal us. The Incident began on this floor.'",
	"LR2 Floor": "A scratched note: 'Serrani ran. Surrena looked for him. Nobody came back for Sonia.'",
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
