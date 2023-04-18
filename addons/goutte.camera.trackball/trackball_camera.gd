extends Camera3D

#  _______             _    _           _ _  _____
# |__   __|           | |  | |         | | |/ ____|
#    | |_ __ __ _  ___| | _| |__   __ _| | | |     __ _ _ __ ___   ___ _ __ __ _
#    | | '__/ _` |/ __| |/ / '_ \ / _` | | | |    / _` | '_ ` _ \ / _ \ '__/ _` |
#    | | | | (_| | (__|   <| |_) | (_| | | | |___| (_| | | | | | |  __/ | | (_| |
#    |_|_|  \__,_|\___|_|\_\_.__/ \__,_|_|_|\_____\__,_|_| |_| |_|\___|_|  \__,_|
# Version 7.1
#
# Responds to actions and input from mouse, keyboard, joystick and touch,
# in order to rotate around its parent node while continuously facing it.
# It is also called an Orbit Camera.
#
#
# Main Features
# -------------
# - No gimbal lock (quaternions)
# - Inertia (optional)
# - Orbit, zoom, roll
# - Stabilize or free the horizon
# - Extensible (hopefully)
# - One-click creation of camera actions (trackball_camera_inspector_plugin.gd)
#
#
# Requirements
# ------------
# Godot `4.x`.
# Other versions are available for Godot `3.x` and `2.x`, see tags and branches.
#
#
# Usage
# -----
# 1. Attach this script to a Camera3D (or use plugin's TrackballCamera node)
# 2. Move Camera3D as child of the Node to trackball around
# 3. Move your Camera3D so that it looks at that Node (translate it along +Z a bit)
# The initial position of your camera matters.
#
#
# First-Person
# ------------
# You can use this camera to look around if you place it atop its parent node.
# It's going to rotate around itself, and that amounts to looking around.
# You'll probably want to use the xxxxx_invert properties in that case.
#
#
# License
# -------
# Same as Godot, ie. permissive MIT. (https://godotengine.org/license)


# Keep the horizon (ie rotation axis) stable, the UP to Y.
# See also action_free_horizon to mix up stable and free.
@export var stabilize_horizon := false
# Only used if horizon is kept stable
@export var headstand_invert_x := true

@export var mouse_enabled := true
@export var mouse_invert := false
@export var mouse_strength := 1.0
# If true will disable click+drag and move around with the mouse moves
@export var mouse_move_mode := false

@export var action_enabled := true
@export var action_invert := false
@export var action_strength := 1.0
@export var action_up := 'ui_up'
@export var action_down := 'ui_down'
@export var action_right := 'ui_right'
@export var action_left := 'ui_left'
@export var action_zoom_in := 'cam_zoom_in'
@export var action_zoom_out := 'cam_zoom_out'
@export var action_free_horizon := 'cam_free_horizon'
@export var action_barrel_roll := 'cam_barrel_roll'

@export var zoom_enabled := true
@export var zoom_invert := false
@export var zoom_strength := 1.0
# As worldspace distances between the camera and its target
@export var zoom_minimum := 3.0
@export var zoom_maximum := 90.0

# When zoom inertia gets below this treshold, stop zooming
@export_range(0.0, 1.0, 0.000001) var zoom_inertia_treshold := 0.0001
# Dampen zoom in when it approaches the minimum (0 = disabled)
@export var zoom_in_dampening := 0.0  # 25.0 works well as a value here

# Multiplier applied to all lateral (non-zoom) inputs
@export var inertia_strength := 1.0
# When inertia gets below this treshold, stop the camera
@export_range(0.0, 1.0, 0.000001) var inertia_treshold := 0.0001
# Fraction of inertia lost on each frame
@export_range(0.0, 1.0, 0.0001) var friction := 0.07:
	set(value):
		friction = value
		recompute_lubricant_efficiency()

# Care for our friends with motion sickness
@export var no_drag_inertia := false

# Needs more work
#export var enable_yaw_limit = true  # left & right
# Limit as fraction of a half-circle = TAU/2 = PI
#export var yaw_limit = 1.0 # (float, 0, 1, 0.005)

@export var enable_pitch_limit := false  # up & down
# Limits as fraction of a quarter-circle (TAU/4)
@export var pitch_up_limit := 1.0 # (float, 0, 1, 0.005)
@export var pitch_down_limit := 1.0 # (float, 0, 1, 0.005)
@export var pitch_limit_strength := 1.0 # (float, 0, 100, 0.05)

