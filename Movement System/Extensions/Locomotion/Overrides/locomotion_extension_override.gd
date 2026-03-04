class_name LocomotionExtensionOverride
extends ExtensionModeOverride

@export var override_speed: bool = false
@export var speed: float = 5.0

@export var override_acceleration: bool = false
@export var acceleration: float = 3.0

@export var override_deceleration: bool = false
@export var deceleration: float = 5.0

@export var override_directional_acceleration: bool = false
@export var directional_acceleration: float = 4.0

func apply_to_extension(target_extension: MovementExtension) -> void:
	var locomotion_extension := target_extension as Locomotion
	if locomotion_extension == null:
		return

	if override_speed:
		locomotion_extension.speed = speed
	if override_acceleration:
		locomotion_extension.acceleration = acceleration
	if override_deceleration:
		locomotion_extension.deceleration = deceleration
	if override_directional_acceleration:
		locomotion_extension.directional_acceleration = directional_acceleration
