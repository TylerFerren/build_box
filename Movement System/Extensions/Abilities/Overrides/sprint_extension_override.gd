class_name SprintExtensionOverride
extends ExtensionModeOverride

@export var override_sprint_speed_multiplier: bool = false
@export var sprint_speed_multiplier: float = 1.75

@export var override_require_grounded: bool = false
@export var require_grounded: bool = true

@export var override_require_move_input: bool = false
@export var require_move_input: bool = true

@export var override_use_toggle_input: bool = false
@export var use_toggle_input: bool = false

func apply_to_extension(target_extension: MovementExtension) -> void:
	var sprint_extension := target_extension as Sprint
	if sprint_extension == null:
		return

	if override_sprint_speed_multiplier:
		sprint_extension.sprint_speed_multiplier = sprint_speed_multiplier
	if override_require_grounded:
		sprint_extension.require_grounded = require_grounded
	if override_require_move_input:
		sprint_extension.require_move_input = require_move_input
	if override_use_toggle_input:
		sprint_extension.use_toggle_input = use_toggle_input
