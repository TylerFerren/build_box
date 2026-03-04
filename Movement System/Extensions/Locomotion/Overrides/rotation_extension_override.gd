class_name RotationExtensionOverride
extends ExtensionModeOverride

@export var override_rotation_driver: bool = false
@export_enum("Movement Direction", "Input Direction", "Follow Camera", "Cursor Based")
var rotation_driver: int = 0

@export var override_rotation_speed: bool = false
@export var rotation_speed: float = 360.0

@export var override_only_rotate_on_move: bool = false
@export var only_rotate_on_move: bool = false

@export var override_lock_upright: bool = false
@export var lock_upright: bool = true

@export var override_cursor_ray_length: bool = false
@export var cursor_ray_length: float = 1000.0

@export var override_input_deadzone: bool = false
@export var input_deadzone: float = 0.05

@export var override_direction_deadzone: bool = false
@export var direction_deadzone: float = 0.0001

func apply_to_extension(target_extension: MovementExtension) -> void:
	var rotation_extension := target_extension as Rotation
	if rotation_extension == null:
		return

	if override_rotation_driver:
		rotation_extension.rotation_driver = rotation_driver
	if override_rotation_speed:
		rotation_extension.rotation_speed = rotation_speed
	if override_only_rotate_on_move:
		rotation_extension.only_rotate_on_move = only_rotate_on_move
	if override_lock_upright:
		rotation_extension.lock_upright = lock_upright
	if override_cursor_ray_length:
		rotation_extension.cursor_ray_length = cursor_ray_length
	if override_input_deadzone:
		rotation_extension.input_deadzone = input_deadzone
	if override_direction_deadzone:
		rotation_extension.direction_deadzone = direction_deadzone
