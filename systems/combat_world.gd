class_name CombatWorld
extends Node3D

signal enemy_destroyed(at: Vector3, xp: int)
signal player_hit
signal impact(at: Vector3, amount: float, critical: bool)
signal notice(title: String, detail: String, color: Color)
signal weapon_fired(id: String)
signal cache_recovered
var effects: CombatEffects
var rig: WeaponRig
var encounters := EncounterDirector.new()
var adaptation := SwarmAdaptation.new()
var spawned_by_type: Dictionary = {}
var resisted_hits: int = 0
var loadout: Dictionary = {}
var mutations: Array[String] = []
var timers: Dictionary = {}
var streak: int = 0
var streak_time: float = 0.0
var overclock: float = 0.0
var effects_enabled: bool = true
var enemies: Array[SwarmEnemy] = []
var projectiles: Array[SwarmProjectile] = []
var hostile_projectiles: Array[SwarmProjectile] = []
var grid := SpatialGrid.new()
var rng := RandomNumberGenerator.new()
var director := SpawnDirector.new()
var weapon := WeaponController.new()
var kills: int = 0
var damage_by_weapon: Dictionary = {}
var tick_index: int = 0
var next_think_phase: Dictionary = {}
var target: Node3D
var active_enemies: int = 0
var active_projectiles: int = 0
const DEFINITIONS: Array[EnemyDefinition] = [preload("res://enemies/crawler.tres"), preload("res://enemies/striker.tres"), preload("res://enemies/sentry.tres"), preload("res://enemies/bulwark.tres"), preload("res://enemies/skimmer.tres"), preload("res://enemies/insulator.tres")]
const ENEMY_RESERVE: int = 240

func _ready() -> void:
	rng.randomize()
	adaptation.changed.connect(_adaptation_changed)
	effects = CombatEffects.new()
	add_child(effects)
	rig = WeaponRig.new()
	add_child(rig)
	# Large enough to accommodate the complete fixed initial pool reserve.
	# Pools grow if exhausted; no spawns are discarded to change difficulty.
	for i in range(ENEMY_RESERVE):
		_create_enemy(i % DEFINITIONS.size())
	for i in range(160):
		_create_projectile(false)
	for i in range(96):
		_create_projectile(true)

func _create_enemy(kind: int) -> SwarmEnemy:
	var enemy := SwarmEnemy.new()
	enemy.index = enemies.size()
	enemy.think_phase = int(next_think_phase.get(kind, kind)) % 6
	next_think_phase[kind] = (enemy.think_phase + 1) % 6
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
	var id: String = str(DEFINITIONS[kind].id)
	spawned_by_type[id] = int(spawned_by_type.get(id, 0)) + 1
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
	streak_time -= delta
	if streak_time <= 0.0:
		streak = 0
	overclock = maxf(0.0, overclock - delta)
	effects.tick(delta)
	encounters.tick(delta, self, player)
	adaptation.tick(delta, player.position, damage_by_weapon, encounters.allows_adaptation(director.elapsed))
	var spawn_count := director.tick(delta)
	for i in range(spawn_count):
		var angle := rng.randf() * TAU
		var point := player.position + Vector3(cos(angle), 0, sin(angle)) * 30.0
		point.x = clampf(point.x, -48.0, 48.0)
		point.z = clampf(point.z, -48.0, 48.0)
		if point.distance_to(player.position) < 18.0:
			point = player.position - Vector3(cos(angle), 0, sin(angle)) * 25.0
		spawn(director.archetype(rng, adaptation.preferred_kind(), adaptation.bias()), point)
	active_enemies = 0
	for enemy in enemies:
		if not enemy.active:
			continue
		active_enemies += 1
		enemy.effects_enabled = effects_enabled
		if enemy.think_phase == tick_index % 6:
			enemy.think(player.position)
		var shot_direction := enemy.tick(delta)
		if shot_direction != Vector3.ZERO:
			fire(enemy.position, shot_direction, true, enemy.definition.damage)
		if enemy.position.distance_squared_to(player.position) < pow(enemy.definition.radius + 0.45, 2):
			if player.health.take_damage(enemy.definition.damage):
				player_hit.emit()
			if player.health.current <= 0.0:
				return false
	grid.rebuild(enemies)
	target = grid.nearest(player.position, weapon.definition.range_m)
	var fired := weapon.ready_to_fire(delta * (1.6 if overclock > 0.0 else 1.0), target != null)
	if fired:
		fire(player.position, target.position - player.position)
		effects.emit_fx("spark", player.position, player.position, Color("c1ffe7"), 0.45)
	if target != null:
		player.aim(target.position)
	_tick_arsenal(delta, player)
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
			_damage(enemy, amount, shot.velocity.normalized() * 0.2, critical)
			if mutations.has("arcstorm"):
				chain(enemy.position, weapon.damage * 0.5, 2, 6.0, [enemy.index], "arcstorm")
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

func update_build(ranks: Dictionary) -> void:
	loadout = ranks
	for id in Arsenal.mutation(ranks):
		if not mutations.has(id):
			mutations.append(id)
			notice.emit("WEAPON MUTATION", "ARCSTORM RIFLE // ROUNDS NOW CHAIN" if id == "arcstorm" else "SOLAR HALO // ORBITALS RADIATE HEAT", Color("ffe39b"))
			weapon_fired.emit("mutation")

