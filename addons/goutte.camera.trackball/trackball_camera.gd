## Responds to actions and input from mouse, keyboard, joystick and touch,
## in order to rotate around its parent node while continuously facing it.
extends Camera3D
#class_name TrackballCamera3D

#  _______             _    _           _ _  _____
# |__   __|           | |  | |         | | |/ ____|
#    | |_ __ __ _  ___| | _| |__   __ _| | | |     __ _ _ __ ___  ___ _ __ __ _
#    | | '__/ _` |/ __| |/ / '_ \ / _` | | | |    / _` | '_ ` _ \/ _ \ '__/ _` |
#    | | | | (_| | (__|   <| |_) | (_| | | | |___| (_| | | | | | | __/ | | (_| |
#    |_|_|  \__,_|\___|_|\_\_.__/ \__,_|_|_|\_____\__,_|_| |_| |_|___|_|  \__,_|
#
# Version 8.0
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
# 3. Move your Camera3D so that it looks at that Node (move it along +Z a bit)
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
# Source: https://github.com/Goutte/godot-trackball-camera

@export_group("Horizon")

## Keep the horizon [i](the rotation axis)[/i] stable.
## See also [code]action_free_horizon[/code] to mix up stable and free.
@export var stabilize_horizon := false
## When the horizon is kept stable and pitch is not constrained,
## the user may do headstands and X controls become naturally inverted.
## Enable this property to mitigate that (undesirable) effect.
@export var headstand_invert_x := true

@export_group("Mouse 🐭")

## Should this camera respond to mouse drags (or moves) ?
## Actions from the [code]InputMap[/code] using mouse buttons are unaffected by
## this setting.
@export var mouse_enabled := true
## Invert the intent of all the horizontal mouse movements.
@export var mouse_invert_x := false
## Invert the intent of all the vertical mouse movements.
@export var mouse_invert_y := false
## Coefficient for the intent of mouse movements (both drag and move).
@export var mouse_strength := 1.0
## Disable click&drag and instead move around with the mouse moves.
@export var mouse_move_mode := false

@export_group("Actions")

## Enable support for actions defined below.
@export var action_enabled := true
## Coefficient for the horizontal intent of movement actions.
## Use a negative value to invert the direction of the horizontal intents.
@export var action_strength_x := 1.0
## Coefficient for the vertical intent of movement actions.
## Use a negative value to invert the direction of the vertical intents.
@export var action_strength_y := 1.0
## Name of the action in the [code]InputMap[/code] that should add an upwards
## movement intent to this camera.
## [b]Tip[/b]: set [code]cam_up[/code] here instead of [code]ui_up[/code],
## reload the inspector, and use the button that should appear above this field
## to quickly create a new action with sensible defaults.
@export var action_up := 'ui_up'
## Name of the action in the [code]InputMap[/code] that should add a downwards
## movement intent to this camera.
## [b]Tip[/b]: set [code]cam_down[/code] here instead of [code]ui_down[/code],
## reload the inspector, and use the button that should appear above this field
## to quickly create a new action with sensible defaults.
@export var action_down := 'ui_down'
## Name of the action in the [code]InputMap[/code] that should add an eastwards
## movement intent to this camera.
## [b]Tip[/b]: set [code]cam_right[/code] here instead of [code]ui_right[/code],
## reload the inspector, and use the button that should appear above this field
## to quickly create a new action with sensible defaults.
@export var action_right := 'ui_right'
## Name of the action in the [code]InputMap[/code] that should add a westwards
## movement intent to this camera.
## [b]Tip[/b]: set [code]cam_left[/code] here instead of [code]ui_left[/code],
## reload the inspector, and use the button that should appear above this field
## to quickly create a new action with sensible defaults.
@export var action_left := 'ui_left'
## Name of the action in the [code]InputMap[/code] that should add a movement
## intent inwards, towards the target of this camera.
@export var action_zoom_in := 'cam_zoom_in'
## Name of the action in the [code]InputMap[/code] that should add a movement
## intent outwards, away from the target of this camera.
@export var action_zoom_out := 'cam_zoom_out'
## Name of the action in the [code]InputMap[/code] that should temporarily free
## the horizon during activation.  (right mouse click works well)
## Useful only if [code]stabilize_horizon[/code] is set to [code]true[/code].
@export var action_free_horizon := 'cam_free_horizon'
## Name of the action in the [code]InputMap[/code] that should enable the
## [i]barrel roll mode[/i] for the whole duration of its activation,
## mode in which movement intents are converted to roll rotations.
## The default, generated action uses the middle mouse button for this.
@export var action_barrel_roll := 'cam_barrel_roll'

