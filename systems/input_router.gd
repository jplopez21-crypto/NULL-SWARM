class_name InputRouter
extends RefCounted

var touch_id: int = -1
var origin: Vector2
var stick: Vector2
var dash_requested: bool = false
const ACTIONS: Dictionary = {"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN], "dash": [KEY_SPACE], "pause": [KEY_ESCAPE]}

func setup() -> void:
	for action in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in ACTIONS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
	for pair in [["dash", JOY_BUTTON_A], ["pause", JOY_BUTTON_START]]:
		var event := InputEventJoypadButton.new()
		event.button_index = pair[1]
		InputMap.action_add_event(pair[0], event)

func handle(event: InputEvent, viewport_size: Vector2) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and event.position.x < viewport_size.x * 0.45 and touch_id == -1:
			touch_id = event.index
			origin = event.position
			stick = Vector2.ZERO
		elif not event.pressed and event.index == touch_id:
			# A dash from another finger can arrive in the same physics frame.
			# Releasing movement must not discard that independent request.
			touch_id = -1
			stick = Vector2.ZERO
	if event is InputEventScreenDrag and event.index == touch_id:
		stick = ((event.position - origin) / 75.0).limit_length()
	if event.is_action_pressed("dash"):
		dash_requested = true

func movement() -> Vector2:
	var value := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if not Input.get_connected_joypads().is_empty():
		var device: int = Input.get_connected_joypads()[0]
		var axis := Vector2(Input.get_joy_axis(device, JOY_AXIS_LEFT_X), Input.get_joy_axis(device, JOY_AXIS_LEFT_Y))
		if axis.length() > 0.18:
			value += axis
	return (value + stick).limit_length()

func reset() -> void:
	touch_id = -1
	stick = Vector2.ZERO
	dash_requested = false
