tool
extends EditorPlugin

func _enter_tree():
	add_custom_type(
		"TrackballCamera", "Camera",
		preload("trackball_camera.gd"),
		preload("icon_trackball_camera.png")
	)

func _exit_tree():
	remove_custom_type("TrackballCamera")