class_name ImpulseExtensionOverride
extends ExtensionModeOverride

@export var override_impulse_distance: bool = false
@export var impulse_distance: float = 5.0

@export var override_impulse_speed: bool = false
@export var impulse_speed: float = 12.0

@export var override_recovery_time: bool = false
@export var recovery_time: float = 0.5

@export var override_lift_height: bool = false
@export var lift_height: float = 0.0

@export var override_enable_momentum: bool = false
@export var enable_momentum: bool = false

@export var override_momentum_drag: bool = false
@export var momentum_drag: float = 3.0

@export var override_use_camera_relative_direction: bool = false
@export var use_camera_relative_direction: bool = true

func apply_to_extension(target_extension: MovementExtension) -> void:
	var impulse_extension := target_extension as Impulse
	if impulse_extension == null:
		return

	if override_impulse_distance:
		impulse_extension.impulse_distance = impulse_distance
	if override_impulse_speed:
		impulse_extension.impulse_speed = impulse_speed
	if override_recovery_time:
		impulse_extension.recovery_time = recovery_time
	if override_lift_height:
		impulse_extension.lift_height = lift_height
	if override_enable_momentum:
		impulse_extension.enable_momentum = enable_momentum
	if override_momentum_drag:
		impulse_extension.momentum_drag = momentum_drag
	if override_use_camera_relative_direction:
		impulse_extension.use_camera_relative_direction = use_camera_relative_direction
