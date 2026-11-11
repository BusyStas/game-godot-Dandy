class_name MapPicker
extends RefCounted
## Weighted random floor selection from the design deck's map table.
## "min_floor" is the earliest floor the map can appear; "weight" is the
## percentage odds at or after floor 30 (before floor 30 odds differ - TBD).

const MAPS := [
	{"name": "Library", "min_floor": 0, "weight": 8.0},
	{"name": "Laboratory", "min_floor": 0, "weight": 4.0},
	{"name": "Train Station", "min_floor": 0, "weight": 6.0},
	{"name": "Kitchen", "min_floor": 0, "weight": 10.0},
	{"name": "Warehouse", "min_floor": 5, "weight": 5.0},
	{"name": "Aquarium", "min_floor": 0, "weight": 2.0},
	{"name": "Diner", "min_floor": 0, "weight": 5.0},
	{"name": "Museum", "min_floor": 0, "weight": 3.0},
	{"name": "Art Gallery", "min_floor": 0, "weight": 5.0},
	{"name": "Rainbow Room", "min_floor": 5, "weight": 10.0},
	{"name": "School", "min_floor": 0, "weight": 7.0},
	{"name": "Factory", "min_floor": 10, "weight": 4.0},
	{"name": "Gardens", "min_floor": 5, "weight": 5.0},
	{"name": "Playhouse", "min_floor": 0, "weight": 4.0},
	{"name": "Gift Shop", "min_floor": 0, "weight": 2.0},
	{"name": "CH1 Floor", "min_floor": 15, "weight": 3.0},
	{"name": "CH2 Floor", "min_floor": 15, "weight": 4.0},
	{"name": "CH3 Floor", "min_floor": 15, "weight": 4.0},
	{"name": "CH4 Floor", "min_floor": 15, "weight": 6.0},
	{"name": "CL1 Floor", "min_floor": 20, "weight": 0.5},
	{"name": "CL2 Floor", "min_floor": 20, "weight": 0.75},
	{"name": "CL3 Floor", "min_floor": 20, "weight": 0.75},
	{"name": "LR1 Floor", "min_floor": 25, "weight": 0.5},
	{"name": "LR2 Floor", "min_floor": 30, "weight": 0.5},
]


static func pick(floor_number: int, rng: RandomNumberGenerator = null) -> String:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var eligible: Array = MAPS.filter(func(m): return floor_number >= m["min_floor"])
	var total := 0.0
	for m in eligible:
		total += m["weight"]
	var roll := rng.randf() * total
	for m in eligible:
		roll -= m["weight"]
		if roll <= 0.0:
			return m["name"]
	return eligible[-1]["name"]
