extends Camera

# Makes this Camera respond to input from mouse, keyboard, joystick and touch(?),
# in order to rotate around its parent node while facing it.
# We're using quaternions, so no infamous gimbal lock.
# The camera has (an opt-out) inertia for a smoother experience.

# todo: test if touch works on android and html5, try SCREEN_DRAG otherwise
# todo: type everything (bc break, but which version?)

# Requirements
# ------------
# Godot `3.1.x` or Godot `3.2.x`.
# Not tested with Godot `4.x`.

# Usage
# -----
# 1. Attach this script to a Camera (or use plugin's TrackballCamera node)
# 2. Move Camera as child of the Node to trackball around
# 3. Move your Camera so that it looks at that Node (translate it along +z a bit)
# The initial position of your camera matters. The node does not need to be in the center.

# First-Person
# ------------
# You can also use this camera to look around you if you place it atop its parent node, spatially.
# It's going to rotate around itself, and that amounts to looking around.
# You'll probably want to set mouse_invert and keyboard_invert to true in that case.
# You can also override apply_constraints()
# and call apply_updown_constraint()

# License
# -------
# Same as Godot, ie. permissive MIT. (https://godotengine.org/license)

# Authors
# -------
# - (you <3)

# Keep the horizon stable, the UP to Y
export var stabilize_horizon = false
export var mouse_enabled = true
export var mouse_invert = false
export var mouse_strength = 1.0
# If true will disable click+drag and move around with the mouse moves
export var mouse_move_mode = false
# Directly bound keyboard is deprecated, use actions instead
export var keyboard_enabled = false
export var keyboard_invert = false
export var keyboard_strength = 1.0
# Directly bound joystick is deprecated, use actions instead
export var joystick_enabled = true
export var joystick_invert = false
export var joystick_strength = 1.0
# The resting state of my joystick's x-axis is -0.05,
# so we want to ignore any input below this threshold.
export var joystick_threshold = 0.09
export var joystick_device = 0
# Use the project's Actions
export var action_enabled = true
export var action_invert = false
export var action_up = 'ui_up'
export var action_down = 'ui_down'
export var action_right = 'ui_right'
export var action_left = 'ui_left'
export var action_strength = 1.0

export var zoom_enabled = true
export var zoom_invert = false
export var zoom_strength = 1.0
# As distances between the camera and its target
export var zoom_minimum = 3
export var zoom_maximum = 90.0
export(float, 0.0, 1.0, 0.000001) var zoomInertiaTreshold = 0.0001

# There is no default Godot action using mousewheel, so
# you should make your own actions and use them here.
# We usually use "cam_zoom_in" and "cam_zoom_out".
# Perhaps the plugin could add those…
# We're using `action_just_released` to catch mousewheels properly,
# which makes it a bit awkward for key presses.
export var action_zoom_in = 'ui_page_up'
export var action_zoom_out = 'ui_page_down'

# Multiplier applied to all lateral (non-zoom) inputs
export var inertia_strength = 1.0
# When inertia gets below this treshold, stop the camera
export(float, 0.0, 1.0, 0.000001) var inertiaTreshold = 0.0001
# Fraction of inertia lost on each frame
export(float, 0.0, 1.0, 0.005) var friction = 0.07



#export var enable_yaw_limit = true  # left & right
# Limit as fraction of a half-circle = TAU/2 = PI
#export(float, 0, 1, 0.005) var yaw_limit = 1.0

export var enable_pitch_limit = false  # up & down
# Limits as fraction of a quarter-circle = TAU/4
export(float, 0, 1, 0.005) var pitch_up_limit = 1.0
export(float, 0, 1, 0.005) var pitch_down_limit = 1.0
export(float, 0, 100, 0.05) var pitch_limit_strength = 1.0


# If you need those as exported variables, it can happen
const ZOOM_IN = Vector3.FORWARD
const HORIZON_NORMAL = Vector3.UP
const QUARTER_CIRCLE = 0.25 * TAU

var _iKnowWhatIAmDoing = false	# lesswrong.org
var _cameraUp = Vector3.UP
var _cameraRight = Vector3.RIGHT
var _mouseDragStart
var _mouseDragPosition
var _dragInertia = Vector2.ZERO
var _zoomInertia = 0.0
var _referenceTransform


