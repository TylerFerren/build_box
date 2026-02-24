class_name Rotation
extends MovementExtension

enum RotationDriver {MOVEMENT_DIRECTION, INPUT_DIRECTION, FOLLOW_CAMERA, CURSOR_BASED}

@export var rotation_driver : RotationDriver = RotationDriver.MOVEMENT_DIRECTION
@export_range(0 , 1440) var rotation_speed = 360
@export var only_rotate_on_move : bool = false
@export var lock_upright : bool = true
@export var cursor_ray_length : float = 1000.0


var target_direction : Vector3
var target_rotation : Vector3
var smooth_rotation : Vector3

func get_rotation_vector(_delta: float = 0.0) -> Vector3:
	match rotation_driver:
		RotationDriver.MOVEMENT_DIRECTION:
			rotate_towards_movement()
		RotationDriver.INPUT_DIRECTION:
			rotate_towards_input()
		RotationDriver.FOLLOW_CAMERA:
			rotate_following_camera()
		RotationDriver.CURSOR_BASED:
			rotate_towards_cursor()

	if target_direction.length_squared() == 0.0 and only_rotate_on_move:
		return smooth_rotation
	
	var _horizontal_length := Vector2(target_direction.x, target_direction.z).length()
	var _pitch_rotation := -atan2(target_direction.y, _horizontal_length)
	var _yaw_rotation := atan2(-target_direction.x, -target_direction.z)
	var _roll_rotation := atan2(target_direction.x, _horizontal_length)
	
	if lock_upright:
		target_rotation = Vector3(0,_yaw_rotation,0)
	else:
		target_rotation = Vector3(_pitch_rotation, _yaw_rotation, _roll_rotation)
	
	var _max_step := deg_to_rad(rotation_speed) * _delta
	smooth_rotation = Vector3(
		move_toward(smooth_rotation.x, target_rotation.x, _max_step),
		rotate_toward(smooth_rotation.y, target_rotation.y, _max_step),
		move_toward(smooth_rotation.z, target_rotation.z, _max_step)
	)
	return smooth_rotation

func rotate_towards_movement():
	target_direction = manager.movement_vector

var move_input : Vector2
func set_move_input(_input_value : Vector2):
	move_input = _input_value

func rotate_towards_input():
	var _input_direction := Vector3(move_input.x, 0, move_input.y)
	target_direction = manager.get_camera_relative_input(_input_direction)
	if lock_upright:
		target_direction.y = 0.0
	

func rotate_following_camera():
	var _camera := _get_active_camera()
	if _camera == null:
		target_direction = Vector3.ZERO
		return

	target_direction = -_camera.global_basis.z
	if lock_upright:
		target_direction.y = 0.0

var cursor_position : Vector3
func rotate_towards_cursor():
	var _camera := _get_active_camera()
	if _camera == null:
		target_direction = Vector3.ZERO
		return
	
	var _mouse_position := get_viewport().get_mouse_position()
	var _ray_origin := _camera.project_ray_origin(_mouse_position)
	var _ray_direction := _camera.project_ray_normal(_mouse_position)
	var _ray_end := _ray_origin + (_ray_direction * cursor_ray_length)
	
	var _query := PhysicsRayQueryParameters3D.create(_ray_origin, _ray_end)
	_query.exclude = [manager.controller.get_rid()]
	_query.collide_with_areas = true
	
	var _space_state := manager.controller.get_world_3d().direct_space_state
	var _hit := _space_state.intersect_ray(_query)
	
	if _hit.has("position"):
		cursor_position = _hit["position"]
	else:
		var _ground_plane := Plane(Vector3.UP, manager.controller.global_position.y)
		var _plane_hit = _ground_plane.intersects_ray(_ray_origin, _ray_direction)
		if _plane_hit == null:
			target_direction = Vector3.ZERO
			return
		cursor_position = _plane_hit
	
	target_direction = cursor_position - manager.controller.global_position
	if lock_upright:
		target_direction.y = 0.0

func _get_active_camera() -> Camera3D:
	if manager and manager.camera:
		return manager.camera
	return get_viewport().get_camera_3d()
