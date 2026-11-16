class_name FloorChain
extends RefCounted
## A tiny hash chain that proves a run went through the floors one by one, in order.
## Every floor you reach adds a block whose hash covers the previous block's hash, the floor number, the map,
## the run id and the time. Floor N is only allowed to start if the chain holds exactly blocks 1..N-1 and every
## link verifies, so a run cannot jump ahead (for example straight to floor 1000).
## This runs on the client, so it stops accidents and casual edits; for real anti-cheat the same chain must be
## re-verified on the server once multiplayer exists (the blocks are what you would send).

const GENESIS_SALT := "sonias-expeditions-genesis-v1"
const SEAL_SALT := "sonias-expeditions-best-floor-seal-v1"


static func genesis(run_id: int) -> String:
	return ("%s|%d" % [GENESIS_SALT, run_id]).sha256_text()


static func block_hash(prev: String, floor_number: int, map_name: String, run_id: int, time_s: int) -> String:
	return ("%s|%d|%s|%d|%d" % [prev, floor_number, map_name, run_id, time_s]).sha256_text()


## Append the block for floor_number; returns false (and appends nothing) if the chain is not valid up to floor_number - 1.
static func append(chain: Array, floor_number: int, map_name: String, run_id: int) -> bool:
	if not is_valid_up_to(chain, floor_number - 1, run_id):
		return false
	var prev: String = genesis(run_id) if chain.is_empty() else str(chain[-1]["hash"])
	var t := int(Time.get_unix_time_from_system())
	chain.append({"floor": floor_number, "map": map_name, "time": t, "prev": prev, "hash": block_hash(prev, floor_number, map_name, run_id, t)})
	return true


## True when the chain holds exactly floors 1..count, in order, and every hash link checks out.
static func is_valid_up_to(chain: Array, count: int, run_id: int) -> bool:
	if chain.size() != count:
		return false
	var prev := genesis(run_id)
	for i in count:
		var b: Dictionary = chain[i]
		if int(b["floor"]) != i + 1 or str(b["prev"]) != prev:
			return false
		if str(b["hash"]) != block_hash(prev, i + 1, str(b["map"]), run_id, int(b["time"])):
			return false
		prev = str(b["hash"])
	return true


## Seal stored with the best floor in the save file, so editing best_floor by hand is noticed.
static func seal(best_floor: int, tip_hash: String) -> String:
	return ("%s|%d|%s" % [SEAL_SALT, best_floor, tip_hash]).sha256_text()
