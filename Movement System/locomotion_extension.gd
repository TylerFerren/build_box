class_name Locomotion
extends MovementExtension

@export var speed : float = 5
@export var acceleration : float = 3;
@export var decceleration : float  = 5;
@export var directional_acceleration : float = 4;

var move_input : Vector2
func set_move_input(_input_value : Vector2):
	move_input = _input_value

func get_movement_vector(_delta: float = 0.0) -> Vector3:
	movement_vector = get_speed(_delta) * get_direction(_delta)
	return super.get_movement_vector(_delta)

var _target_direction := Vector3.ZERO
var _smoothed_direction := Vector3.ZERO
func get_direction(_delta : float) -> Vector3:
	var _relative_input = manager.get_camera_relative_input(Vector3(move_input.x, 0, move_input.y))
	_target_direction = _relative_input
	#_target_direction = Vector3(move_input.x, 0, move_input.y)
	_smoothed_direction = lerp(_smoothed_direction, _target_direction, directional_acceleration * _delta)
	return _smoothed_direction

var _target_speed : float = 0
var _smoothed_speed : float = 0
func get_speed(_delta : float) -> float:
	_target_speed = speed * move_input.length()
	if _target_speed > 0:
		_smoothed_speed = lerp(_smoothed_speed, _target_speed, acceleration * _delta)
	else:
		_smoothed_speed = lerp(_smoothed_speed, _target_speed, decceleration * _delta)
	return _smoothed_speed
