class_name Locomotion
extends MovementExtension

@export var speed: float = 5.0
@export var acceleration: float = 3.0
@export var deceleration: float = 5.0
@export var directional_acceleration: float = 4.0

var target_direction: Vector3 = Vector3.ZERO
var smoothed_direction: Vector3 = Vector3.ZERO
var target_speed: float = 0.0
var smoothed_speed: float = 0.0

func get_movement_velocity(movement_state: MovementState, delta: float) -> Vector3:
	var move_input_direction := Vector3(movement_state.move_input.x, 0.0, movement_state.move_input.y)
	var camera_relative_input := manager.get_camera_relative_input(move_input_direction)
	var floor_plane_direction : Vector3 = camera_relative_input
	if movement_state.is_grounded:
		floor_plane_direction = camera_relative_input.slide(movement_state.ground_normal)
	if floor_plane_direction.length_squared() > 0.0:
		target_direction = floor_plane_direction.normalized()
	else:
		target_direction = Vector3.ZERO

	smoothed_direction = lerp(smoothed_direction, target_direction, directional_acceleration * delta)

	target_speed = speed * movement_state.move_input.length() * movement_state.speed_multiplier
	if target_speed > 0.0:
		smoothed_speed = lerp(smoothed_speed, target_speed, acceleration * delta)
	else:
		smoothed_speed = lerp(smoothed_speed, target_speed, deceleration * delta)

	return smoothed_speed * smoothed_direction
