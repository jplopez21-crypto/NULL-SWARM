class_name ValueAwareBot
extends PlaytestBot

# Test-only alternate collector. It changes navigation, never game stats or rules.
var target_mesh: MeshInstance3D
var last_upgrade_time: float = 0.0

func tick(game: Node3D, delta: float) -> void:
	var decision_due: bool = reaction <= delta
	var choosing: bool = game.state == game.State.UPGRADING
	super.tick(game, delta)
	if choosing:
		last_upgrade_time = game.combat.director.elapsed
		return
	if game.state != game.State.PLAYING or not decision_due or game.input_router.dash_requested:
		return
	var point: Vector3 = game.player.position
	var best_value: float = -INF
	var target: Dictionary = {}
	for item in game.pickups.items:
		if item["attract"]:
			continue
		var at: Vector3 = item["mesh"].position
		at.y = 0.0
		var distance: float = point.distance_to(at)
		if distance > 16.0:
			continue
		# Reward tiers correspond to visible blue/mint/gold packet tiers, not exact XP.
		var value: float = (4.0 if item["xp"] >= 100 else (2.0 if item["xp"] >= 25 else 1.0)) / (distance + 2.0)
		if item["mesh"] == target_mesh:
			value *= 1.35
		if value > best_value:
			best_value = value
			target = item
	if target.is_empty():
		return
	target_mesh = target["mesh"]
	var goal: Vector3 = target_mesh.position
	goal.y = 0.0
	var nearby: Array = game.combat.grid.query(point, 16.0)
	var may_dash: bool = game.player.dash_cooldown <= 0.0 and point.distance_to(goal) > 5.0 and (target["xp"] >= 25 or game.combat.director.elapsed - last_upgrade_time > 30.0)
	var best: float = -INF
	var chosen := movement
	var chosen_dash: bool = false
	for mode in [false, true]:
		if mode and not may_dash:
			continue
		for i in range(16):
			var angle: float = TAU * i / 16
			var candidate := Vector2(cos(angle), sin(angle))
			var direction := Vector3(candidate.x, 0, candidate.y)
			var distance: float = 27.0 * 0.18 + game.player.speed * 0.37 if mode else game.player.speed * 0.55
			var future: Vector3 = point + direction * distance
			var score: float = (point.distance_to(goal) - future.distance_to(goal)) * 2.0 + candidate.dot(movement) * 0.4
			if mode:
				score -= 2.0
			if absf(future.x) > 45 or absf(future.z) > 45:
				score -= 60.0
			for enemy in nearby:
				var enemy_future: Vector3 = enemy.position + enemy.velocity * 0.35
				var clearance: float = future.distance_to(enemy_future) - enemy.definition.radius - 0.55
				if clearance < 0.0:
					score -= 75.0
				elif clearance < 3.0:
					score -= 5.0 / (clearance + 0.5)
				else:
					score -= 0.25 / (clearance + 1.0)
				if not mode:
					var closest := Geometry3D.get_closest_point_to_segment(enemy.position, point, future)
					if closest.distance_to(enemy.position) < enemy.definition.radius + 0.55:
						score -= 60.0
			for shot in game.combat.hostile_projectiles:
				if shot.active and shot.position.distance_squared_to(point) < 64.0 and future.distance_to(shot.position + shot.velocity * 0.35) < 1.1:
					score -= 45.0
			if game.combat.encounters.warning_time > 0 and not game.combat.encounters.attacking_radial:
				for location in game.combat.encounters.locations:
					if future.distance_to(location) < 3.8:
						score -= 80.0
			if score > best:
				best = score
				chosen = candidate
				chosen_dash = mode
	movement = chosen
	game.input_router.stick = movement
	if chosen_dash:
		game.input_router.dash_requested = true
		dashes += 1
