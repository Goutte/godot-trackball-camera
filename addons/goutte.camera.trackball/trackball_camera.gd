extends Camera

# Makes this Camera respond to input from mouse, keyboard, joystick and touch,
# in order to rotate around its parent node while facing it.
# We're using quaternions, so no infamous gimbal lock.
# The camera has (opt-out) inertia for a smoother experience.

# todo: test if touch works on android and html5, try SCREEN_DRAG otherwise
# todo: move to snake_case API to conform with guidelines

# Requirements
# ------------
# Godot `3.1.x` or Godot `3.2.x`.
# Not tested with Godot `4.x`.

# Usage
# -----
# 1. Attach this script to a Camera (or use plugin's TrackballCamera node)
# 2. Move Camera as child of the Node to trackball around
# 3. Make sure your Camera looks at that Node
# Make sure your Camera initially faces said Node, and is at a proper distance from it.
# The initial position of your camera matters. The node does not need to be in the center.

# You can also use this camera to look around you if you place it atop its parent node, spatially.
# It's going to rotate around itself, and that amounts to looking around.
# You'll probably want to set mouseInvert and keyboardInvert to true in that case.

# License
# -------
# Same as Godot, ie. permissive MIT. (https://godotengine.org/license)

# Authors
# -------
# - Ξ 0xB48C3B718a1FF3a280f574Ad36F04068d7EAf498
# - (you <3)

export var mouseEnabled = true
export var mouseInvert = false
export var mouseStrength = 1.111
export var keyboardEnabled = false
export var keyboardInvert = false
export var keyboardStrength = 1.111
export var joystickEnabled = true
export var joystickInvert = false
export var joystickStrength = 1.111
# The resting state of my joystick's x-axis is -0.05,
# so we want to ignore any input below this threshold.
export var joystickThreshold = 0.09
export var joystickDevice = 0
# Use the project's Actions
export var actionEnabled = true
export var actionInvert = false
export var actionUp = 'ui_up'
export var actionDown = 'ui_down'
export var actionRight = 'ui_right'
export var actionLeft = 'ui_left'
export var actionStrength = 1.111

export var zoomEnabled = true
export var zoomInvert = false
export var zoomStrength = 1.111
# There is no default Godot action using mousewheel, so
# you should make your own actions and use them here.
# We're using `action_just_released` to catch mousewheels,
# which makes it a bit awkward for key presses.
export var actionZoomIn = 'ui_page_up'
export var actionZoomOut = 'ui_page_down'

# Multiplier applied to all lateral (non-zoom) inputs
export var inertiaStrength = 1.0
# Fraction of inertia lost on each frame
export(float, 0, 1, 0.005) var friction = 0.07

var _iKnowWhatIAmDoing = false	# should we skip assertions?
var _cameraUp = Vector3(0, 1, 0)
var _cameraRight = Vector3(1, 0, 0)
var _epsilon = 0.0001
var _mouseDragStart
var _mouseDragPosition
var _dragInertia = Vector2(0.0, 0.0)
var _zoomInertia = 0.0


func _ready():
	# Those were required in earlier versions of Godot
	set_process_input(true)
	set_process(true)

	# It's best to catch future divisions by 0 before they happen.
	# Note that we don't need this check if the mouse support is disabled.
	# In case you know what you're doing, there's a property you can change.
	assert(_iKnowWhatIAmDoing or get_viewport().get_visible_rect().get_area())
	#print("Trackball Camera around %s is ready. ♥" % get_parent().get_name())


func _input(ev):
	if mouseEnabled and ev is InputEventMouseButton:
		if ev.pressed:
			_mouseDragStart = getNormalizedMousePosition()
		else:
			_mouseDragStart = null
		_mouseDragPosition = _mouseDragStart