# Directly bound keyboard is deprecated, use actions instead
@export var keyboard_enabled := false
@export var keyboard_invert := false
@export var keyboard_strength := 1.0
# Directly bound joystick is deprecated, use actions instead
@export var joystick_enabled := false
@export var joystick_invert := false
@export var joystick_strength := 1.0
# The resting state of my joystick's x-axis is ±0.05,
# so we want to ignore any input below this threshold.
@export var joystick_threshold := 0.09
@export var joystick_device := 0


const QUARTER_CIRCLE := TAU / 4.0
const ZOOM_IN := Vector3.FORWARD
const ABSURD_VECTOR2 := Vector2.INF
# Internal normalizations to target sane defaults at 1
const ZOOM_STRENGTH_NORMALIZATION := 0.05
const MOUSE_STRENGTH_NORMALIZATION := 0.00005

var _horizonUp := Vector3.UP
var _cameraUp := Vector3.UP
var _cameraRight := Vector3.RIGHT
var _mouseDragStart := ABSURD_VECTOR2
var _mouseDragPosition := ABSURD_VECTOR2
var _dragInertia := Vector2.ZERO
var _zoomInertia := 0.0
var _rollInertia := 0.0
var _lubricantEfficiency := 1.0
var _isBarrelRollAvailable := false
var _isFreeHorizonAvailable := false
var _isZoomInAvailable := false
var _isZoomOutAvailable := false


func _ready():  # this allows overriding through inheritance
	ready()


func _input(event: InputEvent):  # this allows overriding through inheritance
	input(event)


func _process(delta: float):  # this allows overriding through inheritance
	process(delta)


func ready():
	detect_actions_availability()
	recompute_lubricant_efficiency()  # as friction setter may never trigger
	#print("%s around %s is ready. ♥" % [get_name(), get_parent().get_name()])


func input(event: InputEvent):
	if mouse_enabled:
		handle_mouse_input(event)


func handle_mouse_input(event: InputEvent):
	if (not mouse_move_mode) and (event is InputEventMouseButton):
		if (event as InputEventMouseButton).pressed:
			_mouseDragStart = get_mouse_position()
		else:
			_mouseDragStart = ABSURD_VECTOR2
		_mouseDragPosition = _mouseDragStart
	if (mouse_move_mode) and (event is InputEventMouseMotion):
		add_inertia(
			(event as InputEventMouseMotion).relative *
			mouse_strength *
			MOUSE_STRENGTH_NORMALIZATION
		)


func process(delta: float):
	process_mouse(delta)
	process_keyboard(delta)
	process_joystick(delta)
	process_actions(delta)
	process_zoom(delta)
	process_drag_inertia(delta)
	process_roll_inertia(delta)
	process_zoom_inertia(delta)


func process_mouse(delta: float):
	if mouse_enabled and _mouseDragPosition != ABSURD_VECTOR2:
		var _currentDragPosition = get_mouse_position()
		add_inertia((
			(_currentDragPosition - _mouseDragPosition)
			* mouse_strength * (-0.1 if mouse_invert else 0.1)
		), (_currentDragPosition - Vector2.ONE / 2.0) * Vector2(1.0, -1.0))
		_mouseDragPosition = _currentDragPosition


func process_keyboard(delta: float):  # deprecated, use actions
	if keyboard_enabled:
		var key_s := keyboard_strength / 1000.0  # exported floats get truncated
		key_s *= -1.0 if keyboard_invert else 1.0
		if Input.is_key_pressed(KEY_LEFT):
			add_inertia(Vector2(key_s, 0.0))
		if Input.is_key_pressed(KEY_RIGHT):
			add_inertia(Vector2(-1.0 * key_s, 0.0))
		if Input.is_key_pressed(KEY_UP):
			add_inertia(Vector2(0.0, key_s))
		if Input.is_key_pressed(KEY_DOWN):
			add_inertia(Vector2(0.0, -1.0 * key_s))


func process_joystick(delta: float):  # deprecated, use actions
	if joystick_enabled:
		var joy_h := Input.get_joy_axis(joystick_device, JOY_AXIS_LEFT_X)
		var abs_joy_h : float = abs(joy_h) as float  # not greenlit-typed right now
		var joy_v := Input.get_joy_axis(joystick_device, JOY_AXIS_LEFT_Y)
		var joy_s := joystick_strength / 1000.0  # exported floats are truncated
		joy_s *= -1.0 if joystick_invert else 1.0

		if abs_joy_h > joystick_threshold:
			add_inertia(Vector2(joy_h * joy_h * sign(joy_h) * joy_s, 0.0))
		if abs(joy_v) > joystick_threshold:
			add_inertia(Vector2(0.0, joy_v * joy_v * sign(joy_v) * joy_s))


