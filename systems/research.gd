class_name Research
extends RefCounted

const UPGRADES: Dictionary = {
 "chassis": {"title": "REINFORCED CHASSIS", "description": "+5 maximum health per rank", "costs": [8, 16, 24]},
 "tether": {"title": "MEMORY TETHER", "description": "+0.25m pickup attraction per rank", "costs": [8, 16, 24]},
 "logistics": {"title": "FIELD LOGISTICS", "description": "+1 upgrade reroll per deployment", "costs": [12]}
}
const KITS: Dictionary = {
 "vanguard": {"title": "VANGUARD", "description": "Balanced rifle. 100 HP. 1/4 slots.", "damage": 18.0, "cooldown": 0.42, "health": 100.0, "speed": 7.0, "weapon": ""},
 "conductor": {"title": "CONDUCTOR", "description": "Arc Emitter + weak rifle. 85 HP. 2/4 slots.", "damage": 9.0, "cooldown": 0.65, "health": 85.0, "speed": 7.0, "weapon": "arc"},
 "sentinel": {"title": "SENTINEL", "description": "Orbitals + slow rifle. 110 HP. Speed 6.5. 2/4 slots.", "damage": 12.0, "cooldown": 0.65, "health": 110.0, "speed": 6.5, "weapon": "orbit"},
 "engineer": {"title": "ENGINEER", "description": "Drone Hive + weak rifle. 80 HP. 2/4 slots.\nDash leaves one sentry for 3s. Cannot stack.", "damage": 9.0, "cooldown": 0.65, "health": 80.0, "speed": 7.0, "weapon": "drone"}
}

static func unlocked(data: Dictionary) -> Array[String]:
	var result: Array[String] = ["vanguard"]
	if int(data.get("salvaged_kills", 0)) >= 150:
		result.append("conductor")
	if int(data.get("wardens", 0)) >= 1:
		result.append("sentinel")
	if int(data.get("architects", 0)) >= 1:
		result.append("engineer")
	return result

static func cost(data: Dictionary, id: String) -> int:
	if not UPGRADES.has(id):
		return -1
	var rank: int = int(data.get("research", {}).get(id, 0))
	var costs: Array = UPGRADES[id]["costs"]
	return int(costs[rank]) if rank >= 0 and rank < costs.size() else -1

static func salvage(time: float, kills: int, warden: bool, architect: bool, won: bool) -> int:
	# Defeat and withdrawal retain earned salvage. No reward for an empty restart.
	return int(clampf(time, 0, 900) / 45) + maxi(0, kills) / 20 + (8 if warden else 0) + (20 if architect else 0) + (15 if won else 0)

static func apply(data: Dictionary, player: SwarmPlayer, combat: CombatWorld, progress: RunProgression) -> void:
	var id: String = data.get("selected_kit", "vanguard")
	if not unlocked(data).has(id):
		id = "vanguard"
	var kit: Dictionary = KITS[id]
	player.health.maximum = float(kit["health"]) + int(data.get("research", {}).get("chassis", 0)) * 5.0
	player.health.current = player.health.maximum
	player.speed = kit["speed"]
	player.magnet = 2.6 + int(data.get("research", {}).get("tether", 0)) * 0.25
	combat.weapon.damage = kit["damage"]
	combat.weapon.interval = kit["cooldown"]
	combat.sentry.configure(id == "engineer")
	progress.rerolls = 2 + int(data.get("research", {}).get("logistics", 0))
	if kit["weapon"] != "":
		progress.ranks[kit["weapon"]] = 1
	combat.update_build(progress.ranks)