func _process(delta):
	if mouseEnabled and _mouseDragPosition != null:
		var _currentDragPosition = getNormalizedMousePosition()
		_dragInertia += (_currentDragPosition - _mouseDragPosition) \
						* mouseStrength * (-0.1 if mouseInvert else 0.1)
		_mouseDragPosition = _currentDragPosition

	if keyboardEnabled:  # deprecated, use actions
		var key_i = -1 if keyboardInvert else 1
		var key_s = keyboardStrength / 1000.0	# exported floats get truncated
		if Input.is_key_pressed(KEY_LEFT):
			_dragInertia += Vector2(key_i * key_s, 0)
		if Input.is_key_pressed(KEY_RIGHT):
			_dragInertia += Vector2(-1 * key_i * key_s, 0)
		if Input.is_key_pressed(KEY_UP):
			_dragInertia += Vector2(0, key_i * key_s)
		if Input.is_key_pressed(KEY_DOWN):
			_dragInertia += Vector2(0, -1 * key_i * key_s)

	if joystickEnabled:  # deprecated, use actions
		var joy_h = Input.get_joy_axis(joystickDevice, 0)	# left stick horizontal
		var joy_v = Input.get_joy_axis(joystickDevice, 1)	# left stick vertical
		var joy_i = -1 if joystickInvert else 1
		var joy_s = joystickStrength / 1000.0	# exported floats are truncated

		if abs(joy_h) > joystickThreshold:
			_dragInertia += Vector2(joy_i * joy_h * joy_h * sign(joy_h) * joy_s, 0)
		if abs(joy_v) > joystickThreshold:
			_dragInertia += Vector2(0, joy_i * joy_v * joy_v * sign(joy_v) * joy_s)
	
	if actionEnabled:
		# Exported floats are truncated, so we use a bigger number
		var act_s = actionStrength / 1000.0
		var act_i = -1 if actionInvert else 1
		if Input.is_action_pressed(actionUp):
			addInertia(Vector2(0, act_i * act_s))
		if Input.is_action_pressed(actionDown):
			addInertia(Vector2(0, act_i * act_s * -1))
		if Input.is_action_pressed(actionLeft):
			addInertia(Vector2(act_i * act_s, 0))
		if Input.is_action_pressed(actionRight):
			addInertia(Vector2(act_i * act_s * -1, 0))
	
	if zoomEnabled:
		var zoo_s = zoomStrength / 20.0
		var zoo_i = -1 if zoomInvert else 1
		if Input.is_action_just_released(actionZoomIn):
			addZoomInertia(zoo_i * zoo_s)
		if Input.is_action_just_released(actionZoomOut):
			addZoomInertia(zoo_i * zoo_s * -1)
	
	var inertia = _dragInertia.length()
	if inertia > _epsilon:
		applyRotationFromTangent(_dragInertia * inertiaStrength)
		_dragInertia = _dragInertia * (1 - friction)
	elif inertia > 0:
		_dragInertia.x = 0
		_dragInertia.y = 0
	
	if abs(_zoomInertia) > _epsilon:
		applyZoom(_zoomInertia)
		_zoomInertia = _zoomInertia * (1 - friction)
	else:
		_zoomInertia = 0


func addInertia(inertia):
	"""
	Move the camera around.
	inertia:
		a Vector2 in the normalized right-handed x/y of the screen. Y is up.
	"""
	_dragInertia += inertia


func addZoomInertia(inertia):
	_zoomInertia += inertia


func getNormalizedMousePosition():
	return get_viewport().get_mouse_position() / get_viewport().get_visible_rect().size


func applyZoom(amount):
	var delta = Vector3(0, 0, -1)
#	delta *= 0.1
	delta *= amount
	translate(delta)


func applyRotationFromTangent(tangent):
	var tr = get_transform()  # not get_camera_transform, unsure why
	var up = tr.basis.xform(_cameraUp).normalized()
	var rg = tr.basis.xform(_cameraRight).normalized()
	var upQuat = Quat(up, -1 * tangent.x * TAU)
	var rgQuat = Quat(rg, -1 * tangent.y * TAU)
	set_transform(Transform(upQuat * rgQuat) * tr)	# ;p


# That's all folks!
# No-one else contributed to this project, but...
# It helped me discover quaternion fractals.
# ...
# Worth it.
