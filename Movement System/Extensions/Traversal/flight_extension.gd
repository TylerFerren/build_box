class_name Flight
extends MovementExtension

enum FlightState {HOVER, CRUISE}

@export_group("Flight Speeds")
@export var horizontal_flight_speed: float = 9.0
@export var vertical_flight_speed: float = 6.0
@export var acceleration_speed: float = 18.0
@export var deceleration_speed: float = 14.0
@export var cruise_forward_speed: float = 11.0
@export var use_move_axis_for_vertical_in_cruise: bool = true
@export var cruise_forward_smoothing_speed: float = 7.0

@export_group("Input")
@export var use_move_axis_for_vertical_in_hover: bool = false

@export_group("Mode")
@export var flight_mode_name: StringName = MovementModeNames.FLYING
@export var walking_mode_name: StringName = MovementModeNames.WALKING
@export var auto_land_when_grounded: bool = false
@export var default_flight_state: FlightState = FlightState.HOVER

signal flight_entered
signal flight_exited
signal flight_state_changed(current_state: FlightState)

var requested_toggle: bool = false
var requested_state_transition: bool = false
var ascend_input_held: bool = false
var descend_input_held: bool = false
var current_flight_velocity: Vector3 = Vector3.ZERO
var current_flight_state: FlightState = FlightState.HOVER
var smoothed_cruise_forward: Vector3 = Vector3.ZERO
var default_horizontal_flight_speed: float = 0.0
var default_vertical_flight_speed: float = 0.0
var default_acceleration_speed: float = 0.0
var default_deceleration_speed: float = 0.0
var default_cruise_forward_speed: float = 0.0
var default_use_move_axis_for_vertical_in_cruise: bool = true
var default_cruise_forward_smoothing_speed: float = 0.0
var default_use_move_axis_for_vertical_in_hover: bool = false
var default_auto_land_when_grounded: bool = false
var default_flight_state_value: FlightState = FlightState.HOVER

func _ready() -> void:
	blend_mode = MovementExtension.ExtensionBlendMode.OVERRIDING
	default_horizontal_flight_speed = horizontal_flight_speed
	default_vertical_flight_speed = vertical_flight_speed
	default_acceleration_speed = acceleration_speed
	default_deceleration_speed = deceleration_speed
	default_cruise_forward_speed = cruise_forward_speed
	default_use_move_axis_for_vertical_in_cruise = use_move_axis_for_vertical_in_cruise
	default_cruise_forward_smoothing_speed = cruise_forward_smoothing_speed
	default_use_move_axis_for_vertical_in_hover = use_move_axis_for_vertical_in_hover
	default_auto_land_when_grounded = auto_land_when_grounded
	default_flight_state_value = default_flight_state

	request_active_state(false)
	current_flight_state = default_flight_state

func on_flight_toggle_pressed() -> void:
	requested_toggle = true

func on_flight_state_transition_pressed() -> void:
	requested_state_transition = true

func on_ascend_pressed() -> void:
	ascend_input_held = true

func on_ascend_released() -> void:
	ascend_input_held = false

func on_descend_pressed() -> void:
	descend_input_held = true

func on_descend_released() -> void:
	descend_input_held = false

func update_extension_state(movement_state: MovementState, _delta: float) -> void:
	if requested_toggle:
		_toggle_flight_mode()
	requested_toggle = false

	var is_in_flight_mode := movement_state.current_mode == flight_mode_name
	if auto_land_when_grounded and is_in_flight_mode and movement_state.is_grounded:
		_set_mode_if_possible(walking_mode_name)
		is_in_flight_mode = false

	if is_in_flight_mode and requested_state_transition:
		_toggle_flight_state()
	requested_state_transition = false

	if is_in_flight_mode and not is_active:
		current_flight_state = default_flight_state
		flight_entered.emit()
	elif not is_in_flight_mode and is_active:
		flight_exited.emit()

	request_active_state(is_in_flight_mode)
	if not is_active:
		current_flight_velocity = Vector3.ZERO
		smoothed_cruise_forward = Vector3.ZERO
		ascend_input_held = false
		descend_input_held = false

