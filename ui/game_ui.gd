class_name GameUI
extends CanvasLayer

signal deploy
signal resume_run
signal restart
signal return_menu
signal pause_run
signal dash
signal upgrade_selected(id: String)
signal reroll_requested
signal lab_requested
signal research_requested(id: String)
signal kit_selected(id: String)
signal setting_changed(key: String, value: Variant)
const CYAN := Color("78f8d4")
const MUTED := Color("8cabb9")
var root: Control
var safe: MarginContainer
var column: VBoxContainer
var overlay: CenterContainer
var screen: PanelContainer
var hud: VBoxContainer
var health_bar: ProgressBar
var shield_bar: ProgressBar
var xp_bar: ProgressBar
var status_label: Label
var health_label: Label
var operative_title: String = "VANGUARD"
var weapons_label: Label
var perf_label: Label
var hint_label: Label
var dash_button: Button
var world_camera: Camera3D
var input_router: InputRouter
var damage_texts: Array[Dictionary] = []
var joystick_canvas: Control
var last_safe_size := Vector2.ZERO
var hud_visible: bool = false
var settings_return: Callable
var notices: Label
var adaptation_label: Label
var boss_bar: ProgressBar
var boss_label: Label
var surge_label: Label
var toast_title: Label
var toast_detail: Label
var toast_time: float = 0.0
var backdrop: Control

func _ready() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme := Theme.new()
	theme.default_font_size = 19
	for kind in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("16323e") if kind == "normal" else Color("245261")
		style.border_color = CYAN if kind != "normal" else Color("355563")
		style.set_border_width_all(2 if kind == "focus" else 1)
		style.set_corner_radius_all(5)
		style.content_margin_left = 20
		style.content_margin_right = 20
		style.content_margin_top = 15
		style.content_margin_bottom = 15
		theme.set_stylebox(kind, "Button", style)
	theme.set_color("font_color", "Label", Color("e0f0f2"))
	theme.set_color("font_color", "Button", Color("e0f0f2"))
	root.theme = theme
	backdrop = Control.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(backdrop)
	root.move_child(backdrop, 0)
	backdrop.draw.connect(_draw_brand)
	safe = MarginContainer.new()
	safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(safe)
	column = VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe.add_child(column)
	_build_hud()
	overlay = CenterContainer.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(overlay)
	joystick_canvas = Control.new()
	joystick_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	joystick_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(joystick_canvas)
	joystick_canvas.draw.connect(_draw_feedback)
	_safe_area()
	root.resized.connect(_safe_area)

