@tool
extends EditorPlugin


const TrackballCameraInspectorPlugin := preload("res://addons/goutte.camera.trackball/trackball_camera_inspector_plugin.gd")


var inspector_plugin := TrackballCameraInspectorPlugin.new()


func _enter_tree():
	add_custom_type(
		"TrackballCamera", "Camera3D",
		load("res://addons/goutte.camera.trackball/trackball_camera.gd"),
		load("res://addons/goutte.camera.trackball/icon_trackball_camera.png")
	)
	
	var godot_theme := get_editor_interface().get_base_control().theme
	if godot_theme != null:
		inspector_plugin.warning_icon = godot_theme.get_icon('StatusWarning', 'EditorIcons')
	# Quite handy dump of the list of available icons
#	var list = Array(godot_theme.get_icon_list('EditorIcons'))
#	list.sort()
#	for icon_name in list:
#		print(icon_name)
	
	add_inspector_plugin(inspector_plugin)


func _exit_tree():
	remove_custom_type("TrackballCamera")
	remove_inspector_plugin(inspector_plugin)

