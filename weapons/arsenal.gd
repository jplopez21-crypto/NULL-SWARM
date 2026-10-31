class_name Arsenal
extends RefCounted

# One content registry drives upgrade offers, behavior parameters and HUD labels.
const DATA: Dictionary = {
 "orbit": {"title": "PLASMA ORBITALS", "role": "DEFENSE", "color": Color("ffb35c"), "damage": 13.0, "cooldown": 0.45, "description": "Rotating plasma guards\nstrike enemies near you."},
 "arc": {"title": "ARC EMITTER", "role": "CHAIN", "color": Color("b4a1ff"), "damage": 19.0, "cooldown": 1.25, "description": "Lightning jumps between\nclustered targets."},
 "rail": {"title": "RAIL LANCE", "role": "PIERCE", "color": Color("9de9ff"), "damage": 65.0, "cooldown": 2.0, "description": "A piercing beam drills\nthrough the whole line."},
 "thermal": {"title": "THERMAL BURST", "role": "AREA", "color": Color("ff7652"), "damage": 40.0, "cooldown": 2.8, "description": "A close-range blast\npushes the swarm back."},
 "drone": {"title": "DRONE HIVE", "role": "SUPPORT", "color": Color("b9f66b"), "damage": 17.0, "cooldown": 0.8, "description": "Autonomous escorts fire\nfrom your flanks."}
}
const MUTATIONS: Dictionary = {
 "arcstorm": {"weapon": "pulse", "title": "ARCSTORM RIFLE", "requires": {"damage": 3, "arc": 3}, "effect": "ROUNDS NOW CHAIN"},
 "halo": {"weapon": "orbit", "title": "SOLAR HALO", "requires": {"orbit": 3, "thermal": 3}, "effect": "ORBITALS RADIATE HEAT"},
 "singularity": {"weapon": "rail", "title": "SINGULARITY LANCE", "requires": {"rail": 3, "magnet": 3}, "effect": "RAIL IMPACTS LEAVE GRAVITY FIELDS"}
}
const MAX_SLOTS: int = 4
const PASSIVE_TITLES: Dictionary = {"damage": "AMPLIFIED PULSE", "magnet": "MEMORY TETHER"}

static func mutation_progress(ranks: Dictionary, active: Array[String], slots_used: int) -> Array[Dictionary]:
	# Read-only presentation query. Multiple missing weapons must all fit the run.
	var result: Array[Dictionary] = []
	for id in MUTATIONS:
		var definition: Dictionary = MUTATIONS[id]
		var requirements: Array[String] = []
		var missing_weapons: int = 0
		var ready: bool = true
		for prerequisite in definition["requires"]:
			var rank: int = int(ranks.get(prerequisite, 0))
			var needed: int = int(definition["requires"][prerequisite])
			var name: String = PASSIVE_TITLES.get(prerequisite, title(prerequisite))
			requirements.append("%s %d/%d" % [name, rank, needed])
			ready = ready and rank >= needed
			if DATA.has(prerequisite) and rank <= 0:
				missing_weapons += 1
		var free_slots: int = maxi(0, MAX_SLOTS - slots_used)
		var status := "IN PROGRESS"
		if active.has(id):
			status = "ACTIVE"
		elif missing_weapons > free_slots:
			status = "SLOTS BLOCKED"
		elif ready:
			status = "REQUIREMENTS MET"
		result.append({"id": id, "title": definition["title"], "effect": definition["effect"],
			"requirements": " + ".join(requirements), "status": status,
			"missing_weapons": missing_weapons, "free_slots": free_slots})
	return result

static func color(id: String) -> Color:
	return Color("8eb5ff") if id == "singularity" else DATA.get(id, {}).get("color", Color("78f8d4"))

static func title(id: String) -> String:
	return MUTATIONS[id]["title"] if MUTATIONS.has(id) else DATA.get(id, {}).get("title", "PULSE RIFLE")

static func mutation(ranks: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for id in MUTATIONS:
		var ready: bool = true
		for prerequisite in MUTATIONS[id]["requires"]:
			ready = ready and int(ranks.get(prerequisite, 0)) >= int(MUTATIONS[id]["requires"][prerequisite])
		if ready:
			result.append(id)
	return result

static func equipped_title(weapon: String, active: Array[String]) -> String:
	for id in MUTATIONS:
		if active.has(id) and MUTATIONS[id]["weapon"] == weapon:
			return MUTATIONS[id]["title"]
	return title(weapon)
