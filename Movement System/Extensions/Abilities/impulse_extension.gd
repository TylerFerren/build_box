class_name Impulse
extends MovementExtension

@export var impulse_distance: float = 5.0
@export var impulse_speed: float = 12.0
@export var recovery_time: float = 0.5
@export var lift_height: float = 0.0
@export var enable_momentum: bool = false
@export var momentum_drag: float = 3.0
@export var use_camera_relative_direction: bool = true

signal impulse_started
signal impulse_finished
signal impulse_entered
signal impulse_exited

var remaining_impulse_time: float = 0.0
var remaining_recovery_time: float = 0.0
var directional_input: Vector2 = Vector2.ZERO
var impulse_direction: Vector3 = Vector3.ZERO
var momentum_velocity: Vector3 = Vector3.ZERO
var current_floor_normal: Vector3 = Vector3.UP
var is_impulse_requested: bool = false
var did_emit_finished_signal: bool = false

func _ready() -> void:
	blend_mode = MovementExtension.ExtensionBlendMode.OVERRIDING
	is_active = false

func on_impulse_pressed() -> void:
	is_impulse_requested = true

func set_directional_input(input_direction: Vector2) -> void:
	directional_input = input_direction

func update_extension_state(movement_state: MovementState, delta: float) -> void:
	current_floor_normal = movement_state.ground_normal

	if is_impulse_requested:
		_try_start_impulse(movement_state)
	is_impulse_requested = false

	if remaining_impulse_time > 0.0:
		remaining_impulse_time = max(remaining_impulse_time - delta, 0.0)
		if is_equal_approx(remaining_impulse_time, 0.0):
			remaining_recovery_time = recovery_time
			did_emit_finished_signal = false
	elif remaining_recovery_time > 0.0:
		remaining_recovery_time = max(remaining_recovery_time - delta, 0.0)

	var is_currently_impulsing := remaining_impulse_time > 0.0
	if is_currently_impulsing:
		is_active = true
	else:
		if enable_momentum and momentum_velocity.length_squared() > 0.0001:
			is_active = true
		else:
			is_active = false
			if not did_emit_finished_signal:
				impulse_finished.emit()
				impulse_exited.emit()
				did_emit_finished_signal = true

func get_movement_velocity(_movement_state: MovementState, delta: float) -> Vector3:
	if remaining_impulse_time > 0.0:
		var impulse_velocity := impulse_speed * impulse_direction
		momentum_velocity = impulse_velocity
		impulse_velocity += _get_lift_velocity(delta)
		return impulse_velocity

	if enable_momentum and momentum_velocity.length_squared() > 0.0001:
		momentum_velocity = momentum_velocity.move_toward(Vector3.ZERO, momentum_drag * delta)
		return momentum_velocity

	return Vector3.ZERO

func _try_start_impulse(movement_state: MovementState) -> void:
	if is_active or remaining_recovery_time > 0.0:
		return
	if is_zero_approx(impulse_speed) or is_zero_approx(impulse_distance):
		return

	remaining_impulse_time = impulse_distance / impulse_speed
	did_emit_finished_signal = false

	var has_directional_input := directional_input.length_squared() > 0.0
	if has_directional_input:
		var directional_vector := Vector3(directional_input.x, 0.0, directional_input.y)
		var world_direction := directional_vector
		if use_camera_relative_direction:
			world_direction = manager.get_camera_relative_input(directional_vector)
		var projected_direction := world_direction.slide(current_floor_normal)
		if projected_direction.length_squared() > 0.0:
			impulse_direction = projected_direction.normalized()
		else:
			impulse_direction = _get_forward_direction()
	else:
		impulse_direction = _get_forward_direction()

	impulse_started.emit()
	impulse_entered.emit()

func _get_forward_direction() -> Vector3:
	var forward_direction := -manager.controller.global_basis.z
	var projected_forward := forward_direction.slide(current_floor_normal)
	if projected_forward.length_squared() > 0.0:
		return projected_forward.normalized()
	return forward_direction.normalized()

func _get_lift_velocity(_delta: float) -> Vector3:
	if is_zero_approx(lift_height):
		return Vector3.ZERO
	var impulse_duration := impulse_distance / impulse_speed
	var impulse_progress := 1.0 - (remaining_impulse_time / impulse_duration)
	var lift_speed := lift_height * sin(PI * impulse_progress)
	return manager.controller.up_direction * lift_speed
