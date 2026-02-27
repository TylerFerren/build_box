class_name ThirdPersonOrbitCamera
extends Node3D

@export var target_path: NodePath
@export var spring_arm_path: NodePath
@export var orbit_distance: float = 4.0
@export var height_offset: float = 1.5
@export var mouse_sensitivity: float = 0.003
@export var gamepad_sensitivity: float = 2.5
@export_range(-90,0) var minimum_pitch_degrees: float = -45.0
@export_range(0,90) var maximum_pitch_degrees: float = 60.0

@export var invert_vertical_look: bool = true
@export var use_interpolated_target_transform: bool = true
@export var manage_mouse_capture: bool = true
@export_group("Dampening Settings")
@export_range(0.0, 50.0) var follow_position_dampening: float = 16.0
@export_range(0.0, 50.0) var look_rotation_dampening: float = 20.0

@export_group("Mouse Capture Settigns")
@export var capture_mouse_on_ready: bool = true
@export var release_mouse_action: StringName = &"ui_cancel"
@export var recapture_mouse_button: MouseButton = MOUSE_BUTTON_LEFT

var target_node: Node3D
var spring_arm: SpringArm3D
var yaw_radians: float = 0.0
var pitch_radians: float = deg_to_rad(-10.0)
var target_yaw_radians: float = 0.0
var target_pitch_radians: float = deg_to_rad(-10.0)
var accumulated_mouse_look_delta: Vector2 = Vector2.ZERO

func _ready() -> void:
	if target_path != NodePath():
		target_node = get_node_or_null(target_path) as Node3D
	if spring_arm_path != NodePath():
		spring_arm = get_node_or_null(spring_arm_path) as SpringArm3D
	else:
		spring_arm = get_node_or_null("SpringArm3D") as SpringArm3D
	if spring_arm != null:
		spring_arm.spring_length = orbit_distance

	target_yaw_radians = yaw_radians
	target_pitch_radians = pitch_radians

	if manage_mouse_capture and capture_mouse_on_ready:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if manage_mouse_capture:
		_handle_mouse_capture_input(event)
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			return

	if event is InputEventMouseMotion:
		accumulated_mouse_look_delta += event.relative

func _process(delta: float) -> void:
	if target_node == null:
		return

	_update_orbit_angles(delta)
	_update_rig_transform(delta)

func set_target(new_target: Node3D) -> void:
	target_node = new_target

func _update_orbit_angles(delta: float) -> void:
	var look_input_delta := _read_look_input(delta)
	target_yaw_radians -= look_input_delta.x

	var vertical_look_sign := -1.0 if invert_vertical_look else 1.0
	target_pitch_radians = clamp(
		target_pitch_radians + (look_input_delta.y * vertical_look_sign),
		deg_to_rad(minimum_pitch_degrees),
		deg_to_rad(maximum_pitch_degrees)
	)

func _read_look_input(delta: float) -> Vector2:
	var look_input_delta := accumulated_mouse_look_delta * mouse_sensitivity
	accumulated_mouse_look_delta = Vector2.ZERO

	if _has_gamepad_look_actions():
		var gamepad_look := Input.get_vector("look_left", "look_right", "look_up", "look_down")
		look_input_delta += gamepad_look * gamepad_sensitivity * delta

	return look_input_delta

func _has_gamepad_look_actions() -> bool:
	return (
		InputMap.has_action("look_left")
		and InputMap.has_action("look_right")
		and InputMap.has_action("look_up")
		and InputMap.has_action("look_down")
	)

func _update_rig_transform(delta: float) -> void:
	if spring_arm != null:
		spring_arm.spring_length = orbit_distance

	var target_transform := _get_target_render_transform()
	var target_up_vector := target_transform.basis.y.normalized()
	var desired_position := target_transform.origin + (target_up_vector * height_offset)
	var position_lerp_weight : float = clamp(follow_position_dampening * delta, 0.0, 1.0)
	global_position = global_position.lerp(desired_position, position_lerp_weight)

	var rotation_lerp_weight : float = clamp(look_rotation_dampening * delta, 0.0, 1.0)
	yaw_radians = lerp_angle(yaw_radians, target_yaw_radians, rotation_lerp_weight)
	pitch_radians = lerp_angle(pitch_radians, target_pitch_radians, rotation_lerp_weight)
	rotation = Vector3(pitch_radians, yaw_radians, 0.0)

func _get_target_render_transform() -> Transform3D:
	if use_interpolated_target_transform and target_node.has_method("get_global_transform_interpolated"):
		return target_node.get_global_transform_interpolated()
	return target_node.global_transform

func _handle_mouse_capture_input(event: InputEvent) -> void:
	if event.is_action_pressed(release_mouse_action):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	if event is InputEventMouseButton:
		var mouse_button_event := event as InputEventMouseButton
		if (
			mouse_button_event.pressed
			and mouse_button_event.button_index == recapture_mouse_button
			and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED
		):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