func _ready():  # this allows overriding through inheritance
	ready()
#	set_reference_transform(self.transform)


func _input(event):  # this allows overriding through inheritance
	input(event)


func ready():
	# Those were required in earlier versions of Godot
	set_process_input(true)
	set_process(true)

	# It's best to catch future divisions by 0 before they happen.
	# Note that we don't need this check if the mouse support is disabled.
	# In case you know what you're doing, there's a property you can change.
	assert(_iKnowWhatIAmDoing or get_viewport().get_visible_rect().get_area())
	#print("Trackball Camera around %s is ready. ♥" % get_parent().get_name())


func input(event):
	if mouse_enabled:
		handle_mouse_input(event)


# @deprecated : will be removed in next BC break (version 6)
func handle_input_mouse(event):
	printerr("Method handle_input_mouse() is deprecated.  Use handle_mouse_input() instead.")
	handle_mouse_input(event)


func handle_mouse_input(event):
	if (not mouse_move_mode) and (event is InputEventMouseButton):
		if event.pressed:
			_mouseDragStart = get_mouse_position()
		else:
			_mouseDragStart = null
		_mouseDragPosition = _mouseDragStart
	if (mouse_move_mode) and (event is InputEventMouseMotion):
		add_inertia(event.relative * mouse_strength * 0.00005)


func _process(delta):
	process_mouse(delta)
	process_keyboard(delta)
	process_joystick(delta)
	process_actions(delta)
	process_zoom(delta)
	process_drag_inertia(delta)
	process_zoom_inertia(delta)


func process_mouse(delta):
	if mouse_enabled and _mouseDragPosition != null:
		var _currentDragPosition = get_mouse_position()
		add_inertia(
			(_currentDragPosition - _mouseDragPosition) \
			* mouse_strength * (-0.1 if mouse_invert else 0.1))
		_mouseDragPosition = _currentDragPosition


func process_keyboard(delta):  # deprecated, use actions
	if keyboard_enabled:
		var key_i = -1 if keyboard_invert else 1
		var key_s = keyboard_strength / 1000.0	# exported floats get truncated
		if Input.is_key_pressed(KEY_LEFT):
			add_inertia(Vector2(key_i * key_s, 0))
		if Input.is_key_pressed(KEY_RIGHT):
			add_inertia(Vector2(-1 * key_i * key_s, 0))
		if Input.is_key_pressed(KEY_UP):
			add_inertia(Vector2(0, key_i * key_s))
		if Input.is_key_pressed(KEY_DOWN):
			add_inertia(Vector2(0, -1 * key_i * key_s))


func process_joystick(delta):  # deprecated, use actions
	if joystick_enabled:
		var joy_h = Input.get_joy_axis(joystick_device, 0)	# left stick horizontal
		var joy_v = Input.get_joy_axis(joystick_device, 1)	# left stick vertical
		var joy_i = -1 if joystick_invert else 1
		var joy_s = joystick_strength / 1000.0	# exported floats are truncated

		if abs(joy_h) > joystick_threshold:
			add_inertia(Vector2(joy_i * joy_h * joy_h * sign(joy_h) * joy_s, 0))
		if abs(joy_v) > joystick_threshold:
			add_inertia(Vector2(0, joy_i * joy_v * joy_v * sign(joy_v) * joy_s))


func process_actions(delta):
	if action_enabled:
		# Exported floats are truncated, so we use a bigger number
		var act_s:float
		var act_i = -1 if action_invert else 1
		if Input.is_action_pressed(action_up):
			act_s = Input.get_action_strength(action_up) * action_strength / 1000.0
			add_inertia(Vector2(0, act_i * act_s))
		if Input.is_action_pressed(action_down):
			act_s = Input.get_action_strength(action_down) * action_strength / 1000.0
			add_inertia(Vector2(0, act_i * act_s * -1))
		if Input.is_action_pressed(action_left):
			act_s = Input.get_action_strength(action_left) * action_strength / 1000.0
			add_inertia(Vector2(act_i * act_s, 0))
		if Input.is_action_pressed(action_right):
			act_s = Input.get_action_strength(action_right) * action_strength / 1000.0
			add_inertia(Vector2(act_i * act_s * -1, 0))