func label_at(parent: Node, text: String, font_size: int = 19, color: Color = Color("e0f0f2")) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func button_at(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 56
	parent.add_child(button)
	button.pressed.connect(callback)
	button.mouse_entered.connect(func(): button.modulate = Color("baffee"))
	button.mouse_exited.connect(func(): button.modulate = Color.WHITE)
	return button

func _safe_area() -> void:
	var margin_x: int = 26
	var margin_y: int = 18
	if OS.has_feature("android"):
		var area := DisplayServer.get_display_safe_area()
		var window := DisplayServer.window_get_size()
		if area.size.x > 0 and window.x > 0:
			var ratio: float = root.size.x / float(window.x)
			margin_x = maxi(26, int(maxi(area.position.x, window.x - area.end.x) * ratio) + 8)
			margin_y = maxi(18, int(maxi(area.position.y, window.y - area.end.y) * ratio) + 8)
	for side in ["left", "right"]:
		safe.add_theme_constant_override("margin_" + side, margin_x)
	for side in ["top", "bottom"]:
		safe.add_theme_constant_override("margin_" + side, margin_y)
	last_safe_size = root.size

func _bar(parent: Node, color: Color, height: int) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size.y = height
	bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("152c36")
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	parent.add_child(bar)
	return bar

func _build_hud() -> void:
	hud = VBoxContainer.new()
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(hud)
	var top := HBoxContainer.new()
	hud.add_child(top)
	var vital := VBoxContainer.new()
	vital.custom_minimum_size.x = 260
	top.add_child(vital)
	health_label = label_at(vital, "VANGUARD  /  100 HP", 18, CYAN)
	health_bar = _bar(vital, CYAN, 13)
	shield_bar = _bar(vital, Color("5cbbf6"), 6)
	status_label = label_at(top, "", 23)
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button_at(top, "II  PAUSE", func(): pause_run.emit())
	xp_bar = _bar(hud, Color("5e9fff"), 5)
	weapons_label = label_at(hud, "PULSE RIFLE  /  AUTOMATIC", 15, MUTED)
	adaptation_label = label_at(hud, "SWARM // OBSERVING", 14, Color("ffcf85"))
	hint_label = label_at(hud, "MOVE: WASD / LEFT STICK     DASH: SPACE / A", 15, MUTED)
	perf_label = label_at(hud, "", 14, MUTED)
	perf_label.visible = false
	notices = label_at(hud, "", 16, Color("ffbd78"))
	boss_label = label_at(hud, "", 18, Color("ff9274"))
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_bar = _bar(hud, Color("ff7652"), 7)
	boss_label.visible = false
	boss_bar.visible = false
	surge_label = label_at(hud, "", 18, Color("b9f66b"))
	surge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_title = label_at(hud, "", 30, CYAN)
	toast_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_detail = label_at(hud, "", 16, MUTED)
	toast_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	var bottom := HBoxContainer.new()
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(bottom)
	var left := Control.new()
	left.custom_minimum_size.x = 240
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(left)
	dash_button = button_at(bottom, "DASH  /  READY", func(): dash.emit())
	dash_button.custom_minimum_size = Vector2(180, 95)

func _panel() -> VBoxContainer:
	if screen != null:
		overlay.remove_child(screen)
		screen.queue_free()
	screen = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.06, 0.085, 0.94)
	style.border_color = Color("355966")
	style.set_border_width_all(1)
	style.border_width_top = 3
	style.set_corner_radius_all(8)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	screen.add_theme_stylebox_override("panel", style)
	overlay.add_child(screen)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	screen.add_child(box)
	screen.modulate.a = 0.0
	create_tween().tween_property(screen, "modulate:a", 1.0, 0.16)
	return box

func show_menu(data: Dictionary) -> void:
	set_hud(false)
	var box := _panel()
	box.custom_minimum_size.x = 570
	label_at(box, "N // S     •     COMBAT SYSTEMS ONLINE", 16, CYAN)
	label_at(box, "NULL//SWARM", 64)
	label_at(box, "THE NETWORK IS LOST. YOU ARE STILL ONLINE.", 16, MUTED)
	label_at(box, "REACTOR ZERO  /  SURVIVAL", 23)
	label_at(box, "Ten minutes. Four weapon slots. The swarm learns.\nWeapons auto-fire. Large gold packets hold more XP.", 19, MUTED)
	label_at(box, "WARDEN 03:00     //     ARCHITECT 09:00", 16, Color("ffb35c"))
	var play := button_at(box, "DEPLOY %s     →" % Research.KITS[data["selected_kit"]]["title"], func(): deploy.emit())
	button_at(box, "FOUNDRY  /  %d SALVAGE" % int(data["salvage"]), func(): lab_requested.emit())
	button_at(box, "SETTINGS", func(): show_settings(data["settings"], func(): show_menu(data)))
	label_at(box, "BEST  %s     /     DEPLOYMENTS  %d     /     VICTORIES  %d" % [clock(float(data["best_time"])), data["runs"], data["wins"]], 15, CYAN)
	label_at(box, "BUILD 0.4  •  SWARM ANALYSIS STARTS AT 02:00", 13, MUTED)
	play.grab_focus()

func set_hud(value: bool) -> void:
	hud_visible = value
	column.visible = value
	joystick_canvas.queue_redraw()

func hide_panel() -> void:
	if screen != null:
		overlay.remove_child(screen)
		screen.queue_free()
		screen = null

func show_pause(settings: Dictionary) -> void:
	var box := _panel()
	box.custom_minimum_size.x = 430
	label_at(box, "SIGNAL HELD", 38, CYAN)
	label_at(box, "Deployment paused", 20, MUTED)
	var resume_button := button_at(box, "RESUME", func(): resume_run.emit())
	button_at(box, "SETTINGS", func(): show_settings(settings, func(): show_pause(settings)))
	button_at(box, "END DEPLOYMENT", func(): return_menu.emit())
	resume_button.grab_focus()

