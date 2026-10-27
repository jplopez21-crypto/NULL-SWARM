class_name CombatWorld
extends Node3D

signal enemy_destroyed(at: Vector3, xp: int)
signal player_hit
signal impact(at: Vector3, amount: float, critical: bool)
var enemies: Array[SwarmEnemy] = []
var projectiles: Array[SwarmProjectile] = []
var hostile_projectiles: Array[SwarmProjectile] = []
var grid := SpatialGrid.new()
var rng := RandomNumberGenerator.new()
var director := SpawnDirector.new()
var weapon := WeaponController.new()
var kills: int = 0
var tick_index: int = 0
var target: Node3D
var active_enemies: int = 0
var active_projectiles: int = 0
const DEFINITIONS: Array[EnemyDefinition] = [preload("res://enemies/crawler.tres"), preload("res://enemies/striker.tres"), preload("res://enemies/sentry.tres")]
const ENEMY_RESERVE: int = 384

func _ready() -> void:
	rng.seed = 7312026
	# Large enough to accommodate the complete fixed five-minute spawn schedule.
	# Pools grow if exhausted; no spawns are discarded to change difficulty.
	for i in range(ENEMY_RESERVE):
		_create_enemy(i % 3)
	for i in range(160):
		_create_projectile(false)
	for i in range(96):
		_create_projectile(true)

func _create_enemy(kind: int) -> SwarmEnemy:
	var enemy := SwarmEnemy.new()
	enemy.index = enemies.size()
	add_child(enemy)
	enemy.configure(DEFINITIONS[kind])
	enemies.append(enemy)
	return enemy

func _create_projectile(hostile: bool) -> SwarmProjectile:
	var shot := SwarmProjectile.new()
	add_child(shot)
	shot.configure(hostile)
	if hostile:
		hostile_projectiles.append(shot)
	else:
		projectiles.append(shot)
	return shot

func spawn(kind: int, point: Vector3) -> SwarmEnemy:
	for enemy in enemies:
		if not enemy.active and enemy.definition == DEFINITIONS[kind]:
			enemy.activate(point, 1.0 + director.elapsed / 280.0)
			return enemy
	var enemy := _create_enemy(kind)
	enemy.activate(point, 1.0 + director.elapsed / 280.0)
	return enemy

func fire(at: Vector3, direction: Vector3, hostile: bool = false, amount: float = -1.0) -> void:
	var pool: Array[SwarmProjectile] = hostile_projectiles if hostile else projectiles
	var shot: SwarmProjectile
	for candidate in pool:
		if not candidate.active:
			shot = candidate
			break
	if shot == null:
		shot = _create_projectile(hostile)
	shot.activate(at, direction, 10.0 if hostile else weapon.definition.projectile_speed, amount if amount >= 0.0 else weapon.damage, 30.0 if hostile else weapon.definition.range_m, 0 if hostile else weapon.piercing)

func tick(delta: float, player: SwarmPlayer) -> bool:
	tick_index += 1
	var spawn_count := director.tick(delta)
	for i in range(spawn_count):
		var angle := rng.randf() * TAU
		var point := player.position + Vector3(cos(angle), 0, sin(angle)) * 30.0
		point.x = clampf(point.x, -48.0, 48.0)
		point.z = clampf(point.z, -48.0, 48.0)
		if point.distance_to(player.position) < 18.0:
			point = player.position - Vector3(cos(angle), 0, sin(angle)) * 25.0
		spawn(director.archetype(rng), point)
	active_enemies = 0
	for enemy in enemies:
		if not enemy.active:
			continue
		active_enemies += 1
		if enemy.index % 6 == tick_index % 6:
			enemy.think(player.position)
		var shot_direction := enemy.tick(delta)
		if shot_direction != Vector3.ZERO:
			fire(enemy.position, shot_direction, true, enemy.definition.damage)
		if enemy.position.distance_squared_to(player.position) < pow(enemy.definition.radius + 0.45, 2):
			if player.health.take_damage(enemy.definition.damage):
				player_hit.emit()
	grid.rebuild(enemies)
	target = grid.nearest(player.position, weapon.definition.range_m)
	var fired := weapon.ready_to_fire(delta, target != null)
	if fired:
		fire(player.position, target.position - player.position)
	if target != null:
		player.aim(target.position)
	active_projectiles = 0
	for shot in projectiles:
		if not shot.active:
			continue
		active_projectiles += 1
		shot.tick(delta)
		if not shot.active:
			continue
		var midpoint := (shot.previous + shot.position) * 0.5
		for enemy in grid.query(midpoint, 2.0):
			if shot.struck.has(enemy.index):
				continue
			var closest := Geometry3D.get_closest_point_to_segment(enemy.position, shot.previous, shot.position)
			if enemy.position.distance_squared_to(closest) > pow(enemy.definition.radius + 0.2, 2):
				continue
			shot.struck.append(enemy.index)
			var critical := rng.randf() < 0.08
			var amount := shot.damage * (1.8 if critical else 1.0)
			impact.emit(enemy.position, amount, critical)
			if enemy.hit(amount, shot.velocity.normalized() * 0.2):
				enemy_destroyed.emit(enemy.position, enemy.definition.xp)
				enemy.deactivate()
				kills += 1
			if shot.piercing <= 0:
				shot.deactivate()
				break
			shot.piercing -= 1
	for shot in hostile_projectiles:
		if not shot.active:
			continue
		active_projectiles += 1
		shot.tick(delta)
		var closest := Geometry3D.get_closest_point_to_segment(player.position, shot.previous, shot.position)
		if shot.active and player.position.distance_squared_to(closest) < 0.65:
			if player.health.take_damage(shot.damage):
				player_hit.emit()
			shot.deactivate()
	return fired
