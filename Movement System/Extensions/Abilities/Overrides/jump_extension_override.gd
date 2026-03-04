class_name JumpExtensionOverride
extends ExtensionModeOverride

@export var override_jump_height: bool = false
@export var jump_height: float = 3.0

@export var override_air_jumps: bool = false
@export var air_jumps: int = 1

@export var override_fast_fall_multiplier: bool = false
@export var fast_fall_multiplier: float = 2.0

@export var override_low_jump_multiplier: bool = false
@export var low_jump_multiplier: float = 2.0

@export var override_coyote_time: bool = false
@export var coyote_time: float = 0.2

@export var override_enable_wall_jump: bool = false
@export var enable_wall_jump: bool = true

@export var override_wall_jump_push_speed: bool = false
@export var wall_jump_push_speed: float = 8.0

@export var override_wall_jump_push_dampening: bool = false
@export var wall_jump_push_dampening: float = 6.0

@export var override_wall_jump_cooldown: bool = false
@export var wall_jump_cooldown: float = 0.1

func apply_to_extension(target_extension: MovementExtension) -> void:
	var jump_extension := target_extension as Jump
	if jump_extension == null:
		return

	if override_jump_height:
		jump_extension.jump_height = jump_height
	if override_air_jumps:
		jump_extension.air_jumps = air_jumps
	if override_fast_fall_multiplier:
		jump_extension.fast_fall_multiplier = fast_fall_multiplier
	if override_low_jump_multiplier:
		jump_extension.low_jump_multiplier = low_jump_multiplier
	if override_coyote_time:
		jump_extension.coyote_time = coyote_time
	if override_enable_wall_jump:
		jump_extension.enable_wall_jump = enable_wall_jump
	if override_wall_jump_push_speed:
		jump_extension.wall_jump_push_speed = wall_jump_push_speed
	if override_wall_jump_push_dampening:
		jump_extension.wall_jump_push_dampening = wall_jump_push_dampening
	if override_wall_jump_cooldown:
		jump_extension.wall_jump_cooldown = wall_jump_cooldown