func process_actions(delta: float):
	if action_enabled:
		# Exported floats are truncated, so we use a bigger number
		var intent := action_strength / 1000.0
		intent *= -1.0 if action_invert else 1.0
		if Input.is_action_pressed(action_up):
			var analog := Input.get_action_strength(action_up)
			add_inertia(Vector2(0.0, intent * analog))
		if Input.is_action_pressed(action_down):
			var analog := Input.get_action_strength(action_down)
			add_inertia(Vector2(0.0, intent * analog * -1.0))
		if Input.is_action_pressed(action_left):
			var analog := Input.get_action_strength(action_left)
			add_inertia(Vector2(intent * analog, 0.0))
		if Input.is_action_pressed(action_right):
			var analog := Input.get_action_strength(action_right)
			add_inertia(Vector2(intent * analog * -1.0, 0.0))


func process_zoom(delta: float):
	if zoom_enabled:
		var inertia := zoom_strength * ZOOM_STRENGTH_NORMALIZATION
		inertia *= -1.0 if zoom_invert else 1.0
		if should_zoom_in():
			add_zoom_inertia(inertia)
		if should_zoom_out():
			add_zoom_inertia(inertia * -1.0)


func process_drag_inertia(delta: float):
	var inertia := _dragInertia.length()
	if inertia > inertia_treshold:
		apply_rotation_from_tangent(_dragInertia * inertia_strength)
		apply_drag_friction()
	else:
		_dragInertia.x = 0
		_dragInertia.y = 0


func process_roll_inertia(delta: float):
	if abs(_rollInertia) > inertia_treshold:
		apply_barrel_roll(_rollInertia * inertia_strength)
		apply_roll_friction()
	else:
		_rollInertia = 0


func process_zoom_inertia(delta: float):
	# This whole function is … bouerk.  Please share your improvements!
	var cpl := get_distance_to_target()
	if abs(_zoomInertia) > zoom_inertia_treshold:
		if cpl < zoom_minimum:
			if _zoomInertia > 0.0:
				_zoomInertia *= float(max(0, 1 - (1.333 * (zoom_minimum - cpl) / zoom_minimum)))
			_zoomInertia = _zoomInertia - 0.1 * (zoom_minimum - cpl) / zoom_minimum
		if cpl > zoom_maximum:
			_zoomInertia += 0.09 * exp((cpl - zoom_maximum) * 3 + 1) * (cpl - zoom_maximum) * (cpl - zoom_maximum)
		apply_zoom(_zoomInertia)
		apply_zoom_friction()
	else:
		_zoomInertia = 0.0


# Moves the camera around its target, or barrel rolls it.
# inertia is a Vector2 in the normalized right-handed x/y of the screen.
# Y is up.  The origin is in the center of the screen.
func add_inertia(inertia: Vector2, origin := Vector2.ZERO):
	if should_barrel_roll():
		if origin == Vector2.ZERO:
			if inertia.dot(Vector2.RIGHT + Vector2.UP) < 0:
				_rollInertia += inertia.length()
			else:
				_rollInertia -= inertia.length()
		else:
			if (inertia * Vector2(-1.0, 1.0)).angle_to(-origin) < 0:
				_rollInertia -= inertia.length()
			else:
				_rollInertia += inertia.length()
	else:
		if self.no_drag_inertia:
			apply_rotation_from_tangent(inertia * inertia_strength)
		else:
			_dragInertia += inertia


# Moves the camera towards its target, or away from it if inertia is negative.
func add_zoom_inertia(inertia: float):
	if zoom_in_dampening > 0.0 and inertia > 0.0:
		var delta := float(abs(get_distance_to_target() - zoom_minimum))
		var brake := pow(zoom_in_dampening, -1.0 * delta + 1.0) + 1.0
		inertia /= brake
	_zoomInertia += inertia


func apply_zoom(amount: float):
	translate(ZOOM_IN * amount)


# Override this method to apply your custom constraints.
# You can both edit the on_transform or make a new one.
func apply_constraints(on_transform: Transform3D) -> Transform3D:
	if enable_pitch_limit and not should_free_horizon():
		on_transform = apply_pitch_constraint(on_transform)
	return on_transform


