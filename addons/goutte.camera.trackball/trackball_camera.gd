extends Camera

# Makes this Camera respond to input from mouse, keyboard, joystick and touch(?),
# in order to rotate around its parent node while facing it.
# We're using quaternions, so no infamous gimbal lock.
# The camera has (an opt-out) inertia for a smoother experience.
#
# todo: use SCREEN_DRAG for pinch zoom
# todo: port to Godot 4 (soon)
#
#
# Requirements
# ------------
# Godot `3.1.x` or Godot `3.2.x` or Godot `3.3.x` or Godot `3.4.x`.
# Not tested with Godot `4.x`. (won't work -- needs refacto)
#
#
# Usage
# -----
# 1. Attach this script to a Camera (or use plugin's TrackballCamera node)
# 2. Move Camera as child of the Node to trackball around
# 3. Move your Camera so that it looks at that Node (translate it along +z a bit)
# The initial position of your camera matters. The node does not need to be in the center.
#
#
# First-Person
# ------------
# You can also use this camera to look around you if you place it atop its parent node, spatially.
# It's going to rotate around itself, and that amounts to looking around.
# You'll probably want to set mouse_invert and keyboard_invert to true in that case.
# You can also override apply_constraints()
# and call apply_updown_constraint()
#
#
# License
# -------
# Same as Godot, ie. permissive MIT. (https://godotengine.org/license)


# Keep the horizon stable, the UP to Y
# See also action_free_horizon
export var stabilize_horizon := false

# Only used if horizon is kept stable
export var headstand_invert_x := true

export var mouse_enabled := true
export var mouse_invert := false
export var mouse_strength := 1.0
# If true will disable click+drag and move around with the mouse moves
export var mouse_move_mode := false
# Directly bound keyboard is deprecated, use actions instead
export var keyboard_enabled := false
export var keyboard_invert := false
export var keyboard_strength := 1.0
# Directly bound joystick is deprecated, use actions instead
export var joystick_enabled := true
export var joystick_invert := false
export var joystick_strength := 1.0
# The resting state of my joystick's x-axis is -0.05,
# so we want to ignore any input below this threshold.
export var joystick_threshold := 0.09
export var joystick_device := 0
# Use the project's Actions
export var action_enabled := true
export var action_invert := false
export var action_up := 'ui_up'
export var action_down := 'ui_down'
export var action_right := 'ui_right'
export var action_left := 'ui_left'
export var action_strength := 1.0
# There is no default Godot action using mousewheel, so
# you should make your own actions and use them here.
# We usually use "cam_zoom_in" and "cam_zoom_out".
# Perhaps the plugin itself could add those actions…
# We're using `action_just_released` to catch mousewheels properly,
# which makes it a bit awkward for key presses.
export var action_zoom_in := 'ui_page_up'
export var action_zoom_out := 'ui_page_down'
export var action_free_horizon := 'cam_free_horizon'

export var zoom_enabled := true
export var zoom_invert := false
export var zoom_strength := 1.0
# As worldspace distances between the camera and its target
export var zoom_minimum := 3.0
export var zoom_maximum := 90.0

# When zoom inertia gets below this treshold, stop zooming
export(float, 0.0, 1.0, 0.000001) var zoom_inertia_treshold = 0.0001
# Dampen zoom in when it approaches the minimum (0 = disabled)
export var zoom_in_dampening := 0.0  # 25.0 works well as a value here

# Multiplier applied to all lateral (non-zoom) inputs
export var inertia_strength := 1.0
# When inertia gets below this treshold, stop the camera
export(float, 0.0, 1.0, 0.000001) var inertia_treshold = 0.0001
# Fraction of inertia lost on each frame
export(float, 0, 1, 0.005) var friction := 0.07


# Needs more work
#export var enable_yaw_limit = true  # left & right
# Limit as fraction of a half-circle = TAU/2 = PI
#export(float, 0, 1, 0.005) var yaw_limit = 1.0

export var enable_pitch_limit := false  # up & down
# Limits as fraction of a quarter-circle (TAU/4)
export(float, 0, 1, 0.005) var pitch_up_limit := 1.0
export(float, 0, 1, 0.005) var pitch_down_limit := 1.0
export(float, 0, 100, 0.05) var pitch_limit_strength := 1.0


