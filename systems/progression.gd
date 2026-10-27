class_name RunProgression
extends RefCounted

var level: int = 1
var xp: int = 0
var pending: int = 0
var ranks: Dictionary = {}
const IDS: Array[String] = ["damage", "rate", "pierce", "speed", "health", "shield", "magnet"]
const CAPS: Dictionary = {"damage": 7, "rate": 7, "pierce": 3, "speed": 5, "health": 5, "shield": 5, "magnet": 5}

func threshold() -> int:
	return 18 + (level - 1) * 12

func add_xp(amount: int) -> void:
	xp += maxi(0, amount)
	while xp >= threshold():
		xp -= threshold()
		level += 1
		pending += 1

func choices(rng: RandomNumberGenerator) -> Array[String]:
	var available: Array[String] = []
	for id in IDS:
		if int(ranks.get(id, 0)) < int(CAPS[id]):
			available.append(id)
	var result: Array[String] = []
	while result.size() < 3 and not available.is_empty():
		var index: int = rng.randi_range(0, available.size() - 1)
		result.append(available.pop_at(index))
	if result.is_empty():
		result.append("repair")
	return result

func select(id: String, offered: Array[String]) -> bool:
	if pending <= 0 or not offered.has(id):
		return false
	if id != "repair" and (not CAPS.has(id) or int(ranks.get(id, 0)) >= int(CAPS[id])):
		return false
	ranks[id] = int(ranks.get(id, 0)) + 1
	pending -= 1
	return true
