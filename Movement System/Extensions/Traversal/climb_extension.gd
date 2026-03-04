class_name Climb
extends MovementExtension

@export var climb_speed: float = 4.0
@export var wall_stick_speed: float = 1.5
@export_group("Ledge Mantle")
@export var enable_ledge_mantle: bool = true
@export var ledge_input_threshold: float = 0.35
@export var lower_wall_probe_height: float = 1.0
@export var upper_wall_probe_height: float = 1.8
@export var wall_probe_distance: float = 0.7
@export var mantle_probe_forward_offset: float = 0.45
@export var mantle_probe_up_offset: float = 1.2
@export var mantle_floor_probe_depth: float = 2.0
@export var mantle_floor_minimum_up_dot: float = 0.65
@export var mantle_height_offset: float = 0.05
@export var mantle_forward_offset: float = 0.2
@export var mantle_move_speed: float = 5.5
@export var mantle_completion_distance: float = 0.08
@export var mantle_timeout: float = 0.6

signal climb_entered
signal climb_exited

var cached_wall_normal: Vector3 = Vector3.ZERO
var is_mantling: bool = false
var mantle_target_position: Vector3 = Vector3.ZERO
var mantle_time_remaining: float = 0.0
var default_climb_speed: float = 0.0
var default_wall_stick_speed: float = 0.0
var default_enable_ledge_mantle: bool = true
var default_ledge_input_threshold: float = 0.0
var default_lower_wall_probe_height: float = 0.0
var default_upper_wall_probe_height: float = 0.0
var default_wall_probe_distance: float = 0.0
var default_mantle_probe_forward_offset: float = 0.0
var default_mantle_probe_up_offset: float = 0.0
var default_mantle_floor_probe_depth: float = 0.0
var default_mantle_floor_minimum_up_dot: float = 0.0
var default_mantle_height_offset: float = 0.0
var default_mantle_forward_offset: float = 0.0
var default_mantle_move_speed: float = 0.0
var default_mantle_completion_distance: float = 0.0
var default_mantle_timeout: float = 0.0

func _ready() -> void:
	affects_movement = true
	affects_rotation = false
	default_climb_speed = climb_speed
	default_wall_stick_speed = wall_stick_speed
	default_enable_ledge_mantle = enable_ledge_mantle
	default_ledge_input_threshold = ledge_input_threshold
	default_lower_wall_probe_height = lower_wall_probe_height
	default_upper_wall_probe_height = upper_wall_probe_height
	default_wall_probe_distance = wall_probe_distance
	default_mantle_probe_forward_offset = mantle_probe_forward_offset
	default_mantle_probe_up_offset = mantle_probe_up_offset
	default_mantle_floor_probe_depth = mantle_floor_probe_depth
	default_mantle_floor_minimum_up_dot = mantle_floor_minimum_up_dot
	default_mantle_height_offset = mantle_height_offset
	default_mantle_forward_offset = mantle_forward_offset
	default_mantle_move_speed = mantle_move_speed
	default_mantle_completion_distance = mantle_completion_distance
	default_mantle_timeout = mantle_timeout
	request_active_state(false)

func update_extension_state(movement_state: MovementState, _delta: float) -> void:
	if movement_state.wall_normal.length_squared() > 0.0:
		cached_wall_normal = movement_state.wall_normal.normalized()

	if not is_mantling and _should_start_ledge_mantle(movement_state):
		_try_start_ledge_mantle(movement_state)

	if is_mantling:
		movement_state.metadata["suppress_mode_transitions"] = true
		mantle_time_remaining = max(mantle_time_remaining - movement_state.delta_time, 0.0)
		if is_zero_approx(mantle_time_remaining):
			_finish_ledge_mantle()

	var should_be_active := is_mantling or (movement_state.current_mode == MovementModeNames.CLIMBING and cached_wall_normal.length_squared() > 0.0)
	if should_be_active and not is_active:
		climb_entered.emit()
	elif not should_be_active and is_active:
		climb_exited.emit()

	request_active_state(should_be_active)

func get_movement_velocity(movement_state: MovementState, _delta: float) -> Vector3:
	if not is_active:
		return Vector3.ZERO

	if is_mantling:
		return _get_ledge_mantle_velocity()

	var up_direction := movement_state.up_direction.normalized()
	var wall_normal := cached_wall_normal

	var wall_lateral_direction := up_direction.cross(wall_normal)
	if wall_lateral_direction.length_squared() > 0.0:
		wall_lateral_direction = wall_lateral_direction.normalized()
	else:
		wall_lateral_direction = Vector3.RIGHT

	var vertical_input := -movement_state.move_input.y
	var climb_input_direction := (wall_lateral_direction * movement_state.move_input.x) + (up_direction * vertical_input)
	if climb_input_direction.length_squared() > 1.0:
		climb_input_direction = climb_input_direction.normalized()

	var movement_velocity := climb_input_direction * climb_speed * movement_state.speed_multiplier
	movement_velocity += -wall_normal * wall_stick_speed
	return movement_velocity

