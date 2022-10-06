tool
extends EditorPlugin

func _enter_tree():
	add_custom_type(
		"TrackballCamera", "Camera",
		load("res://addons/goutte.camera.trackball/trackball_camera.gd"),
		load("res://addons/goutte.camera.trackball/icon_trackball_camera.png")
	)

func _exit_tree():
	remove_custom_type("TrackballCamera")