const QUARTER_CIRCLE := TAU / 4.0
const ZOOM_IN := Vector3.FORWARD
#const HORIZON_NORMAL := Vector3.UP


var _iKnowWhatIAmDoing := false	# lesswrong.org
var _horizonUp := Vector3.UP
var _cameraUp := Vector3.UP
var _cameraRight := Vector3.RIGHT
var _epsilon := 0.0001
var _mouseDragStart := Vector2.INF  # set but unused ; make public or remove?
var _mouseDragPosition := Vector2.INF
var _dragInertia := Vector2.ZERO
var _zoomInertia := 0.0


func _ready():  # this allows overriding through inheritance
	ready()


func _input(event: InputEvent):  # this allows overriding through inheritance
	input(event)


func _process(delta: float):  # this allows overriding through inheritance
	process(delta)


func ready():
	# Those were required in earlier versions of Godot
	set_process_input(true)
	set_process(true)

	# It's best to catch future divisions by 0 before they happen.
	# Note that we don't need this check if the mouse support is disabled.
	# In case you know what you're doing, there's a property you can change.
	assert(_iKnowWhatIAmDoing or get_viewport().get_visible_rect().get_area())
	#print("Trackball Camera around %s is ready. ♥" % get_parent().get_name())


func input(event: InputEvent):
	if mouse_enabled:
		handle_mouse_input(event)


func handle_mouse_input(event: InputEvent):
	if (not mouse_move_mode) and (event is InputEventMouseButton):
		if event.pressed:
			_mouseDragStart = get_mouse_position()
		else:
			_mouseDragStart = Vector2.INF
		_mouseDragPosition = _mouseDragStart
	if (mouse_move_mode) and (event is InputEventMouseMotion):
		add_inertia(event.relative * mouse_strength * 0.00005)


func process(delta: float):
	process_mouse(delta)
	process_keyboard(delta)
	process_joystick(delta)
	process_actions(delta)
	process_zoom(delta)
	process_drag_inertia(delta)
	process_zoom_inertia(delta)


func process_mouse(delta: float):
	if mouse_enabled and _mouseDragPosition != Vector2.INF:
		var _currentDragPosition = get_mouse_position()
		add_inertia((
			(_currentDragPosition - _mouseDragPosition)
			* mouse_strength * (-0.1 if mouse_invert else 0.1)
		))
		_mouseDragPosition = _currentDragPosition


func process_keyboard(delta: float):  # deprecated, use actions
	if keyboard_enabled:
		var key_s := keyboard_strength / 1000.0	# exported floats get truncated
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
		var joy_h := Input.get_joy_axis(joystick_device, 0)  # left stick horizontal
		var joy_v := Input.get_joy_axis(joystick_device, 1)  # left stick vertical
		var joy_s := joystick_strength / 1000.0  # exported floats are truncated
		joy_s *= -1.0 if joystick_invert else 1.0

		if abs(joy_h) > joystick_threshold:
			add_inertia(Vector2(joy_h * joy_h * sign(joy_h) * joy_s, 0.0))
		if abs(joy_v) > joystick_threshold:
			add_inertia(Vector2(0.0, joy_v * joy_v * sign(joy_v) * joy_s))


func process_actions(delta: float):
	if action_enabled:
		# Exported floats are truncated, so we use a bigger number
		var act_s := action_strength / 1000.0
		act_s *= -1.0 if action_invert else 1.0
		if Input.is_action_pressed(action_up):
			var analog := Input.get_action_strength(action_up)
			add_inertia(Vector2(0.0, act_s * analog))
		if Input.is_action_pressed(action_down):
			var analog := Input.get_action_strength(action_down)
			add_inertia(Vector2(0.0, act_s * analog * -1.0))
		if Input.is_action_pressed(action_left):
			var analog := Input.get_action_strength(action_left)
			add_inertia(Vector2(act_s * analog, 0.0))
		if Input.is_action_pressed(action_right):
			var analog := Input.get_action_strength(action_right)
			add_inertia(Vector2(act_s * analog * -1.0, 0.0))


func process_zoom(delta: float):
	if zoom_enabled:
		var zoo_s := zoom_strength / 20.0
		zoo_s *= -1.0 if zoom_invert else 1.0
		if Input.is_action_just_released(action_zoom_in):
			add_zoom_inertia(zoo_s)
		if Input.is_action_just_released(action_zoom_out):
			add_zoom_inertia(zoo_s * -1.0)