func process_zoom(delta):
	if zoom_enabled:
		var zoo_s = zoom_strength / 20.0
		var zoo_i = -1 if zoom_invert else 1
		if Input.is_action_just_released(action_zoom_in):
			add_zoom_inertia(zoo_i * zoo_s)
		if Input.is_action_just_released(action_zoom_out):
			add_zoom_inertia(zoo_i * zoo_s * -1)


func process_drag_inertia(delta):
	var inertia = _dragInertia.length()
	if inertia > inertiaTreshold:
		apply_rotation_from_tangent(_dragInertia * inertia_strength)
		_dragInertia = _dragInertia * (1 - friction)
	elif inertia > 0:
		_dragInertia.x = 0
		_dragInertia.y = 0


func process_zoom_inertia(delta):
	# This whole function is … bouerk.  Please share your improvements!
	var currentPosition = transform.origin
	var cpl = currentPosition.length()
	if abs(_zoomInertia) > zoomInertiaTreshold:
		if cpl < zoom_minimum:
			if _zoomInertia > 0:
				_zoomInertia *= max(0, 1 - (1.333 * (zoom_minimum - cpl) / zoom_minimum))
			_zoomInertia = _zoomInertia - 0.1 * (zoom_minimum - cpl) / zoom_minimum
		if cpl > zoom_maximum:
			_zoomInertia += 0.09 * exp((cpl - zoom_maximum) * 3 + 1) * (cpl - zoom_maximum) * (cpl - zoom_maximum)
		apply_zoom(_zoomInertia)
		_zoomInertia = _zoomInertia * (1 - friction)
	else:
		_zoomInertia = 0


#func set_reference_transform(reference_transform):
#	"""
#	Set a new reference transform, for the yaw and pitch limits.
#	"""
#	_referenceTransform = reference_transform
#	prints("Reference Basis", _referenceTransform.basis)
#	prints("Reference Origin", _referenceTransform.origin)
#	prints("Reference Quat", Quat(_referenceTransform.basis))
#	prints("Reference Quat Normalized", Quat(_referenceTransform.basis).normalized())


func add_inertia(inertia):
	"""
	Move the camera around.
	inertia:
		a Vector2 in the normalized right-handed x/y of the screen. Y is up.
	"""
	_dragInertia += inertia


func add_zoom_inertia(inertia):
	_zoomInertia += inertia


func apply_zoom(amount):
	translate(ZOOM_IN * amount)


# Override this method to apply your custom constraints.
# You can both edit the on_transform or make a new one.
# It's usually faster to edit than create.
# You need to return a Transform in all cases.
func apply_constraints(on_transform):
	if enable_pitch_limit:
		on_transform = apply_pitch_constraint(on_transform)
	return on_transform


func apply_pitch_constraint(on_transform):
	var eulers = on_transform.basis.get_euler()
	
	var dxu = QUARTER_CIRCLE * pitch_up_limit + eulers.x
	var dxd = QUARTER_CIRCLE * pitch_down_limit - eulers.x
	var limit_will = 0
	var limit_over = 0
	if (dxu < 0):
		limit_will = 1
		limit_over = dxu
	if (dxd < 0):
		limit_will = -1
		limit_over = dxd
	if 0 != limit_will:
		_dragInertia.y = 0.0
#		_dragInertia *= 0.618
		var resistance_strength = (((1 - limit_over) * (1 - limit_over)) - 1)
		
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
func apply_updown_constraint(on_transform, limit=0.75):
	var eulers = on_transform.basis.get_euler()
	eulers.x = clamp(eulers.x, -limit, limit)
	eulers.z = 0.0
	on_transform.basis = Basis(Quat(eulers))
	return on_transform


func apply_rotation_from_tangent(tangent):
	var tr = get_transform()
	var up
	if self.stabilize_horizon:
		up = HORIZON_NORMAL
	else:
		up = tr.basis.xform(_cameraUp).normalized()
	var rg = tr.basis.xform(_cameraRight).normalized()
	var upQuat = Quat(up, -1 * tangent.x * TAU)
	var rgQuat = Quat(rg, -1 * tangent.y * TAU)
	var rotated_transform = Transform(upQuat * rgQuat) * tr
	set_transform(apply_constraints(rotated_transform))


func get_mouse_position():
	return (
		get_viewport().get_mouse_position()
		/
		get_viewport().get_visible_rect().size
	)

# That's all folks!
