extends ValueAwareBot

# Explicit experimental policy. Only normal stick input changes; inherited danger
# dashes/upgrade preferences and both reference policies remain untouched.
var recent: Array[Vector3] = []
var waypoint := Vector3.ZERO
var detour_remaining: float = 0.0
var detours_started: int = 0
var detours_cancelled: int = 0

static func looping(points: Array[Vector3]) -> bool:
	if points.size() < 16 or points.front().distance_to(points.back()) >= 1.5:
		return false
	var distance: float = 0.0
	for i in range(1, points.size()):
		distance += points[i - 1].distance_to(points[i])
	return distance >= 8.0

func _clear(game: Node3D, point: Vector3, future: Vector3) -> bool:
	if absf(future.x) > 45.0 or absf(future.z) > 45.0:
		return false
	for enemy in game.combat.grid.query(point, 16.0):
		var predicted: Vector3 = enemy.position + enemy.velocity * enemy.movement_multiplier * 0.35
		var closest := Geometry3D.get_closest_point_to_segment(predicted, point, future)
		if closest.distance_to(predicted) < enemy.definition.radius + 0.8:
			return false
	for shot in game.combat.hostile_projectiles:
		if shot.active and shot.position.distance_squared_to(point) < 64.0:
			var predicted: Vector3 = shot.position + shot.velocity * 0.35
			if Geometry3D.get_closest_point_to_segment(predicted, point, future).distance_to(predicted) < 1.1:
				return false
	if game.combat.encounters.warning_time > 0.0 and not game.combat.encounters.attacking_radial:
		for location in game.combat.encounters.locations:
			if Geometry3D.get_closest_point_to_segment(location, point, future).distance_to(location) < 3.8:
				return false
	return true

func tick(game: Node3D, delta: float) -> void:
	var decision_due: bool = reaction <= delta
	var choosing: bool = game.state == game.State.UPGRADING
	super.tick(game, delta)
	if choosing:
		recent.clear()
		detour_remaining = 0.0
		return
	if game.state != game.State.PLAYING:
		return
	detour_remaining = maxf(0.0, detour_remaining - delta)
	if not decision_due:
		return
	var point: Vector3 = game.player.position
	recent.append(point)
	if recent.size() > 16:
		recent.pop_front()
	# Preserve the inherited response and direction for every danger dash.
	if game.input_router.dash_requested:
		detour_remaining = 0.0
		recent.clear()
		return
	if detour_remaining <= 0.0 and looping(recent) and is_instance_valid(target_mesh):
		var toward: Vector3 = target_mesh.position - point
		toward.y = 0.0
		if toward.length_squared() > 0.01:
			var best: float = -INF
			for turn in [PI / 2.0, -PI / 2.0, PI / 4.0, -PI / 4.0, PI * 0.75, -PI * 0.75]:
				var direction := toward.normalized().rotated(Vector3.UP, turn)
				var candidate: Vector3 = point + direction * 5.0
				if not _clear(game, point, candidate):
					continue
				var score: float = -absf(turn) + direction.dot(Vector3(movement.x, 0, movement.y)) * 0.25
				if score > best:
					best = score
					waypoint = candidate
			if best > -INF:
				detour_remaining = 1.2
				detours_started += 1
				recent.clear()
	if detour_remaining <= 0.0:
		return
	var offset: Vector3 = waypoint - point
	offset.y = 0.0
	if offset.length() < 0.6:
		detour_remaining = 0.0
		return
	var future: Vector3 = point + offset.normalized() * minf(offset.length(), game.player.effective_speed() * 0.4)
	if not _clear(game, point, future):
		detour_remaining = 0.0
		detours_cancelled += 1
		return
	movement = Vector2(offset.x, offset.z).normalized()
	game.input_router.stick = movement
