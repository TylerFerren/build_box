class_name GravityExtensionOverride
extends ExtensionModeOverride

@export var override_gravity_force: bool = false
@export var gravity_force: Vector3 = Vector3(0.0, -9.8, 0.0)

@export var override_minimum_fall_velocity: bool = false
@export var minimum_fall_velocity: float = -1.0

func apply_to_extension(target_extension: MovementExtension) -> void:
	var gravity_extension := target_extension as Gravity
	if gravity_extension == null:
		return

	if override_gravity_force:
		gravity_extension.gravity_force = gravity_force
	if override_minimum_fall_velocity:
		gravity_extension.minimum_fall_velocity = minimum_fall_velocity