func show_results(won: bool, elapsed: float, kills: int, level: int, total_xp: int, salvage: int = 0, wallet: int = 0, breakdown: Dictionary = {}, unlocks: Array[String] = []) -> void:
	set_hud(false)
	var box := _panel()
	box.custom_minimum_size.x = 530
	label_at(box, "EXTRACTION COMPLETE" if won else "SIGNAL LOST", 39, CYAN if won else Color("ff8e7b"))
	label_at(box, "The sector holds. Your telemetry survived." if won else "Operative offline. Your telemetry survived.", 18, MUTED)
	label_at(box, "%s   /   %d DESTROYED   /   LEVEL %d" % [clock(elapsed), kills, level], 22)
	label_at(box, "%d memory recovered   //   +%d SALVAGE BANKED" % [total_xp, salvage], 18, CYAN)
	var rows: Array = breakdown.keys()
	rows.sort_custom(func(a: String, b: String): return float(breakdown[a]) > float(breakdown[b]))
	var summary: Array[String] = []
	for id in rows.slice(0, 3):
		summary.append("%s %d" % [Arsenal.title(id), int(breakdown[id])])
	label_at(box, "DAMAGE  /  " + "   /   ".join(summary), 14, MUTED)
	for id in unlocks:
		label_at(box, "UNLOCKED // " + Research.KITS[id]["title"], 17, Color("ffe39b"))
	button_at(box, "FOUNDRY  /  %d SALVAGE AVAILABLE" % wallet, func(): lab_requested.emit())
	var again := button_at(box, "REDEPLOY     →", func(): restart.emit())
	button_at(box, "COMMAND MENU", func(): return_menu.emit())
	again.grab_focus()

func show_upgrades(ids: Array[String], descriptions: Callable, level: int, rerolls: int = 0) -> void:
	var box := _panel()
	label_at(box, "MEMORY RECONSTRUCTED  /  LEVEL %02d" % level, 18, CYAN)
	label_at(box, "CHOOSE YOUR ADVANTAGE", 32)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var first: Button
	for i in range(ids.size()):
		var id: String = ids[i]
		var text: String = descriptions.call(id)
		var button := button_at(row, "0%d\n\n%s" % [i + 1, text], func(): upgrade_selected.emit(id))
		button.custom_minimum_size = Vector2(292, 255)
		button.add_theme_font_size_override("font_size", 17)
		button.add_theme_color_override("font_color", Arsenal.color(id))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var card_style: StyleBoxFlat = button.get_theme_stylebox("normal").duplicate()
		card_style.border_width_left = 4
		card_style.border_color = Arsenal.color(id)
		button.add_theme_stylebox_override("normal", card_style)
		if first == null:
			first = button
	var footer := HBoxContainer.new()
	box.add_child(footer)
	var caption := label_at(footer, "4 WEAPON SLOTS // CHOOSE A DIRECTION", 14, MUTED)
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var reroll := button_at(footer, "REROLL  /  %d" % rerolls, func(): reroll_requested.emit())
	reroll.disabled = rerolls <= 0
	first.grab_focus()

func show_settings(settings: Dictionary, back: Callable) -> void:
	settings_return = back
	var box := _panel()
	box.custom_minimum_size.x = 540
	label_at(box, "SYSTEM SETTINGS", 30, CYAN)
	for key in ["master", "music", "sfx", "ui"]:
		var row := HBoxContainer.new()
		box.add_child(row)
		var label := label_at(row, key.to_upper(), 17, MUTED)
		label.custom_minimum_size.x = 130
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.value = float(settings[key])
		slider.custom_minimum_size = Vector2(300, 36)
		row.add_child(slider)
		slider.value_changed.connect(func(value: float): setting_changed.emit(key, value))
	for pair in [["shake", "Camera shake"], ["flashes", "Impact flashes"]]:
		var check := CheckButton.new()
		check.text = pair[1]
		check.button_pressed = settings[pair[0]]
		box.add_child(check)
		check.toggled.connect(func(value: bool): setting_changed.emit(pair[0], value))
	var row := HBoxContainer.new()
	box.add_child(row)
	label_at(row, "EFFECT QUALITY", 17, MUTED)
	var options := OptionButton.new()
	for name in ["LOW", "MEDIUM", "HIGH"]:
		options.add_item(name)
	options.selected = int(settings["quality"])
	row.add_child(options)
	options.item_selected.connect(func(index: int): setting_changed.emit("quality", index))
	var back_button := button_at(box, "BACK", back)
	back_button.grab_focus()

