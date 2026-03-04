class_name Gravity
extends MovementExtension

@export var gravity_force: Vector3 = Vector3(0.0, -9.8, 0.0)
@export var minimum_fall_velocity: float = -1.0
var default_gravity_force: Vector3 = Vector3.ZERO
var default_minimum_fall_velocity: float = 0.0

func _ready() -> void:
	blend_mode = MovementExtension.ExtensionBlendMode.CONSTANT
	default_gravity_force = gravity_force
	default_minimum_fall_velocity = minimum_fall_velocity

func get_movement_velocity(movement_state: MovementState, delta: float) -> Vector3:
	if manager == null or manager.controller == null:
		return Vector3.ZERO
	if movement_state.gravity_scale <= 0.0:
		return Vector3.ZERO

	var clamped_vertical_velocity := Vector3(0.0, min(movement_state.current_velocity.y, minimum_fall_velocity), 0.0)
	return clamped_vertical_velocity + (delta * gravity_force * movement_state.gravity_scale)

func clear_mode_override() -> void:
	gravity_force = default_gravity_force
	minimum_fall_velocity = default_minimum_fall_velocity