@export_group("Zoom")

## Enable zoom control, movement towards or away from the target.
@export var zoom_enabled := true
## Coefficient for the intent of zoom actions.
## Use a negative value to invert the direction of zoom intents.
@export var zoom_strength := 1.0
## A minimum worldspace distance between this camera and its target.
@export var zoom_minimum := 1.0
## A maximum worldspace distance between this camera and its target.
@export var zoom_maximum := 100.0
## When zoom inertia gets below this threshold, stop zooming.
@export_range(0.0, 1.0, 0.000001) var zoom_inertia_threshold := 0.0001
## Dampen zoom in when it approaches the minimum (0 = disabled).
@export var zoom_in_dampening := 0.0  # 25.0 works well as a value here

@export_group("Barrel Roll")

## Coefficient applied to all barrel roll intents.
## Use a negative value to invert the intents.
## See also [code]action_barrel_roll[/code].
@export var barrel_roll_strength := 1.0

@export_group("Inertia")

## Care for our friends with motion sickness.
@export var no_drag_inertia := false
## Coefficient applied to all lateral (non-zoom) intents.
@export var inertia_strength := 1.0
## When inertia gets below this threshold, stop the camera.
@export_range(0.0, 1.0, 0.000001) var inertia_threshold := 0.0001
## Fraction of inertia lost on each frame.
@export_range(0.0, 1.0, 0.0001) var friction := 0.07:
	set(value):
		friction = value
		recompute_lubricant_efficiency()


@export_group("Pitch Constraints")

# Needs more work
#export var enable_yaw_limit = true  # left & right
# Limit as fraction of a half-circle = TAU/2 = PI
#export var yaw_limit = 1.0 # (float, 0, 1, 0.005)
## Enable (experimental) pitch limits.  Works best with a stable horizon.
@export var enable_pitch_limit := false  # up & down
## Limit as fraction of a quarter-circle ([code]TAU/4[/code])
@export_range(0.0, 1.0, 0.005) var pitch_up_limit := 1.0
## Limit as fraction of a quarter-circle ([code]TAU/4[/code])
@export_range(0.0, 1.0, 0.005) var pitch_down_limit := 1.0
## Strength of the resistance when approaching a pitch limit.
@export var pitch_limit_strength := 1.0


# Generic constants
const QUARTER_CIRCLE := 0.25 * TAU
const CLOCKWISE_CIRCLE := -TAU
const ZOOM_IN := Vector3.FORWARD
const ABSURD_VECTOR2 := Vector2.INF
const HALF_VECTOR2 := Vector2.ONE * 0.5
const MIRRORED_X := Vector2(-1.0, 1.0)
const MIRRORED_Y := Vector2(1.0, -1.0)
# Internal normalizations to target sane defaults at 1
const ZOOM_STRENGTH_NORMALIZATION := 0.05
const MOUSE_DRAG_STRENGTH_NORMALIZATION := 0.1
const MOUSE_MOVE_STRENGTH_NORMALIZATION := 0.00005
const ACTION_MOVE_STRENGTH_NORMALIZATION := 0.1

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
			MOUSE_MOVE_STRENGTH_NORMALIZATION
		)


func process(delta: float):
	process_mouse(delta)
	process_actions(delta)
	process_zoom(delta)
	process_drag_inertia(delta)
	process_roll_inertia(delta)
	process_zoom_inertia(delta)


func process_mouse(delta: float):
	if mouse_enabled and _mouseDragPosition != ABSURD_VECTOR2:
		var _currentDragPosition := get_mouse_position()
		var intent := _currentDragPosition - _mouseDragPosition
		intent *= mouse_strength * MOUSE_DRAG_STRENGTH_NORMALIZATION
		if mouse_invert_x:
			intent *= Vector2.LEFT
		if mouse_invert_y:
			intent *= Vector2.UP
		add_inertia(intent, (_currentDragPosition - HALF_VECTOR2) * MIRRORED_Y)
		_mouseDragPosition = _currentDragPosition


