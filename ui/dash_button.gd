class_name TouchDashButton
extends Button

# BaseButton's touch-to-mouse path has one pointer. Track native touches here
# so a joystick finger cannot prevent another finger from pressing dash.
var touch_id: int = -1
var input_enabled: bool = false:
	set(value):
		input_enabled = value
		if not value:
			reset_touch()

func reset_touch() -> void:
	touch_id = -1
	set_pressed_no_signal(false)

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT]:
		reset_touch()
	elif what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		reset_touch()

func _input(event: InputEvent) -> void:
	if not input_enabled or disabled or not is_visible_in_tree():
		return
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		# The same primary touch may also generate a mouse event. Never turn
		# its release into a second dash after the native touch already fired.
		if event.device == InputEvent.DEVICE_ID_EMULATION and get_global_rect().has_point(event.position):
			get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		if event.index == touch_id:
			if not event.pressed or event.canceled:
				reset_touch()
			get_viewport().set_input_as_handled()
		elif event.pressed and not event.canceled and get_global_rect().has_point(event.position):
			if touch_id == -1:
				touch_id = event.index
				set_pressed_no_signal(true)
				pressed.emit()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == touch_id:
		# Moving this finger away never steals or changes joystick ownership.
		get_viewport().set_input_as_handled()