func update_hud(player: SwarmPlayer, progress: RunProgression, combat: CombatWorld) -> void:
	health_label.text = "%s / %d HP + %d SHIELD" % [operative_title, ceili(player.health.current), ceili(player.health.shield)]
	health_bar.value = 100.0 * player.health.current / player.health.maximum
	shield_bar.value = 100.0 * player.health.shield / maxf(1.0, player.health.max_shield)
	xp_bar.value = 100.0 * progress.xp / progress.threshold()
	status_label.text = "%s / 10:00     LV %02d     %d KILLS" % [clock(combat.director.elapsed), progress.level, combat.kills]
	var names: Array[String] = ["ARCSTORM" if combat.mutations.has("arcstorm") else "PULSE RIFLE"]
	for id in Arsenal.DATA:
		if progress.ranks.has(id):
			names.append(("SOLAR HALO" if id == "orbit" and combat.mutations.has("halo") else Arsenal.title(id)) + " %d" % progress.ranks[id])
	weapons_label.text = "   /   ".join(names) + "    [%d/4]" % progress.equipped()
	var boss: SwarmEnemy = combat.encounters.boss if combat.encounters.boss != null and combat.encounters.boss.active else combat.encounters.mini
	var boss_active := boss != null and boss.active
	boss_bar.visible = boss_active
	boss_label.visible = boss_active
	if boss_active:
		boss_label.text = boss.definition.title + "  //  PHASE %d" % combat.encounters.phase
		if boss.exposed_time > 0.0:
			boss_label.text += " // EXPOSED %.1fs" % boss.exposed_time
		boss_bar.value = 100.0 * boss.hp / boss.max_hp
	surge_label.text = "OVERCLOCK  %.1fs  //  FIRE RATE +60%%" % combat.overclock if combat.overclock > 0.0 else ("%d CHAIN  //  NEXT OVERCLOCK AT %d" % [combat.streak, (combat.streak / 20 + 1) * 20] if combat.streak > 1 else "")
	dash_button.text = "DASH / %.1fs" % player.dash_cooldown if player.dash_cooldown > 0.0 else "DASH / READY"
	adaptation_label.text = combat.adaptation.status()
	var time := combat.director.elapsed
	hint_label.visible = time < 22.0
	notices.text = "STRIKER SIGNALS DETECTED • ORANGE LANES WARN OF CHARGES" if time > 22.0 and time < 29.0 else ("SENTRY SIGNALS DETECTED • AVOID VIOLET FIRING LANES" if time > 62.0 and time < 70.0 else "")
	if perf_label.visible:
		var fps := Engine.get_frames_per_second()
		perf_label.text = "%d FPS / %.1fms  •  ENEMIES %d  •  SHOTS %d  •  DRAWS %d  •  STATIC %.1fMB" % [fps, 1000.0 / maxf(1.0, fps), combat.active_enemies, combat.active_projectiles, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0]

static func clock(seconds: float) -> String:
	return "%02d:%02d" % [int(seconds) / 60, int(seconds) % 60]

func add_damage(at: Vector3, amount: float, critical: bool, enabled: bool) -> void:
	if not enabled or damage_texts.size() >= 36:
		return
	damage_texts.append({"at": at, "text": str(int(amount)), "life": 0.6, "critical": critical})

func _process(delta: float) -> void:
	toast_time = maxf(0.0, toast_time - delta)
	toast_title.visible = toast_time > 0.0
	toast_detail.visible = toast_time > 0.0
	backdrop.queue_redraw()
	for i in range(damage_texts.size() - 1, -1, -1):
		damage_texts[i]["life"] -= delta
		if damage_texts[i]["life"] <= 0.0:
			damage_texts.remove_at(i)
	joystick_canvas.queue_redraw()

