class_name RunProgression
extends RefCounted

var level: int = 1
var xp: int = 0
var pending: int = 0
var ranks: Dictionary = {}
var rerolls: int = 2
const IDS: Array[String] = ["damage", "rate", "pierce", "speed", "health", "shield", "magnet", "orbit", "arc", "rail", "thermal", "drone"]
const CAPS: Dictionary = {"damage": 7, "rate": 7, "pierce": 3, "speed": 5, "health": 5, "shield": 5, "magnet": 5, "orbit": 5, "arc": 5, "rail": 5, "thermal": 5, "drone": 5}

func threshold() -> int:
	return 18 + (level - 1) * 10

func add_xp(amount: int) -> void:
	xp += maxi(0, amount)
	while xp >= threshold():
		xp -= threshold()
		level += 1
		pending += 1

func equipped() -> int:
	var count: int = 1
	for id in Arsenal.DATA:
		if int(ranks.get(id, 0)) > 0:
			count += 1
	return count

func eligible(id: String) -> bool:
	if not CAPS.has(id) or int(ranks.get(id, 0)) >= int(CAPS[id]):
		return false
	return not Arsenal.DATA.has(id) or ranks.has(id) or equipped() < Arsenal.MAX_SLOTS

func choices(rng: RandomNumberGenerator) -> Array[String]:
	var available: Array[String] = []
	var weapons: Array[String] = []
	for id in IDS:
		if eligible(id):
			available.append(id)
			if Arsenal.DATA.has(id):
				weapons.append(id)
	var result: Array[String] = []
	# Early cards guarantee a new toy, rather than three tiny stat adjustments.
	if not weapons.is_empty():
		var id: String = weapons[rng.randi_range(0, weapons.size() - 1)]
		result.append(id)
		available.erase(id)
	while result.size() < 3 and not available.is_empty():
		var index: int = rng.randi_range(0, available.size() - 1)
		result.append(available.pop_at(index))
	if result.is_empty():
		result.append("repair")
	return result

func select(id: String, offered: Array[String]) -> bool:
	if pending <= 0 or not offered.has(id) or (id != "repair" and not eligible(id)):
		return false
	ranks[id] = int(ranks.get(id, 0)) + 1
	pending -= 1
	return true