func _damage(enemy: SwarmEnemy, amount: float, knockback: Vector3 = Vector3.ZERO, critical: bool = false, weapon_id: String = "pulse") -> void:
	if not enemy.active:
		return
	if weapon_id in ["arc", "arcstorm"] and enemy.definition.electric_resistance > 0.0:
		amount *= 1.0 - clampf(enemy.definition.electric_resistance, 0.0, 0.8)
		resisted_hits += 1
	amount = maxf(0.0, amount) * (1.25 if enemy.exposed_time > 0.0 else 1.0)
	damage_by_weapon[weapon_id] = float(damage_by_weapon.get(weapon_id, 0.0)) + minf(maxf(0.0, enemy.hp), amount)
	impact.emit(enemy.position, amount, critical)
	effects.emit_fx("spark", enemy.position, enemy.position, enemy.definition.color.lightened(0.3), 0.45 if critical else 0.22)
	if not enemy.hit(amount, knockback if enemy.definition.radius < 1.3 else Vector3.ZERO):
		return
	var at := enemy.position
	enemy.deactivate()
	kills += 1
	streak += 1
	streak_time = 3.0
	if streak % 20 == 0:
		overclock = 6.0
		notice.emit("OVERCLOCK // %d CHAIN" % streak, "FIRE RATE +60% FOR 6 SECONDS", Color("b9f66b"))
		weapon_fired.emit("overclock")
	enemy_destroyed.emit(at, enemy.definition.xp)
	effects.destruction(at, enemy.definition.color, enemy.definition.radius > 1.3)
	if enemy.definition.id in [&"warden", &"architect"]:
		notice.emit("CORE RECOVERED", "MEMORY VACUUM // REPAIR // BONUS UPGRADE", Color("ffe39b"))
		cache_recovered.emit()
		weapon_fired.emit("mutation")

func area(at: Vector3, radius: float, damage: float, push: float = 0.0, weapon_id: String = "thermal") -> void:
	for enemy in grid.query(at, radius + 3.0):
		if enemy.position.distance_to(at) <= radius + enemy.definition.radius:
			_damage(enemy, damage, (enemy.position - at).normalized() * push, false, weapon_id)

func chain(at: Vector3, damage: float, jumps: int, reach: float, ignore: Array = [], weapon_id: String = "arc") -> void:
	var used: Array = ignore.duplicate()
	var previous := at
	for i in range(jumps):
		var closest: SwarmEnemy
		var local_reach: float = reach if i == 0 else minf(reach, 7.0)
		var distance: float = local_reach * local_reach
		for enemy in grid.query(previous, local_reach):
			if used.has(enemy.index):
				continue
			var squared: float = enemy.position.distance_squared_to(previous)
			if squared < distance:
				closest = enemy
				distance = squared
		if closest == null:
			break
		var point := closest.position
		used.append(closest.index)
		effects.emit_fx("beam", previous, point, Arsenal.color("arc"), 0.10)
		_damage(closest, damage, Vector3.ZERO, false, weapon_id)
		previous = point

func _tick_arsenal(delta: float, player: SwarmPlayer) -> void:
	rig.tick(delta, player.position, loadout, mutations.has("halo"))
	for id in Arsenal.DATA:
		var rank: int = int(loadout.get(id, 0))
		if rank <= 0:
			continue
		timers[id] = maxf(0.0, float(timers.get(id, 0.0)) - delta * (1.6 if overclock > 0.0 else 1.0))
		if float(timers[id]) > 0.0:
			continue
		var definition: Dictionary = Arsenal.DATA[id]
		var damage: float = definition["damage"] * (1.0 + (rank - 1) * 0.28)
		var ready: bool = target != null
		match id:
			"orbit":
				for point in rig.orbital_points:
					area(point, 0.8, damage, 0.0, "orbit")
				if mutations.has("halo"):
					area(player.position, 4.2, damage * 0.35, 0.0, "halo")
					effects.emit_fx("ring", player.position, player.position, Color("ffe39b"), 4.2)
			"arc":
				if ready:
					chain(player.position, damage, 3 + rank / 2, 17.0)
			"rail":
				if ready:
					var start := player.position
					var end: Vector3 = start + (target.position - start).normalized() * 26.0
					effects.emit_fx("beam", start, end, Arsenal.color("rail"), 0.22)
					for enemy in grid.query(start, 29.0):
						var closest := Geometry3D.get_closest_point_to_segment(enemy.position, start, end)
						if enemy.position.distance_to(closest) < enemy.definition.radius + 0.45:
							_damage(enemy, damage, Vector3.ZERO, false, "rail")
			"thermal":
				ready = not grid.query(player.position, 6.0).is_empty()
				if ready:
					area(player.position, 5.0 + rank * 0.2, damage, 1.3)
					effects.emit_fx("ring", player.position, player.position, Arsenal.color("thermal"), 5.0 + rank * 0.2)
			"drone":
				for point in rig.drone_points:
					var victim := grid.nearest(point, 19.0)
					if victim != null:
						effects.emit_fx("beam", point, victim.position, Arsenal.color("drone"), 0.07)
						_damage(victim, damage, Vector3.ZERO, false, "drone")
		if ready:
			timers[id] = float(definition["cooldown"]) * pow(0.94, rank - 1)
			weapon_fired.emit(id)

func _adaptation_changed(event: String, style: String) -> void:
	if event == "warning":
		var response: Dictionary = SwarmAdaptation.RESPONSES[style]
		notice.emit("SWARM ADAPTING // 8s WARNING", response["reason"] + " // " + response["counter"], Color("ffcf85"))
		weapon_fired.emit("mutation")