func process_drag_inertia(delta: float):
	var inertia := _dragInertia.length()
	#assert(inertia > 0, "Can this even happen? → no, unless cosmic rays")
	if inertia > inertia_treshold:
		apply_rotation_from_tangent(_dragInertia * inertia_strength)
		apply_drag_friction()
	else:
		_dragInertia.x = 0
		_dragInertia.y = 0


func process_zoom_inertia(delta: float):
	# This whole function is … bouerk.  Please share your improvements!
	var cpl := get_distance_to_target()
	if abs(_zoomInertia) > zoom_inertia_treshold:
		if cpl < zoom_minimum:
			if _zoomInertia > 0.0:
				_zoomInertia *= max(0, 1 - (1.333 * (zoom_minimum - cpl) / zoom_minimum))
			_zoomInertia = _zoomInertia - 0.1 * (zoom_minimum - cpl) / zoom_minimum
		if cpl > zoom_maximum:
			_zoomInertia += 0.09 * exp((cpl - zoom_maximum) * 3 + 1) * (cpl - zoom_maximum) * (cpl - zoom_maximum)
		apply_zoom(_zoomInertia)
		apply_zoom_friction()
	else:
		_zoomInertia = 0.0


# Moves the camera around.
# inertia is a Vector2 in the normalized right-handed x/y of the screen.
# Y is up.
func add_inertia(inertia: Vector2):
	_dragInertia += inertia


# Moves the camera towards its target, or away from if inertia is negative.
func add_zoom_inertia(inertia: float):
	if zoom_in_dampening > 0.0 and inertia > 0.0:
		var delta := abs(get_distance_to_target() - zoom_minimum)
		var brake := pow(zoom_in_dampening, -1.0 * delta + 1.0) + 1.0
		inertia /= brake
	_zoomInertia += inertia


func apply_zoom(amount: float):
	translate(ZOOM_IN * amount)


# Override this method to apply your custom constraints.
# You can both edit the on_transform or make a new one.
# It's usually faster to edit than create ; perhaps not in Godot (COW?)
func apply_constraints(on_transform: Transform) -> Transform:
	if enable_pitch_limit:
		on_transform = apply_pitch_constraint(on_transform)
	return on_transform


func apply_pitch_constraint(on_transform: Transform) -> Transform:
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
func apply_updown_constraint(on_transform: Transform, limit := 0.75) -> Transform:
	var eulers: Vector3 = on_transform.basis.get_euler()
	eulers.x = clamp(eulers.x, -limit, limit)
	eulers.z = 0.0
	on_transform.basis = Basis(Quat(eulers))
	return on_transform


func apply_rotation_from_tangent(tangent: Vector2):
	var tr := get_transform()
	var up: Vector3
	if should_stabilize_horizon():
		up = _horizonUp
		if headstand_invert_x and is_in_headstand():
			tangent.x *= -1.0
	else:
		up = tr.basis.xform(_cameraUp).normalized()
		update_horizon(up)
	var rt := tr.basis.xform(_cameraRight).normalized()
	var upQuat := Quat(up, -1.0 * tangent.x * TAU)
	var rgQuat := Quat(rt, -1.0 * tangent.y * TAU)
	var rotatedTransform := Transform(upQuat * rgQuat) * tr
	set_transform(apply_constraints(rotatedTransform))


func apply_drag_friction():
	_dragInertia = _dragInertia * (1 - friction)


func apply_zoom_friction():
	_zoomInertia = _zoomInertia * (1 - friction)


func get_mouse_position() -> Vector2:
	return (
		get_viewport().get_mouse_position()
		/
		get_viewport().get_visible_rect().size
	)


func get_distance_to_target() -> float:
	return transform.origin.length()


func is_in_headstand() -> bool:
	var actualUp := get_transform().basis.xform(_cameraUp).normalized()
	return actualUp.dot(_horizonUp) < 0.0


func should_stabilize_horizon() -> bool:
	return (
		stabilize_horizon
		and
		not Input.is_action_pressed(action_free_horizon)
	)


# better UX when mixing stable & regular ; override to pass if unwanted
func update_horizon(new_up: Vector3):
	_horizonUp = new_up


# That's all folks!