func apply_pitch_constraint(on_transform: Transform3D) -> Transform3D:
	var eulers := on_transform.basis.get_euler()

	var dxu := QUARTER_CIRCLE * pitch_up_limit + eulers.x
	var dxd := QUARTER_CIRCLE * pitch_down_limit - eulers.x
	var limit_will := 0.0
	var limit_over := 0.0
	if dxu < 0.0:
		limit_will = 1.0
		limit_over = dxu
	if dxd < 0.0:
		limit_will = -1.0
		limit_over = dxd
	if 0.0 != limit_will:
		_dragInertia.y = 0.0

		var resistance_strength := (((1.0 - limit_over) * (1.0 - limit_over)) - 1.0)

		add_inertia((
			limit_will * Vector2.UP  # direction
			* 0.00282  # role: yield a sane behavior with defaults
			* resistance_strength  # grows as the trespassing intensifies
			* pitch_limit_strength  # allow scaling with other strengths?
		))
		# …or modify the transform directly, but it's jittery

	return on_transform


# Tool you can perhaps use in the above method,
# to make sure we can't look too far up or down.
# Useful to make sure we can't do headstands with the camera in FPS.
# Only works well when:
# - horizon is stabilized
# - camera is at origin of parent (0,0,0)   (fps mode)
func apply_updown_constraint(on_transform: Transform3D, limit := 0.75) -> Transform3D:
	var eulers: Vector3 = on_transform.basis.get_euler()
	eulers.x = clamp(eulers.x, -limit, limit)
	eulers.z = 0.0
	on_transform.basis = Basis(Quaternion.from_euler(eulers))
	return on_transform


func apply_rotation_from_tangent(orthogonal: Vector2):
	var tr := get_transform()
	var up: Vector3

	if should_stabilize_horizon():
		up = _horizonUp
		if headstand_invert_x and is_in_headstand():
			orthogonal.x *= -1.0
	else:
		up = tr.basis * _cameraUp.normalized()
		update_horizon(up)

	var rt := tr.basis * _cameraRight.normalized()
	var upQuat := Quaternion(up, -1.0 * orthogonal.x * TAU)
	var rgQuat := Quaternion(rt, -1.0 * orthogonal.y * TAU)
	var rotatedTransform := Transform3D(upQuat * rgQuat) * tr
	set_transform(apply_constraints(rotatedTransform))


func apply_barrel_roll(amount: float):
	rotate_object_local(Vector3.BACK, amount)
	update_horizon(get_transform().basis * _cameraUp.normalized())


func apply_drag_friction():
	_dragInertia *= _lubricantEfficiency


func apply_roll_friction():
	_rollInertia *= _lubricantEfficiency


func apply_zoom_friction():
	_zoomInertia *= _lubricantEfficiency


func recompute_lubricant_efficiency():
	_lubricantEfficiency = 1.0 - self.friction


func update_horizon(new_up: Vector3):
	_horizonUp = new_up


func get_mouse_position() -> Vector2:
	return (
		get_viewport().get_mouse_position()
		/
		get_viewport().get_visible_rect().size
	)


func get_distance_to_target() -> float:
	return transform.origin.length()


func is_in_headstand() -> bool:
	var actualUp := get_transform().basis * _cameraUp.normalized()
	return actualUp.dot(_horizonUp) < 0.0


func should_zoom_in() -> bool:
	return (
		_isZoomInAvailable
		and
		Input.is_action_just_released(action_zoom_in)
	)


func should_zoom_out() -> bool:
	return (
		_isZoomOutAvailable
		and
		Input.is_action_just_released(action_zoom_out)
	)


func should_stabilize_horizon() -> bool:
	return (
		stabilize_horizon
		and
		not should_free_horizon()
	)


func should_free_horizon() -> bool:
	return (
		_isFreeHorizonAvailable
		and
		Input.is_action_pressed(action_free_horizon)
	)


func should_barrel_roll() -> bool:
	return (
		_isBarrelRollAvailable
		and
		Input.is_action_pressed(action_barrel_roll)
	)


func detect_actions_availability():
	_isBarrelRollAvailable = detect_action_availability(action_barrel_roll)
	_isFreeHorizonAvailable = detect_action_availability(action_free_horizon)
	_isZoomInAvailable = detect_action_availability(action_zoom_in)
	_isZoomOutAvailable = detect_action_availability(action_zoom_out)


func detect_action_availability(action: String, silent := false) -> bool:
	if action == "":
		return false
	if ProjectSettings.has_setting("input/%s" % action):
		return true
	if not silent:
		push_warning("%s wants an action named %s.  You can add it quickly by using the buttons in its Inspector." % [get_name(), action])
	return false


# That's all folks!