func _should_start_ledge_mantle(movement_state: MovementState) -> bool:
	if not enable_ledge_mantle:
		return false
	if movement_state.current_mode != MovementModeNames.CLIMBING:
		return false
	if cached_wall_normal.length_squared() <= 0.0:
		return false
	if manager == null or manager.controller == null:
		return false

	var vertical_input := -movement_state.move_input.y
	if vertical_input < ledge_input_threshold:
		return false

	return true

func _try_start_ledge_mantle(movement_state: MovementState) -> void:
	var controller_node := manager.controller
	var up_direction := movement_state.up_direction.normalized()
	var wall_normal := cached_wall_normal
	var wall_forward := -wall_normal

	var lower_probe_start := controller_node.global_position + (up_direction * lower_wall_probe_height)
	var lower_probe_end := lower_probe_start + (wall_forward * wall_probe_distance)
	var lower_probe_hit := _raycast(lower_probe_start, lower_probe_end)
	if lower_probe_hit.is_empty():
		return

	var upper_probe_start := controller_node.global_position + (up_direction * upper_wall_probe_height)
	var upper_probe_end := upper_probe_start + (wall_forward * wall_probe_distance)
	var upper_probe_hit := _raycast(upper_probe_start, upper_probe_end)
	if not upper_probe_hit.is_empty():
		return

	var floor_probe_start := controller_node.global_position \
		+ (up_direction * mantle_probe_up_offset) \
		+ (wall_forward * mantle_probe_forward_offset)
	var floor_probe_end := floor_probe_start - (up_direction * mantle_floor_probe_depth)
	var floor_probe_hit := _raycast(floor_probe_start, floor_probe_end)
	if floor_probe_hit.is_empty():
		return

	var floor_normal: Vector3 = floor_probe_hit.get("normal", Vector3.UP) as Vector3
	if floor_normal.normalized().dot(up_direction) < mantle_floor_minimum_up_dot:
		return

	var hit_position: Vector3 = floor_probe_hit.get("position", controller_node.global_position) as Vector3
	mantle_target_position = hit_position \
		+ (up_direction * mantle_height_offset) \
		+ (wall_forward * mantle_forward_offset)
	is_mantling = true
	mantle_time_remaining = mantle_timeout

func _get_ledge_mantle_velocity() -> Vector3:
	if manager == null or manager.controller == null:
		is_mantling = false
		return Vector3.ZERO

	var to_target := mantle_target_position - manager.controller.global_position
	if to_target.length() <= mantle_completion_distance:
		_finish_ledge_mantle()
		return Vector3.ZERO

	return to_target.normalized() * mantle_move_speed

func _finish_ledge_mantle() -> void:
	is_mantling = false
	mantle_time_remaining = 0.0
	cached_wall_normal = Vector3.ZERO
	if manager != null:
		manager.request_mode_change(MovementModeNames.WALKING)

func _raycast(start_position: Vector3, end_position: Vector3) -> Dictionary:
	if manager == null or manager.controller == null:
		return {}

	var ray_query := PhysicsRayQueryParameters3D.create(start_position, end_position)
	ray_query.exclude = [manager.controller.get_rid()]
	ray_query.collide_with_areas = true

	var physics_space := manager.controller.get_world_3d().direct_space_state
	return physics_space.intersect_ray(ray_query)

func clear_mode_override() -> void:
	climb_speed = default_climb_speed
	wall_stick_speed = default_wall_stick_speed
	enable_ledge_mantle = default_enable_ledge_mantle
	ledge_input_threshold = default_ledge_input_threshold
	lower_wall_probe_height = default_lower_wall_probe_height
	upper_wall_probe_height = default_upper_wall_probe_height
	wall_probe_distance = default_wall_probe_distance
	mantle_probe_forward_offset = default_mantle_probe_forward_offset
	mantle_probe_up_offset = default_mantle_probe_up_offset
	mantle_floor_probe_depth = default_mantle_floor_probe_depth
	mantle_floor_minimum_up_dot = default_mantle_floor_minimum_up_dot
	mantle_height_offset = default_mantle_height_offset
	mantle_forward_offset = default_mantle_forward_offset
	mantle_move_speed = default_mantle_move_speed
	mantle_completion_distance = default_mantle_completion_distance
	mantle_timeout = default_mantle_timeout
