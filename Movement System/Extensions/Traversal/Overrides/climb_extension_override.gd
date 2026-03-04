class_name ClimbExtensionOverride
extends ExtensionModeOverride

@export var override_climb_speed: bool = false
@export var climb_speed: float = 4.0

@export var override_wall_stick_speed: bool = false
@export var wall_stick_speed: float = 1.5

@export var override_enable_ledge_mantle: bool = false
@export var enable_ledge_mantle: bool = true

@export var override_ledge_input_threshold: bool = false
@export var ledge_input_threshold: float = 0.35

@export var override_lower_wall_probe_height: bool = false
@export var lower_wall_probe_height: float = 1.0

@export var override_upper_wall_probe_height: bool = false
@export var upper_wall_probe_height: float = 1.8

@export var override_wall_probe_distance: bool = false
@export var wall_probe_distance: float = 0.7

@export var override_mantle_probe_forward_offset: bool = false
@export var mantle_probe_forward_offset: float = 0.45

@export var override_mantle_probe_up_offset: bool = false
@export var mantle_probe_up_offset: float = 1.2

@export var override_mantle_floor_probe_depth: bool = false
@export var mantle_floor_probe_depth: float = 2.0

@export var override_mantle_floor_minimum_up_dot: bool = false
@export var mantle_floor_minimum_up_dot: float = 0.65

@export var override_mantle_height_offset: bool = false
@export var mantle_height_offset: float = 0.05

@export var override_mantle_forward_offset: bool = false
@export var mantle_forward_offset: float = 0.2

@export var override_mantle_move_speed: bool = false
@export var mantle_move_speed: float = 5.5

@export var override_mantle_completion_distance: bool = false
@export var mantle_completion_distance: float = 0.08

@export var override_mantle_timeout: bool = false
@export var mantle_timeout: float = 0.6

func apply_to_extension(target_extension: MovementExtension) -> void:
	var climb_extension := target_extension as Climb
	if climb_extension == null:
		return

	if override_climb_speed:
		climb_extension.climb_speed = climb_speed
	if override_wall_stick_speed:
		climb_extension.wall_stick_speed = wall_stick_speed
	if override_enable_ledge_mantle:
		climb_extension.enable_ledge_mantle = enable_ledge_mantle
	if override_ledge_input_threshold:
		climb_extension.ledge_input_threshold = ledge_input_threshold
	if override_lower_wall_probe_height:
		climb_extension.lower_wall_probe_height = lower_wall_probe_height
	if override_upper_wall_probe_height:
		climb_extension.upper_wall_probe_height = upper_wall_probe_height
	if override_wall_probe_distance:
		climb_extension.wall_probe_distance = wall_probe_distance
	if override_mantle_probe_forward_offset:
		climb_extension.mantle_probe_forward_offset = mantle_probe_forward_offset
	if override_mantle_probe_up_offset:
		climb_extension.mantle_probe_up_offset = mantle_probe_up_offset
	if override_mantle_floor_probe_depth:
		climb_extension.mantle_floor_probe_depth = mantle_floor_probe_depth
	if override_mantle_floor_minimum_up_dot:
		climb_extension.mantle_floor_minimum_up_dot = mantle_floor_minimum_up_dot
	if override_mantle_height_offset:
		climb_extension.mantle_height_offset = mantle_height_offset
	if override_mantle_forward_offset:
		climb_extension.mantle_forward_offset = mantle_forward_offset
	if override_mantle_move_speed:
		climb_extension.mantle_move_speed = mantle_move_speed
	if override_mantle_completion_distance:
		climb_extension.mantle_completion_distance = mantle_completion_distance
	if override_mantle_timeout:
		climb_extension.mantle_timeout = mantle_timeout
