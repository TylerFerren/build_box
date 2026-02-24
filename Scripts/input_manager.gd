class_name InputManager
extends Node

# InputManager.gd

signal move(direction: Vector2)
signal jump_pressed
signal jump_released
signal attack_pressed
signal interact_pressed

func _process(_delta: float) -> void:
	_handle_movement()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump_pressed.emit()
	elif event.is_action_released("jump"):
		jump_released.emit()

	if event.is_action_pressed("attack"):
		attack_pressed.emit()

	if event.is_action_pressed("interact"):
		interact_pressed.emit()

var move_input : Vector2
func _handle_movement() -> void:
	var _move_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if _move_input != move_input:
		move_input = _move_input
		move.emit(move_input)
	#if direction != Vector2.ZERO:
		#move.emit(direction)
