class_name Rotation
extends MovementExtension

enum RotationDriver {MOVEMENT_DIRECTION, INPUT_DIRECTION, FOLLOW_CAMERA, CURSOR_BASED}

@export var rotation_driver : RotationDriver = RotationDriver.MOVEMENT_DIRECTION
@export_range(0 , 1440) var rotation_speed = 360
@export var only_rotate_on_move : bool = false
@export var lock_upright : bool = true
@export var cursor_ray_length : float = 1000.0
@export var input_deadzone: float = 0.05
@export var direction_deadzone: float = 0.0001

var target_direction: Vector3 = Vector3.ZERO
var target_rotation: Vector3 = Vector3.ZERO
var smooth_rotation: Vector3 = Vector3.ZERO
var default_rotation_driver: RotationDriver = RotationDriver.MOVEMENT_DIRECTION
var default_rotation_speed: float = 0.0
var default_only_rotate_on_move: bool = false
var default_lock_upright: bool = true
var default_cursor_ray_length: float = 0.0
var default_input_deadzone: float = 0.0
var default_direction_deadzone: float = 0.0

func _ready() -> void:
	affects_movement = false
	affects_rotation = true
	default_rotation_driver = rotation_driver
	default_rotation_speed = rotation_speed
	default_only_rotate_on_move = only_rotate_on_move
	default_lock_upright = lock_upright
	default_cursor_ray_length = cursor_ray_length
	default_input_deadzone = input_deadzone
	default_direction_deadzone = direction_deadzone

func get_rotation_euler(movement_state: MovementState, delta: float) -> Vector3:
	match rotation_driver:
		RotationDriver.MOVEMENT_DIRECTION:
			_rotate_towards_movement(movement_state)
		RotationDriver.INPUT_DIRECTION:
			_rotate_towards_input(movement_state)
		RotationDriver.FOLLOW_CAMERA:
			_rotate_following_camera(movement_state)
		RotationDriver.CURSOR_BASED:
			_rotate_towards_cursor(movement_state)

	var has_rotation_direction: bool = target_direction.length_squared() > direction_deadzone
	if not has_rotation_direction:
		return smooth_rotation

	if only_rotate_on_move and movement_state.move_input.length() <= input_deadzone:
		return smooth_rotation
	
	var horizontal_length := Vector2(target_direction.x, target_direction.z).length()
	var pitch_rotation := -atan2(target_direction.y, horizontal_length)
	var yaw_rotation := atan2(-target_direction.x, -target_direction.z)
	var roll_rotation := atan2(target_direction.x, horizontal_length)
	
	if lock_upright:
		target_rotation = Vector3(0.0, yaw_rotation, 0.0)
	else:
		target_rotation = Vector3(pitch_rotation, yaw_rotation, roll_rotation)
	
	var max_step := deg_to_rad(rotation_speed) * delta
	smooth_rotation = Vector3(
		move_toward(smooth_rotation.x, target_rotation.x, max_step),
		rotate_toward(smooth_rotation.y, target_rotation.y, max_step),
		move_toward(smooth_rotation.z, target_rotation.z, max_step)
	)
	return smooth_rotation

func _rotate_towards_movement(movement_state: MovementState) -> void:
	target_direction = movement_state.current_velocity.slide(movement_state.up_direction)
	if lock_upright:
		target_direction.y = 0.0
	if target_direction.length_squared() <= direction_deadzone:
		target_direction = Vector3.ZERO

func _rotate_towards_input(movement_state: MovementState) -> void:
	if movement_state.move_input.length() <= input_deadzone:
		target_direction = Vector3.ZERO
		return

	var input_direction := Vector3(movement_state.move_input.x, 0.0, movement_state.move_input.y)
	target_direction = manager.get_camera_relative_input(input_direction)
	if lock_upright:
		target_direction.y = 0.0
	if target_direction.length_squared() <= direction_deadzone:
		target_direction = Vector3.ZERO

func _rotate_following_camera(movement_state: MovementState) -> void:
	var active_camera := _get_active_camera(movement_state)
	if active_camera == null:
		target_direction = Vector3.ZERO
		return

	target_direction = -active_camera.global_basis.z
	if lock_upright:
		target_direction.y = 0.0
	if target_direction.length_squared() <= direction_deadzone:
		target_direction = Vector3.ZERO

func _rotate_towards_cursor(movement_state: MovementState) -> void:
	var active_camera := _get_active_camera(movement_state)
	if active_camera == null:
		target_direction = Vector3.ZERO
		return
	
	var mouse_position := get_viewport().get_mouse_position()
	var ray_origin := active_camera.project_ray_origin(mouse_position)
	var ray_direction := active_camera.project_ray_normal(mouse_position)
	var ray_end := ray_origin + (ray_direction * cursor_ray_length)
	
	var ray_query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	ray_query.exclude = [manager.controller.get_rid()]
	ray_query.collide_with_areas = true
	
	var world_space_state := manager.controller.get_world_3d().direct_space_state
	var raycast_hit := world_space_state.intersect_ray(ray_query)
	
	if raycast_hit.has("position"):
		target_direction = raycast_hit["position"] - movement_state.character_global_position
	else:
		var ground_plane := Plane(Vector3.UP, movement_state.character_global_position.y)
		var plane_hit_result: Variant = ground_plane.intersects_ray(ray_origin, ray_direction)
		if plane_hit_result == null:
			target_direction = Vector3.ZERO
			return
		var plane_hit_position: Vector3 = plane_hit_result
		target_direction = plane_hit_position - movement_state.character_global_position

	if lock_upright:
		target_direction.y = 0.0
	if target_direction.length_squared() <= direction_deadzone:
		target_direction = Vector3.ZERO

func _get_active_camera(movement_state: MovementState) -> Camera3D:
	if movement_state.camera != null:
		return movement_state.camera
	return get_viewport().get_camera_3d()

func clear_mode_override() -> void:
	rotation_driver = default_rotation_driver
	rotation_speed = default_rotation_speed
	only_rotate_on_move = default_only_rotate_on_move
	lock_upright = default_lock_upright
	cursor_ray_length = default_cursor_ray_length
	input_deadzone = default_input_deadzone
	direction_deadzone = default_direction_deadzone
