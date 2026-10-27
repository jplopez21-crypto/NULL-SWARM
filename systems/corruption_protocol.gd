class_name CorruptionProtocol
extends RefCounted

const MAX_LINKS: int = 3
const HEALTH_COST: float = 20.0
const FIRST_LEVEL: int = 5
const LEVEL_SPACING: int = 5
const IDS: Array[String] = ["redline", "fracture", "hive"]
const TITLES: Dictionary = {"redline": "REDLINE SYNC", "fracture": "FRACTURED CHAMBER", "hive": "PARASITIC HIVE"}
var accepted: Array[String] = []
var next_level: int = FIRST_LEVEL

func available(level: int) -> bool:
	return level >= next_level and accepted.size() < MAX_LINKS

func eligible(id: String, level: int, ranks: Dictionary) -> bool:
	return available(level) and IDS.has(id) and not accepted.has(id) and (id != "hive" or int(ranks.get("drone", 0)) > 0)

func select(id: String, level: int, ranks: Dictionary) -> bool:
	if not eligible(id, level, ranks):
		return false
	accepted.append(id)
	next_level = level + LEVEL_SPACING
	return true

func cycle_rate() -> float:
	return 1.3 if accepted.has("redline") else 1.0

func extra_rounds() -> int:
	return 1 if accepted.has("fracture") else 0

func enemy_pace() -> float:
	return 1.15 if accepted.has("fracture") else 1.0

func extra_drones() -> int:
	return 1 if accepted.has("hive") else 0

func walk_rate() -> float:
	return 0.88 if accepted.has("hive") else 1.0

func status() -> String:
	if accepted.is_empty():
		return "CORRUPTION 0/3 // CLEAN SIGNAL"
	var names: Array[String] = []
	for id in accepted:
		names.append(TITLES[id])
	return "CORRUPTION %d/3 // " % accepted.size() + " + ".join(names)

func description(id: String, player: SwarmPlayer, combat: CombatWorld, ranks: Dictionary) -> String:
	var title: String = TITLES.get(id, "UNKNOWN LINK")
	if accepted.has(id):
		return title + "\nALREADY LINKED\nActive until this run ends."
	match id:
		"redline":
			return title + "\n\nGAIN: Weapon cycles +30%%\nRifle %.2fs -> %.2fs\n\nCOST: Maximum HP %d -> %d\nCurrent HP capped, no healing." % [combat.weapon.interval, combat.weapon.interval / 1.3, int(player.health.maximum), int(player.health.maximum - HEALTH_COST)]
		"fracture":
			return title + "\n\nGAIN: Rifle rounds 1 -> 2\nExtra round can also chain.\n\nCOST: Regular enemy pace\n100% -> 115% (incl. charges)\nBosses and warning times unchanged."
		"hive":
			if int(ranks.get("drone", 0)) <= 0:
				return title + "\n\nREQUIRES DRONE HIVE\n\nGAIN: One additional escort\nCOST: Walking speed -12%\nDash speed stays unchanged."
			var drones: int = 1 + int(ranks["drone"]) / 2
			return title + "\n\nGAIN: Escorts %d -> %d\n\nCOST: Walk speed %.2f -> %.2f\nDash speed stays unchanged." % [drones, drones + 1, player.speed, player.speed * 0.88]
	return title