func process_actions(delta: float):
	if action_enabled:
		var intent := delta * ACTION_MOVE_STRENGTH_NORMALIZATION
		if Input.is_action_pressed(action_up):
			add_inertia(Vector2(
				0.0
				,
				intent
				* Input.get_action_strength(action_up)
				* self.action_strength_y
			))
		if Input.is_action_pressed(action_down):
			add_inertia(Vector2(
				0.0
				,
				intent
				* Input.get_action_strength(action_down)
				* self.action_strength_y
				* -1.0
			))
		if Input.is_action_pressed(action_left):
			add_inertia(Vector2(
				intent
				* Input.get_action_strength(action_left)
				* self.action_strength_x
				,
				0.0
			))
		if Input.is_action_pressed(action_right):
			add_inertia(Vector2(
				intent
				* Input.get_action_strength(action_right)
				* self.action_strength_x
				* -1.0
				,
				0.0
			))


func process_zoom(delta: float):
	if zoom_enabled:
		var intent := self.zoom_strength * ZOOM_STRENGTH_NORMALIZATION
		if should_zoom_in():
			add_zoom_inertia(intent)
		if should_zoom_out():
			add_zoom_inertia(intent * -1.0)


func process_drag_inertia(delta: float):
	var inertia := _dragInertia.length()
	if inertia > self.inertia_threshold:
		apply_rotation_from_tangent(_dragInertia * inertia_strength)
		apply_drag_friction()
	else:
		_dragInertia.x = 0
		_dragInertia.y = 0


func process_roll_inertia(delta: float):
	#var roll_inertia_intensity : float = float(abs(_rollInertia) as float) as float
	if abs(_rollInertia) > inertia_threshold:
		apply_barrel_roll(_rollInertia * inertia_strength)
		apply_roll_friction()
	else:
		_rollInertia = 0


func process_zoom_inertia(delta: float):
	# This whole function is … bouerk.  Please share your improvements!
	var cpl := get_distance_to_target()
	if abs(_zoomInertia) > zoom_inertia_threshold:
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
# Y is UP.  The origin is in the center of the screen.
func add_inertia(inertia: Vector2, origin := Vector2.ZERO):
	if should_barrel_roll():
		var rolling := inertia.length() * self.barrel_roll_strength
		if origin == Vector2.ZERO:
			if inertia.dot(Vector2.RIGHT + Vector2.UP) < 0:
				_rollInertia += rolling
			else:
				_rollInertia -= rolling
		else:
			if (inertia * MIRRORED_X).angle_to(-origin) < 0:
				_rollInertia -= rolling
			else:
				_rollInertia += rolling
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
# You can safely edit the input on_transform, or make a new one.
func apply_constraints(on_transform: Transform3D) -> Transform3D:
	if self.enable_pitch_limit and not should_free_horizon():
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
			* self.pitch_limit_strength  # user-defined (exported) scaling
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


func apply_rotation_from_tangent(tangent: Vector2):
	var tr := get_transform()
	var up: Vector3

	if should_stabilize_horizon():
		up = _horizonUp
		if self.headstand_invert_x and is_in_headstand():
			tangent.x *= -1.0
	else:
		up = tr.basis * _cameraUp.normalized()
		update_horizon(up)

	var rg := tr.basis * _cameraRight.normalized()
	var upQuat := Quaternion(up, tangent.x * CLOCKWISE_CIRCLE)
	var rgQuat := Quaternion(rg, tangent.y * CLOCKWISE_CIRCLE)
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


func is_in_headstand() -> bool:
	var actualUp := get_transform().basis * _cameraUp.normalized()
	return actualUp.dot(_horizonUp) < 0.0


func should_zoom_in() -> bool:
	return (
		_isZoomInAvailable
		and
		Input.is_action_just_released(self.action_zoom_in)
	)


func should_zoom_out() -> bool:
	return (
		_isZoomOutAvailable
		and
		Input.is_action_just_released(self.action_zoom_out)
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
		Input.is_action_pressed(self.action_free_horizon)
	)


func should_barrel_roll() -> bool:
	return (
		_isBarrelRollAvailable
		and
		Input.is_action_pressed(self.action_barrel_roll)
	)


func get_mouse_position() -> Vector2:
	return (
		get_viewport().get_mouse_position()
		/
		get_viewport().get_visible_rect().size
	)


func get_distance_to_target() -> float:
	return self.transform.origin.length()


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
		push_warning(
			"%s wants an action named %s.  " +
			"You can add it quickly by using the buttons in its Inspector." %
			[get_name(), action]
		)
	return false


# That's all folks!
