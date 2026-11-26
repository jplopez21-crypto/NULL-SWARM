class_name PlaytestBot
extends RefCounted

const PROFILES: Dictionary = {
 "halo": ["orbit", "thermal", "rail"],
 "arcstorm": ["arc", "drone", "rail"],
 "kinetic": ["rail", "drone", "orbit"],
 "electric": ["arc", "orbit", "thermal"],
 "singularity": ["rail", "drone", "arc"],
 "engineer": ["drone", "rail", "arc"]
}
var profile: String = "halo"
var reaction: float = 0.0
var movement := Vector2.RIGHT
var dashes: int = 0
var choices: Array[Dictionary] = []
var first_new_weapon: float = -1.0
var damage_events: int = 0
var last_health: float = 0.0
var minimum_health: float = INF
var heading: float = 0.0

func tick(game: Node3D, delta: float) -> void:
	minimum_health = minf(minimum_health, game.player.health.current)
	var total_health: float = game.player.health.current + game.player.health.shield
	if last_health > total_health + 0.01:
		damage_events += 1
	last_health = total_health
	if game.state == game.State.UPGRADING:
		_choose(game)
		return
	if game.state != game.State.PLAYING:
		return
	reaction -= delta
	if reaction > 0:
		return
	reaction = 0.12
	var point: Vector3 = game.player.position
	var nearby: Array = game.combat.grid.query(point, 16.0)
	var pickup_goal: Vector3 = Vector3.ZERO
	var closest: float = 16.0 * 16.0
	for item in game.pickups.items:
		var at: Vector3 = item["mesh"].position
		at.y = 0.0
		var distance: float = point.distance_squared_to(at)
		if distance < closest:
			closest = distance
			pickup_goal = at - point
	# Without memory nearby, slowly circle the central region instead of camping an edge.
	var goal := pickup_goal.normalized() if pickup_goal.length() > 0.5 else Vector3(-point.z, 0, point.x).normalized()
	if goal.length() < 0.1:
		goal = Vector3.RIGHT
	goal += -point.normalized() * maxf(0.0, (point.length() - 25.0) / 10.0)
	var danger: bool = false
	var best: float = -INF
	var chosen := movement
	for i in range(16):
		var angle: float = TAU * i / 16.0
		var candidate := Vector2(cos(angle), sin(angle))
		var direction := Vector3(candidate.x, 0, candidate.y)
		var predicted: Vector3 = point + direction * game.player.effective_speed() * 0.55
		var score: float = direction.dot(goal.normalized()) * 3.0
		score += candidate.dot(movement) * 0.25
		if absf(predicted.x) > 44 or absf(predicted.z) > 44:
			score -= 30.0
		for enemy in nearby:
			var enemy_next: Vector3 = enemy.position + enemy.velocity * enemy.movement_multiplier * 0.35
			var clearance: float = predicted.distance_to(enemy_next) - enemy.definition.radius - 0.55
			if clearance < 0:
				score -= 45.0 + absf(clearance) * 8.0
			else:
				score -= 3.0 / (clearance + 0.4)
			if point.distance_to(enemy.position) < enemy.definition.radius + 1.6:
				danger = true
		for shot in game.combat.hostile_projectiles:
			if not shot.active or shot.position.distance_squared_to(point) > 64.0:
				continue
			var future: Vector3 = shot.position + shot.velocity * 0.35
			var distance: float = predicted.distance_to(future)
			if distance < 1.1:
				score -= 35.0
			if point.distance_to(future) < 1.8:
				danger = true
		var encounter: EncounterDirector = game.combat.encounters
		if encounter.warning_time > 0.0 and not encounter.attacking_radial:
			for location in encounter.locations:
				if point.distance_to(location) < 3.7:
					danger = true
				if predicted.distance_to(location) < 3.8:
					score -= 65.0
		if score > best:
			best = score
			chosen = candidate
	movement = chosen
	game.input_router.stick = movement
	if danger and game.player.dash_cooldown <= 0.0:
		game.input_router.dash_requested = true
		dashes += 1

func _score(id: String, game: Node3D) -> float:
	var rank: int = int(game.progress.ranks.get(id, 0))
	var priorities: Array = PROFILES[profile]
	if id == "health" and game.player.health.current < game.player.health.maximum * 0.5:
		return 250.0
	if profile == "singularity" and id in ["rail", "magnet"] and rank < 3:
		return 150.0 - rank * 3.0
	if profile == "electric" and id == "arc":
		return 160.0 - rank * 3.0
	if profile == "halo" and id in ["orbit", "thermal"] and rank < 3:
		return 150.0 - rank * 3.0
	if profile == "arcstorm" and id in ["damage", "arc"] and rank < 3:
		return 150.0 - rank * 3.0
	if priorities.has(id):
		return 120.0 - priorities.find(id) * 8.0 - rank * 4.0
	if Arsenal.DATA.has(id):
		return 0.0
	return {"damage": 90, "rate": 85, "pierce": 65, "magnet": 60, "speed": 50, "shield": 45, "health": 40, "repair": 25}.get(id, 0)

func _choose(game: Node3D) -> void:
	var selected: String = game.offered[0]
	var score: float = -INF
	for id in game.offered:
		var value := _score(id, game)
		if value > score:
			score = value
			selected = id
	if score < 60 and game.progress.rerolls > 0:
		game.reroll_upgrades()
		choices.append({"at": snappedf(game.combat.director.elapsed, 0.01), "id": "reroll"})
		return
	var is_new: bool = Arsenal.DATA.has(selected) and not game.progress.ranks.has(selected)
	game.select_upgrade(selected)
	if is_new and first_new_weapon < 0:
		first_new_weapon = game.combat.director.elapsed
	choices.append({"at": snappedf(game.combat.director.elapsed, 0.01), "id": selected})