func get_movement_velocity(movement_state: MovementState, delta: float) -> Vector3:
	if not is_active:
		return Vector3.ZERO

	var horizontal_forward_input := movement_state.move_input.y
	if current_flight_state == FlightState.CRUISE and use_move_axis_for_vertical_in_cruise:
		# In cruise with vertical-on-move-axis enabled, treat move Y as vertical only.
		horizontal_forward_input = 0.0

	var input_direction := Vector3(movement_state.move_input.x, 0.0, horizontal_forward_input)
	var camera_relative_direction := manager.get_camera_relative_input(input_direction)
	camera_relative_direction = camera_relative_direction.slide(movement_state.up_direction)

	var horizontal_direction := Vector3.ZERO
	if camera_relative_direction.length_squared() > 0.0:
		horizontal_direction = camera_relative_direction.normalized()

	var vertical_input: float = 0.0
	if current_flight_state == FlightState.CRUISE and use_move_axis_for_vertical_in_cruise:
		vertical_input = -movement_state.move_input.y
	elif current_flight_state == FlightState.HOVER and use_move_axis_for_vertical_in_hover:
		vertical_input = -movement_state.move_input.y
	else:
		if ascend_input_held:
			vertical_input += 1.0
		if descend_input_held:
			vertical_input -= 1.0

	var target_velocity := (horizontal_direction * horizontal_flight_speed * movement_state.speed_multiplier)
	if current_flight_state == FlightState.CRUISE:
		var desired_cruise_forward := _get_desired_cruise_forward(movement_state)
		if desired_cruise_forward.length_squared() > 0.0:
			if smoothed_cruise_forward.length_squared() <= 0.0:
				smoothed_cruise_forward = desired_cruise_forward
			else:
				var blend_weight : float = clamp(cruise_forward_smoothing_speed * delta, 0.0, 1.0)
				smoothed_cruise_forward = smoothed_cruise_forward.lerp(desired_cruise_forward, blend_weight)
				if smoothed_cruise_forward.length_squared() > 0.0:
					smoothed_cruise_forward = smoothed_cruise_forward.normalized()

			target_velocity += smoothed_cruise_forward * cruise_forward_speed * movement_state.speed_multiplier

	target_velocity += movement_state.up_direction.normalized() * (vertical_input * vertical_flight_speed)

	var has_target_velocity := target_velocity.length_squared() > 0.0001
	var blend_speed := acceleration_speed if has_target_velocity else deceleration_speed
	current_flight_velocity = current_flight_velocity.move_toward(target_velocity, blend_speed * delta)
	return current_flight_velocity

func _toggle_flight_mode() -> void:
	if manager == null:
		return

	if manager.current_mode == flight_mode_name:
		_set_mode_if_possible(walking_mode_name)
	else:
		_set_mode_if_possible(flight_mode_name)

func _set_mode_if_possible(mode_name: StringName) -> void:
	if manager == null:
		return
	manager.request_mode_change(mode_name)

func _toggle_flight_state() -> void:
	if current_flight_state == FlightState.HOVER:
		current_flight_state = FlightState.CRUISE
	else:
		current_flight_state = FlightState.HOVER
		smoothed_cruise_forward = Vector3.ZERO
	flight_state_changed.emit(current_flight_state)

func _get_desired_cruise_forward(movement_state: MovementState) -> Vector3:
	var desired_forward := Vector3.ZERO
	if movement_state.camera != null:
		desired_forward = -movement_state.camera.global_basis.z
	elif manager != null and manager.camera != null:
		desired_forward = -manager.camera.global_basis.z
	elif manager != null and manager.controller != null:
		desired_forward = -manager.controller.global_basis.z

	if desired_forward.length_squared() > 0.0:
		return desired_forward.normalized()
	return Vector3.ZERO

func clear_mode_override() -> void:
	horizontal_flight_speed = default_horizontal_flight_speed
	vertical_flight_speed = default_vertical_flight_speed
	acceleration_speed = default_acceleration_speed
	deceleration_speed = default_deceleration_speed
	cruise_forward_speed = default_cruise_forward_speed
	use_move_axis_for_vertical_in_cruise = default_use_move_axis_for_vertical_in_cruise
	cruise_forward_smoothing_speed = default_cruise_forward_smoothing_speed
	use_move_axis_for_vertical_in_hover = default_use_move_axis_for_vertical_in_hover
	auto_land_when_grounded = default_auto_land_when_grounded
	default_flight_state = default_flight_state_value
