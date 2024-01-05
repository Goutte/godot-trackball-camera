@tool
extends EditorInspectorPlugin


const EipTrackballCamera := preload("res://addons/goutte.camera.trackball/trackball_camera.gd")
const ALL_DEVICES := -1


# Injected because I can't figure out how to access Godot's theme from here
var warning_icon: Texture2D = null


func _can_handle(object):
	return object is EipTrackballCamera


func _parse_begin(object):
	var create_actions_button := Button.new()
	create_actions_button.set_name("Create")
	create_actions_button.set_text("Create Actions")
	add_custom_control(create_actions_button)


func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
	if type != TYPE_STRING:
		return
	if not name.begins_with("action_"):
		return
	# Nonexistent function 'detect_action_availability' in base 'Camera3D ()'.
	# Because the camera is not a @tool (and we don't want to make it one)
#	var camera = object as EipTrackballCamera
#	if camera.detect_action_availability(object.get(name), true):
#		return
	# … so we hack around it and duplicate the method here
	if detect_action_availability(object.get(name)):
		return

	var create_action_button := Button.new()
	create_action_button.set_name("CreateAction%s" % name)
	create_action_button.set_text("Create action %s" % [object.get(name)])
	if warning_icon != null:
		create_action_button.icon = warning_icon
	create_action_button.pressed.connect(
		func():
			create_action_button.queue_free()
			if detect_action_availability(object.get(name)):
				printerr("Action %s was already created recently.  Skipping…" % object.get(name))
				return
			prints("Creating the action %s…" % object.get(name))
			printerr("Due to https://github.com/godotengine/godot/issues/25865 you won't see the new action in your InputMap until AFTER you restart Godot.")
			add_default_action(object, name)
			,
		Button.CONNECT_ONE_SHOT  # zealous, since we're freeing the button
	)
	add_custom_control(create_action_button)


func add_default_action(object: Object, name: String):
	var setting_key = "input/%s" % object.get(name)
	var setting = {
		'deadzone': 0.5,
		'events': get_default_input_events(name),
	}
	ProjectSettings.set_setting(setting_key, setting)
	ProjectSettings.save()


func detect_action_availability(action: String) -> bool:
	if action == "":
		return false
	if ProjectSettings.has_setting("input/%s" % action):
		return true
	return false


# TODO: decide on default inputs -- MRs welcome
func get_default_input_events(property_name: String) -> Array:
	match property_name:
		'action_up':
			var j0 := InputEventJoypadButton.new()
			j0.button_index = JOY_BUTTON_DPAD_UP
			j0.device = ALL_DEVICES
			var j1 := InputEventJoypadMotion.new()
			j1.axis = JOY_AXIS_LEFT_Y
			j1.axis_value = 1.0
			j1.device = ALL_DEVICES
			var j2 := InputEventJoypadMotion.new()
			j2.axis = JOY_AXIS_RIGHT_Y
			j2.axis_value = 1.0
			j2.device = ALL_DEVICES
			var k1 := InputEventKey.new()
			k1.physical_keycode = KEY_UP
			var k2 := InputEventKey.new()
			k2.physical_keycode = KEY_KP_8
			return [j0, j1, j2, k1, k2]
		'action_down':
			var j0 := InputEventJoypadButton.new()
			j0.button_index = JOY_BUTTON_DPAD_DOWN
			j0.device = ALL_DEVICES
			var j1 := InputEventJoypadMotion.new()
			j1.axis = JOY_AXIS_LEFT_Y
			j1.axis_value = -1.0
			j1.device = ALL_DEVICES
			var j2 := InputEventJoypadMotion.new()
			j2.axis = JOY_AXIS_RIGHT_Y
			j2.axis_value = -1.0
			j2.device = ALL_DEVICES
			var k1 := InputEventKey.new()
			k1.physical_keycode = KEY_DOWN
			var k2 := InputEventKey.new()
			k2.physical_keycode = KEY_KP_2
			return [j0, j1, j2, k1, k2]
		'action_left':
			var j0 := InputEventJoypadButton.new()
			j0.button_index = JOY_BUTTON_DPAD_LEFT
			j0.device = ALL_DEVICES
			var j1 := InputEventJoypadMotion.new()
			j1.axis = JOY_AXIS_LEFT_X
			j1.axis_value = -1.0
			j1.device = ALL_DEVICES
			var j2 := InputEventJoypadMotion.new()
			j2.axis = JOY_AXIS_RIGHT_X
			j2.axis_value = -1.0
			j2.device = ALL_DEVICES
			var k1 := InputEventKey.new()
			k1.physical_keycode = KEY_LEFT
			var k2 := InputEventKey.new()
			k2.physical_keycode = KEY_KP_4
			return [j0, j1, j2, k1, k2]
		'action_right':
			var j0 := InputEventJoypadButton.new()
			j0.button_index = JOY_BUTTON_DPAD_RIGHT
			j0.device = ALL_DEVICES
			var j1 := InputEventJoypadMotion.new()
			j1.axis = JOY_AXIS_LEFT_X
			j1.axis_value = 1.0
			j1.device = ALL_DEVICES
			var j2 := InputEventJoypadMotion.new()
			j2.axis = JOY_AXIS_RIGHT_X
			j2.axis_value = 1.0
			j2.device = ALL_DEVICES
			var k1 := InputEventKey.new()
			k1.physical_keycode = KEY_RIGHT
			var k2 := InputEventKey.new()
			k2.physical_keycode = KEY_KP_6
			return [j0, j1, j2, k1, k2]
		'action_zoom_in':
			var m0 := InputEventMouseButton.new()
			m0.button_index = MOUSE_BUTTON_WHEEL_UP
			m0.device = ALL_DEVICES
			var k1 := InputEventKey.new()
			k1.physical_keycode = KEY_PAGEUP
			var k2 := InputEventKey.new()
			k2.physical_keycode = KEY_KP_ADD
			return [m0, k1, k2]
		'action_zoom_out':
			var m0 := InputEventMouseButton.new()
			m0.button_index = MOUSE_BUTTON_WHEEL_DOWN
			m0.device = ALL_DEVICES
			var k1 := InputEventKey.new()
			k1.physical_keycode = KEY_PAGEDOWN
			var k2 := InputEventKey.new()
			k2.physical_keycode = KEY_KP_SUBTRACT
			return [m0, k1, k2]
		'action_free_horizon':
			var m0 := InputEventMouseButton.new()
			m0.button_index = MOUSE_BUTTON_RIGHT
			m0.device = ALL_DEVICES
			var k0 := InputEventKey.new()
			k0.physical_keycode = KEY_CTRL
			var k1 := InputEventKey.new()
			k1.physical_keycode = KEY_KP_0
			return [m0, k0, k1]
		'action_barrel_roll':
			var m0 := InputEventMouseButton.new()
			m0.button_index = MOUSE_BUTTON_MIDDLE
			m0.device = ALL_DEVICES
			var k0 := InputEventKey.new()
			k0.physical_keycode = KEY_SHIFT
			return [m0, k0]
	return []
