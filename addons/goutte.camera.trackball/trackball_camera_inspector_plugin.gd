@tool
extends EditorInspectorPlugin


const EipTrackballCamera := preload("res://addons/goutte.camera.trackball/trackball_camera.gd")


# Injected because I can't figure out how to access Godot's theme from here
var warning_icon: Texture2D


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
#	var camera = object as EipTrackballCamera
#	if camera.detect_action_availability(object.get(name), true):
#		return
	# So we hack around it
	if detect_action_availability(object.get(name)):
		return

	var create_action_button := Button.new()
	create_action_button.set_name("CreateAction%s" % name)
	create_action_button.set_text("Create action %s" % [object.get(name)])
	if warning_icon:
		create_action_button.icon = warning_icon
	create_action_button.pressed.connect(
		func():
			prints("Creating the action %s…" % object.get(name))
			printerr("Due to https://github.com/godotengine/godot/issues/25865 you won't see the new action in your InputMap until AFTER you restart Godot.")
			
			var setting_key = "input/%s" % object.get(name)
			var setting = {
				'deadzone': 0.5,
				'events': get_default_input_events(name),
			}
			ProjectSettings.set_setting(setting_key, setting)
			ProjectSettings.save()
			
			create_action_button.queue_free()
			,
		Button.CONNECT_ONE_SHOT
	)
	add_custom_control(create_action_button)


func detect_action_availability(action: String) -> bool:
	if action == "":
		return false
	if ProjectSettings.has_setting("input/%s" % action):
		return true
	return false


func get_default_input_events(property_name: String) -> Array:
	match property_name:
		'action_zoom_in':
			var e0 := InputEventMouseButton.new()
			e0.button_index = MOUSE_BUTTON_WHEEL_UP
			e0.device = -1
			var e1 := InputEventKey.new()
			e1.physical_keycode = KEY_PAGEUP
			var e2 := InputEventKey.new()
			e2.physical_keycode = KEY_KP_ADD
			return [e0, e1, e2]
		'action_zoom_out':
			var e0 := InputEventMouseButton.new()
			e0.button_index = MOUSE_BUTTON_WHEEL_DOWN
			e0.device = -1
			var e1 := InputEventKey.new()
			e1.physical_keycode = KEY_PAGEDOWN
			var e2 := InputEventKey.new()
			e2.physical_keycode = KEY_KP_SUBTRACT
			return [e0, e1, e2]
		'action_free_horizon':
			var e1 := InputEventKey.new()
			e1.physical_keycode = KEY_CTRL
			return [e1]
		'action_barrel_roll':
			var e1 := InputEventKey.new()
			e1.physical_keycode = KEY_SHIFT
			return [e1]
	return []
