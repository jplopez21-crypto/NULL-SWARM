class_name EncounterDirector
extends RefCounted

const MINI_BOSS_TIME: float = 180.0
const FINAL_BOSS_TIME: float = 540.0

var mini_spawned: bool = false
var boss_spawned: bool = false
var boss_defeated: bool = false
var warning_sent: bool = false
var final_warning_sent: bool = false
var boss: SwarmEnemy
var mini: SwarmEnemy
var attack_cooldown: float = 3.0
var warning_time: float = 0.0
var attack_index: int = 0
var phase: int = 1
var warnings: Array[MeshInstance3D] = []
var locations: Array[Vector3] = []
var attacking_radial: bool = true

func tick(delta: float, world: Node3D, player: SwarmPlayer) -> void:
	var time: float = world.director.elapsed
	if time >= MINI_BOSS_TIME - 5.0 and not warning_sent:
		warning_sent = true
		world.notice.emit("HEAVY SIGNAL INBOUND", "WARDEN ARRIVES AT 03:00", Color("ffb35c"))
	if time >= MINI_BOSS_TIME and not mini_spawned:
		mini_spawned = true
		mini = _spawn(world, player.position, false)
		world.notice.emit("THE WARDEN", "BREAK THE ARMOR. CLAIM ITS MEMORY.", Color("ffb35c"))
	if time >= FINAL_BOSS_TIME - 10.0 and not final_warning_sent:
		world.notice.emit("THE ARCHITECT IS COMING", "FINAL CONTACT AT 09:00", Color("ff7652"))
		final_warning_sent = true
	if time >= FINAL_BOSS_TIME and not boss_spawned:
		boss_spawned = true
		boss = _spawn(world, player.position, true)
		world.notice.emit("THE ARCHITECT", "DESTROY THE CORE TO EXTRACT", Color("ff7652"))
	if boss_spawned and boss != null and not boss.active:
		if not boss_defeated:
			boss_defeated = true
			_clear_warnings()
		return
	var source: SwarmEnemy = boss if boss != null and boss.active else mini
	if source == null or not source.active:
		_clear_warnings()
		return
	var next_phase: int = 1 + (1 if source.hp < source.max_hp * 0.66 else 0) + (1 if source.hp < source.max_hp * 0.33 else 0)
	if next_phase > phase:
		phase = next_phase
		_clear_warnings()
		attack_cooldown = 2.0
		source.exposed_time = 1.2
		source.velocity = Vector3.ZERO
		world.effects.emit_fx("ring", source.position, source.position, Color("ffe39b"), 4.5)
		world.weapon_fired.emit("mutation")
		world.notice.emit("CORE EXPOSED // PHASE %d" % phase, "+25% DAMAGE FOR 1.2s // ATTACK PATTERNS CHANGING", Color("ffe39b"))
	if warning_time > 0.0:
		warning_time -= delta
		for warning in warnings:
			warning.scale.y = 0.4 + sin(warning_time * 15.0) * 0.15
		if warning_time <= 0.0:
			if attacking_radial:
				var count: int = 10 + phase * 2
				for i in range(count):
					var angle: float = TAU * i / count + attack_index * 0.23
					world.fire(source.position + Vector3(cos(angle), 0, sin(angle)) * 2.0, Vector3(cos(angle), 0, sin(angle)), true, 15.0)
			else:
				for location in locations:
					world.effects.emit_fx("ring", location, location, Color("ff7652"), 3.3)
					if location.distance_squared_to(player.position) < 3.3 * 3.3:
						if player.health.take_damage(24.0):
							world.player_hit.emit()
				if phase == 3:
					for i in range(2):
						world.spawn(0, source.position + Vector3(i * 3 - 1.5, 0, 3))
			_clear_warnings()
			attack_cooldown = 3.8 - phase * 0.55
	else:
		attack_cooldown -= delta
		if attack_cooldown <= 0.0:
			attack_index += 1
			attacking_radial = phase == 1 or attack_index % 2 == 0
			warning_time = 1.15
			if attacking_radial:
				warnings.append(SwarmVisuals.ring(world, 3.2, source.position + Vector3(0, 0.08, 0), Color("ff9274"), 0.16))
			else:
				for i in range(3):
					var location := player.position + Vector3((i - 1) * 6.0, 0, 0)
					locations.append(location)
					warnings.append(SwarmVisuals.ring(world, 3.3, location + Vector3(0, 0.08, 0), Color("ff7652"), 0.18))

func _spawn(world: Node3D, player_at: Vector3, major: bool) -> SwarmEnemy:
	_clear_warnings()
	attack_cooldown = 3.0
	attack_index = 0
	var definition := EnemyDefinition.new()
	definition.id = &"architect" if major else &"warden"
	definition.title = "THE ARCHITECT" if major else "THE WARDEN"
	definition.health = 7000.0 if major else 1400.0
	definition.speed = 1.4 if major else 2.0
	definition.damage = 24.0
	definition.radius = 2.4 if major else 1.5
	definition.xp = 320 if major else 160
	definition.behavior = 3
	definition.color = Color("ff7652") if major else Color("ffb35c")
	var enemy := SwarmEnemy.new()
	enemy.index = world.enemies.size()
	world.add_child(enemy)
	enemy.configure(definition)
	world.enemies.append(enemy)
	enemy.activate(player_at + Vector3(0, 0, -18), 1.0)
	enemy.visual_scale = 3.2 if major else 2.1
	SwarmVisuals.ring(enemy.body, 1.3, Vector3(0, 0.8, 0), definition.color, 0.15)
	SwarmVisuals.box(enemy.body, Vector3(0.28, 2.0, 0.28), Vector3(-1.0, 1.6, 0), definition.color, true)
	SwarmVisuals.box(enemy.body, Vector3(0.28, 2.0, 0.28), Vector3(1.0, 1.6, 0), definition.color, true)
	phase = 1
	return enemy

func _clear_warnings() -> void:
	warning_time = 0.0
	for warning in warnings:
		if is_instance_valid(warning):
			warning.queue_free()
	warnings.clear()
	locations.clear()

func allows_adaptation(time: float) -> bool:
	var live_boss: bool = (mini != null and mini.active) or (boss != null and boss.active)
	var mini_intro: bool = time >= MINI_BOSS_TIME - 5.0 and time < MINI_BOSS_TIME + 20.0
	return not live_boss and not mini_intro and time < FINAL_BOSS_TIME - 20.0
