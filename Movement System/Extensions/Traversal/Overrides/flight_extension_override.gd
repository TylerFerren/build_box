class_name FlightExtensionOverride
extends ExtensionModeOverride

@export var override_horizontal_flight_speed: bool = false
@export var horizontal_flight_speed: float = 9.0

@export var override_vertical_flight_speed: bool = false
@export var vertical_flight_speed: float = 6.0

@export var override_acceleration_speed: bool = false
@export var acceleration_speed: float = 18.0

@export var override_deceleration_speed: bool = false
@export var deceleration_speed: float = 14.0

@export var override_cruise_forward_speed: bool = false
@export var cruise_forward_speed: float = 11.0

@export var override_use_move_axis_for_vertical_in_cruise: bool = false
@export var use_move_axis_for_vertical_in_cruise: bool = true

@export var override_cruise_forward_smoothing_speed: bool = false
@export var cruise_forward_smoothing_speed: float = 7.0

@export var override_use_move_axis_for_vertical_in_hover: bool = false
@export var use_move_axis_for_vertical_in_hover: bool = false

@export var override_auto_land_when_grounded: bool = false
@export var auto_land_when_grounded: bool = false

@export var override_default_flight_state: bool = false
@export var default_flight_state: Flight.FlightState = Flight.FlightState.HOVER

func apply_to_extension(target_extension: MovementExtension) -> void:
	var flight_extension := target_extension as Flight
	if flight_extension == null:
		return

	if override_horizontal_flight_speed:
		flight_extension.horizontal_flight_speed = horizontal_flight_speed
	if override_vertical_flight_speed:
		flight_extension.vertical_flight_speed = vertical_flight_speed
	if override_acceleration_speed:
		flight_extension.acceleration_speed = acceleration_speed
	if override_deceleration_speed:
		flight_extension.deceleration_speed = deceleration_speed
	if override_cruise_forward_speed:
		flight_extension.cruise_forward_speed = cruise_forward_speed
	if override_use_move_axis_for_vertical_in_cruise:
		flight_extension.use_move_axis_for_vertical_in_cruise = use_move_axis_for_vertical_in_cruise
	if override_cruise_forward_smoothing_speed:
		flight_extension.cruise_forward_smoothing_speed = cruise_forward_smoothing_speed
	if override_use_move_axis_for_vertical_in_hover:
		flight_extension.use_move_axis_for_vertical_in_hover = use_move_axis_for_vertical_in_hover
	if override_auto_land_when_grounded:
		flight_extension.auto_land_when_grounded = auto_land_when_grounded
	if override_default_flight_state:
		flight_extension.default_flight_state = default_flight_state
