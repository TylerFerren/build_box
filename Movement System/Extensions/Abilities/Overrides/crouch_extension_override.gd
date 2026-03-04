class_name CrouchExtensionOverride
extends ExtensionModeOverride

@export var override_crouch_speed_multiplier: bool = false
@export var crouch_speed_multiplier: float = 0.55

@export var override_crouch_height_scale: bool = false
@export var crouch_height_scale: float = 0.65

@export var override_crouch_transition_speed: bool = false
@export var crouch_transition_speed: float = 8.0

@export var override_use_toggle_input: bool = false
@export var use_toggle_input: bool = false

@export var override_require_headroom_to_stand: bool = false
@export var require_headroom_to_stand: bool = true

@export var override_stand_check_margin: bool = false
@export var stand_check_margin: float = 0.05

func apply_to_extension(target_extension: MovementExtension) -> void:
	var crouch_extension := target_extension as Crouch
	if crouch_extension == null:
		return

	if override_crouch_speed_multiplier:
		crouch_extension.crouch_speed_multiplier = crouch_speed_multiplier
	if override_crouch_height_scale:
		crouch_extension.crouch_height_scale = crouch_height_scale
	if override_crouch_transition_speed:
		crouch_extension.crouch_transition_speed = crouch_transition_speed
	if override_use_toggle_input:
		crouch_extension.use_toggle_input = use_toggle_input
	if override_require_headroom_to_stand:
		crouch_extension.require_headroom_to_stand = require_headroom_to_stand
	if override_stand_check_margin:
		crouch_extension.stand_check_margin = stand_check_margin
