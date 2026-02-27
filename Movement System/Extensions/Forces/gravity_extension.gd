class_name Gravity
extends MovementExtension

@export var gravity_force: Vector3 = Vector3(0.0, -9.8, 0.0)
@export var minimum_fall_velocity: float = -1.0

func _ready() -> void:
	blend_mode = MovementExtension.ExtensionBlendMode.CONSTANT

func get_movement_velocity(movement_state: MovementState, delta: float) -> Vector3:
	if manager == null or manager.controller == null:
		return Vector3.ZERO

	var clamped_vertical_velocity := Vector3(0.0, min(movement_state.current_velocity.y, minimum_fall_velocity), 0.0)
	return clamped_vertical_velocity + (delta * gravity_force * movement_state.gravity_scale)
