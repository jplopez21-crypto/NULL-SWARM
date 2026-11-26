extends RefCounted

# Fixed synthetic trace for accepted-source movement/health/aim/animation parity.
# No RNG, wall clock, renderer, enemy grants or measured-FPS claims.
static func run(parent: Node) -> Dictionary:
	var player := SwarmPlayer.new()
	parent.add_child(player)
	var frames: Array = []
	var accepted: int = 0
	var hits: int = 0
	var moves: Array[Vector2] = [Vector2.RIGHT, Vector2(1, 1).normalized(), Vector2.DOWN, Vector2.ZERO,
		Vector2.LEFT, Vector2(-1, -1).normalized(), Vector2.UP, Vector2.ZERO]
	for i in range(2400):
		if i % 480 == 0:
			player.health.current = player.health.maximum
			player.health.shield = player.health.max_shield
		if i % 181 == 0:
			if player.health.take_damage(12.0):
				hits += 1
		if i == 1200:
			player.position = Vector3(46.7, 0, 46.7)
		if i == 1440:
			player.position = Vector3.ZERO
		player.walk_multiplier = 0.88 if i >= 1600 else 1.0
		player.flash_feedback = i < 1800
		player.recoil = 1.0 if i % 31 == 0 else player.recoil
		var movement: Vector2 = moves[(i / 135) % moves.size()]
		if player.tick(1.0 / 60.0, movement, i % 97 == 0 or i % 301 == 1):
			accepted += 1
		player.aim(player.position + Vector3(cos(i * 0.01), 0, sin(i * 0.01)))
		var row: Array = [player.position.x, player.position.z, player.direction.x, player.direction.z,
			player.dash_cooldown, player.dash_time, player.health.current, player.health.shield,
			player.health.invulnerable, player.health.recharge_delay, player.stride, player.recoil,
			player.body.position.y, player.body.rotation.y, player.body.rotation.z, player.gun.position.z,
			player.legs[0].position.z, player.legs[1].position.z, player.hit_feedback_time,
			float(player.hit_ring.visible), float(player.body.visible)]
		for j in range(row.size()):
			row[j] = snappedf(row[j], 0.000001)
		frames.append(row)
	var result := {"frames": frames.size(), "fixed_step": 1.0 / 60.0, "accepted_dashes": accepted,
		"accepted_damage_events": hits, "fingerprint": JSON.stringify(frames).sha256_text()}
	parent.remove_child(player)
	player.free()
	return result
