class_name Rotation
extends MovementExtension

enum RotationDriver {MOVEMENT_DIRECTION, INPUT_DIRECTION, FOLLOW_CAMERA, CURSOR_BASED}

@export var rotation_driver : RotationDriver = RotationDriver.MOVEMENT_DIRECTION
@export_range(0 , 1440) var rotation_speed = 360
@export var only_rotate_on_move : bool = false
@export var lock_upright : bool = true
@export var cursor_ray_length : float = 1000.0


var target_direction: Vector3 = Vector3.ZERO
var target_rotation: Vector3 = Vector3.ZERO
var smooth_rotation: Vector3 = Vector3.ZERO

func _ready() -> void:
	affects_movement = false
	affects_rotation = true

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

	if only_rotate_on_move and target_direction.length_squared() == 0.0:
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

func _rotate_towards_input(movement_state: MovementState) -> void:
	var input_direction := Vector3(movement_state.move_input.x, 0.0, movement_state.move_input.y)
	target_direction = manager.get_camera_relative_input(input_direction)
	if lock_upright:
		target_direction.y = 0.0

func _rotate_following_camera(movement_state: MovementState) -> void:
	var active_camera := _get_active_camera(movement_state)
	if active_camera == null:
		target_direction = Vector3.ZERO
		return

	target_direction = -active_camera.global_basis.z
	if lock_upright:
		target_direction.y = 0.0

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

func _get_active_camera(movement_state: MovementState) -> Camera3D:
	if movement_state.camera != null:
		return movement_state.camera
	return get_viewport().get_camera_3d()
