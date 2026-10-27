class_name SwarmAdaptation
extends RefCounted

signal changed(event: String, style: String)
const FIRST_ANALYSIS: float = 120.0
const ANALYSIS_PERIOD: float = 60.0
const WINDOW: float = 45.0
const WARNING: float = 8.0
const ACTIVE_DURATION: float = 45.0
const BIAS: float = 0.20
const RESPONSES: Dictionary = {
 "bulwarks": {"kind": 3, "title": "ARMORED FORMATION", "reason": "DIRECT FIRE DOMINATES", "counter": "MORE BULWARKS // PIERCE AND AREA DAMAGE HELP"},
 "insulators": {"kind": 5, "title": "INSULATOR FORMATION", "reason": "ELECTRICAL DAMAGE DOMINATES", "counter": "AMBER CORES RESIST ARC 20% // OTHER WEAPONS WORK NORMALLY"},
 "siege": {"kind": 2, "title": "SIEGE FORMATION", "reason": "PROLONGED STATIONARY FIRE", "counter": "MORE VIOLET SENTRIES // KEEP MOVING"},
 "skimmers": {"kind": 4, "title": "EVASIVE FORMATION", "reason": "CLOSE-RANGE DAMAGE DOMINATES", "counter": "MORE SKIMMERS // USE RANGED COVERAGE"}
}
var enabled: bool = true
var elapsed: float = 0.0
var next_analysis: float = FIRST_ANALYSIS
var pending: String = ""
var starts_at: float = 0.0
var active: String = ""
var expires_at: float = 0.0
var history: Array[Dictionary] = []
var samples: Array[Dictionary] = []
var previous_damage: Dictionary = {}
var previous_position: Vector3
var has_position: bool = false
var sample_elapsed: float = 0.0
var sample_stationary: float = 0.0

func tick(delta: float, position: Vector3, damage: Dictionary, allow_new: bool = true) -> void:
	if not enabled:
		return
	elapsed += maxf(0.0, delta)
	if has_position and position.distance_to(previous_position) < delta * 0.35:
		sample_stationary += delta
	previous_position = position
	has_position = true
	sample_elapsed += delta
	if sample_elapsed >= 0.5:
		var entry := {"at": elapsed, "seconds": sample_elapsed, "stationary": sample_stationary, "total": 0.0, "direct": 0.0, "electric": 0.0, "close": 0.0}
		for id in damage:
			var amount: float = maxf(0.0, float(damage[id]) - float(previous_damage.get(id, 0.0)))
			entry["total"] += amount
			if id in ["pulse", "rail", "drone"]:
				entry["direct"] += amount
			elif id in ["arc", "arcstorm"]:
				entry["electric"] += amount
			elif id in ["orbit", "thermal", "halo"]:
				entry["close"] += amount
		previous_damage = damage.duplicate()
		samples.append(entry)
		while not samples.is_empty() and float(samples[0]["at"]) <= elapsed - WINDOW:
			samples.pop_front()
		sample_elapsed = 0.0
		sample_stationary = 0.0
	if not active.is_empty() and elapsed >= expires_at:
		history.append({"event": "expired", "style": active, "at": snappedf(elapsed, 0.01)})
		var old := active
		active = ""
		changed.emit("expired", old)
	if not pending.is_empty() and elapsed >= starts_at:
		active = pending
		pending = ""
		expires_at = elapsed + ACTIVE_DURATION
		history.append({"event": "active", "style": active, "at": snappedf(elapsed, 0.01), "expires_at": snappedf(expires_at, 0.01)})
		changed.emit("active", active)
	if elapsed >= next_analysis:
		next_analysis = (floorf(elapsed / ANALYSIS_PERIOD) + 1.0) * ANALYSIS_PERIOD
		if allow_new and pending.is_empty() and active.is_empty():
			var metrics := recent_metrics()
			var style := classify(metrics)
			history.append({"event": "analysis", "style": style, "at": snappedf(elapsed, 0.01), "metrics": metrics})
			if not style.is_empty():
				pending = style
				starts_at = elapsed + WARNING
				history.append({"event": "warning", "style": style, "at": snappedf(elapsed, 0.01), "starts_at": snappedf(starts_at, 0.01)})
				changed.emit("warning", style)

func recent_metrics() -> Dictionary:
	var totals := {"seconds": 0.0, "stationary": 0.0, "total": 0.0, "direct": 0.0, "electric": 0.0, "close": 0.0}
	for entry in samples:
		for key in totals:
			totals[key] += float(entry[key])
	return {"sample_seconds": totals["seconds"], "total_damage": totals["total"],
		"stationary_share": totals["stationary"] / maxf(0.01, totals["seconds"]),
		"direct_share": totals["direct"] / maxf(1.0, totals["total"]),
		"electric_share": totals["electric"] / maxf(1.0, totals["total"]),
		"close_share": totals["close"] / maxf(1.0, totals["total"])}

static func classify(metrics: Dictionary) -> String:
	if float(metrics.get("sample_seconds", 0.0)) < 20.0 or float(metrics.get("total_damage", 0.0)) < 400.0:
		return ""
	if float(metrics.get("stationary_share", 0.0)) >= 0.70:
		return "siege"
	if float(metrics.get("electric_share", 0.0)) >= 0.50:
		return "insulators"
	if float(metrics.get("close_share", 0.0)) >= 0.45:
		return "skimmers"
	if float(metrics.get("direct_share", 0.0)) >= 0.65:
		return "bulwarks"
	return ""

func preferred_kind() -> int:
	return int(RESPONSES[active]["kind"]) if enabled and not active.is_empty() else -1

func bias() -> float:
	return BIAS if preferred_kind() >= 0 else 0.0

func status() -> String:
	if not enabled:
		return "SWARM // ADAPTATION DISABLED IN THIS QA FIXTURE"
	if not pending.is_empty():
		return "SWARM // %s IN %ds // %s" % [RESPONSES[pending]["title"], ceili(maxf(0.0, starts_at - elapsed)), RESPONSES[pending]["counter"]]
	if not active.is_empty():
		return "SWARM // %s %ds // %s" % [RESPONSES[active]["title"], ceili(maxf(0.0, expires_at - elapsed)), RESPONSES[active]["counter"]]
	return "SWARM // OBSERVING YOUR COMBAT SIGNATURE"
