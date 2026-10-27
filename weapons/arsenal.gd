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
const MAX_SLOTS: int = 4

static func color(id: String) -> Color:
	return DATA.get(id, {}).get("color", Color("78f8d4"))

static func title(id: String) -> String:
	return {"arcstorm": "ARCSTORM", "halo": "SOLAR HALO"}.get(id, DATA.get(id, {}).get("title", "PULSE RIFLE"))

static func mutation(ranks: Dictionary) -> Array[String]:
	var result: Array[String] = []
	if int(ranks.get("damage", 0)) >= 3 and int(ranks.get("arc", 0)) >= 3:
		result.append("arcstorm")
	if int(ranks.get("orbit", 0)) >= 3 and int(ranks.get("thermal", 0)) >= 3:
		result.append("halo")
	return result
