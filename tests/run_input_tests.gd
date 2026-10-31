extends SceneTree

var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error(message)

func run() -> void:
	var router := InputRouter.new()
	router.setup()
	var player := SwarmPlayer.new()
	root.add_child(player)
	var touch := InputEventScreenTouch.new()
	touch.index = 7
	touch.pressed = true
	touch.position = Vector2(120, 600)
	router.handle(touch, Vector2(1280, 720))
	var drag := InputEventScreenDrag.new()
	drag.index = 7
	drag.position = Vector2(195, 600)
	router.handle(drag, Vector2(1280, 720))
	player.tick(0.1, router.movement(), false)
	check(is_equal_approx(player.position.x, 0.7) and player.position.z == 0.0, "normal touch movement uses seven metres per second")
	drag.position = Vector2(300, 780)
	router.handle(drag, Vector2(1280, 720))
	check(is_equal_approx(router.movement().length(), 1), "diagonal joystick cannot exceed unit movement")
	var position_before: Vector3 = player.position
	player.tick(0.1, router.movement(), false)
	check(is_equal_approx(player.position.distance_to(position_before), 0.7), "diagonal movement is not faster than axial movement")
	touch.index = 8
	router.handle(touch, Vector2(1280, 720))
	check(router.touch_id == 7, "second touch cannot steal active joystick")
	touch.pressed = false
	router.handle(touch, Vector2(1280, 720))
	check(router.touch_id == 7, "releasing other touch cannot cancel movement")
	touch.index = 7
	router.handle(touch, Vector2(1280, 720))
	check(router.touch_id == -1 and router.movement() == Vector2.ZERO, "joystick release stops movement")
	touch.pressed = true
	router.handle(touch, Vector2(1280, 720))
	router.dash_requested = true
	touch.pressed = false
	router.handle(touch, Vector2(1280, 720))
	check(router.dash_requested and router.touch_id == -1, "joystick release preserves a same-frame independent dash")
	router.reset()
	check(not router.dash_requested, "explicit state reset still discards pending dash")
	player.position = Vector3(46.9, 0, 46.9)
	player.tick(0.1, Vector2.ONE.normalized(), false)
	check(player.position.x <= 47 and player.position.z <= 47, "movement clamps to arena boundary")
	player.position = Vector3.ZERO
	check(player.tick(0.01, Vector2.RIGHT, true), "ready dash accepts input")
	check(is_equal_approx(player.position.x, 0.27) and player.health.invulnerable > 0, "dash moves at normal speed with temporary protection")
	check(player.body.visible, "operative silhouette remains visible during dash protection")
	check(not player.health.take_damage(50), "dash still blocks damage during its existing protection window")
	check(not player.tick(0.01, Vector2.RIGHT, true), "cooldown rejects repeated dash")
	player.tick(3, Vector2.ZERO, false)
	check(player.dash_cooldown == 0 and player.dash_time == 0, "dash timers clamp to zero")
	player.health.invulnerable = 0
	player.health.shield = 30
	player.health.current = 100
	check(player.health.take_damage(5) and player.health.last_absorbed == 5 and player.health.last_hull_loss == 0, "shield-only hit records actual absorbed damage")
	check(player.hit_ring.visible and player.hit_ring.material_override == SwarmVisuals.material(Color("5cbbf6"), true), "shield absorption shows blue feedback")
	player.tick(0.1, Vector2.ZERO, false)
	check(player.body.visible, "hit protection never hides the operative silhouette")
	player.tick(0.3, Vector2.ZERO, false)
	check(not player.hit_ring.visible, "damage ring expires instead of persisting")
	player.flash_feedback = false
	player.health.invulnerable = 0
	check(player.health.take_damage(50) and player.health.last_absorbed == 25 and player.health.last_hull_loss == 25, "mixed hit records shield and hull loss without changing damage")
	check(not player.hit_ring.visible, "reduced flashes suppress damage ring immediately")
	player.tick(0.01, Vector2.ZERO, false)
	check(player.body.visible, "reduced flashes keep operative visible after hull damage")
	router.dash_requested = true
	router.stick = Vector2.RIGHT
	router.reset()
	check(not router.dash_requested and router.stick == Vector2.ZERO and router.touch_id == -1, "input reset clears all held touch and dash state")
	player.queue_free()
	await process_frame
	QAReport.write("res://builds/qa/input-tests.json", {"checks": checks, "failures": failures})
	print("INPUT_RESULT checks=", checks, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