func _draw_feedback() -> void:
	if not hud_visible or screen != null:
		return
	if input_router != null:
		var center := input_router.origin if input_router.touch_id >= 0 else Vector2(120, root.size.y - 110)
		joystick_canvas.draw_circle(center, 70, Color(0.3, 0.8, 0.8, 0.08))
		joystick_canvas.draw_arc(center, 70, 0, TAU, 40, Color(0.4, 0.9, 0.8, 0.4), 2.0)
		joystick_canvas.draw_circle(center + input_router.stick * 60, 23, Color(0.4, 0.9, 0.8, 0.4))
	if world_camera == null:
		return
	for item in damage_texts:
		var at: Vector3 = item["at"] + Vector3(0, 1.5 + (0.6 - item["life"]) * 2.0, 0)
		if not world_camera.is_position_behind(at):
			var point := world_camera.unproject_position(at)
			joystick_canvas.draw_string(ThemeDB.fallback_font, point, item["text"], HORIZONTAL_ALIGNMENT_LEFT, -1, 24 if item["critical"] else 17, Color("ffe990") if item["critical"] else Color("d6ffed"))

func toast(title: String, detail: String, color: Color = CYAN) -> void:
	toast_title.text = title
	toast_title.add_theme_color_override("font_color", color)
	toast_detail.text = detail
	toast_time = 3.0

func _draw_brand() -> void:
	if hud_visible:
		return
	var size := root.size
	backdrop.draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.025, 0.045, 0.6))
	var origin := Vector2(size.x * 0.82, size.y * 0.5)
	var angle := Time.get_ticks_msec() * 0.0001
	for i in range(3):
		var radius: float = 150.0 + i * 55
		backdrop.draw_arc(origin, radius, angle + i, angle + i + PI * 1.65, 80, Color(0.23, 0.63, 0.62, 0.18), 2.0)
	for i in range(12):
		var y: float = i * 70.0
		backdrop.draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.2, 0.4, 0.5, 0.06), 1)

func show_lab(data: Dictionary, back: Callable, message: String = "") -> void:
	set_hud(false)
	var box := _panel()
	label_at(box, "THE FOUNDRY  //  %d SALVAGE" % int(data["salvage"]), 32, CYAN)
	label_at(box, message if not message.is_empty() else "Banked every 30s, at boss recovery and on exit. Defeat keeps earned salvage.", 16, MUTED)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	for id in Research.UPGRADES:
		var definition: Dictionary = Research.UPGRADES[id]
		var card := VBoxContainer.new()
		card.custom_minimum_size.x = 280
		row.add_child(card)
		label_at(card, definition["title"], 18, CYAN)
		label_at(card, definition["description"], 15, MUTED)
		var rank: int = int(data["research"].get(id, 0))
		var cost := Research.cost(data, id)
		label_at(card, "RANK %d / %d" % [rank, definition["costs"].size()], 15)
		var purchase := button_at(card, "MAXED" if cost < 0 else "RESEARCH // %d" % cost, func(): research_requested.emit(id))
		purchase.disabled = cost < 0 or cost > int(data["salvage"])
	label_at(box, "STARTING KITS // EACH HAS A TRADEOFF", 19, Color("ffe39b"))
	var unlocked := Research.unlocked(data)
	for id in Research.KITS:
		var kit: Dictionary = Research.KITS[id]
		var requirement := ""
		if not unlocked.has(id):
			requirement = "  LOCKED: %d/150 lifetime kills" % mini(150, int(data["salvaged_kills"])) if id == "conductor" else "  LOCKED: defeat the Warden"
		var text: String = kit["title"] + ("  [SELECTED]" if data["selected_kit"] == id else "") + requirement + "\n" + kit["description"]
		var select := button_at(box, text, func(): kit_selected.emit(id))
		select.add_theme_font_size_override("font_size", 16)
		select.disabled = not unlocked.has(id) or data["selected_kit"] == id
	var back_button := button_at(box, "BACK", back)
	back_button.grab_focus()
