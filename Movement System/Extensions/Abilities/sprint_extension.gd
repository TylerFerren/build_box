class_name Sprint
extends MovementExtension

@export var sprint_speed_multiplier: float = 1.75
@export var require_grounded: bool = true
@export var require_move_input: bool = true
@export var use_toggle_input: bool = false

signal sprint_entered
signal sprint_exited

var sprint_pressed_requested: bool = false
var sprint_released_requested: bool = false

func _ready() -> void:
	affects_movement = false
	affects_rotation = false
	if allowed_modes.is_empty():
		allowed_modes = [&"ground"]
	is_active = false

func on_sprint_pressed() -> void:
	sprint_pressed_requested = true

func on_sprint_released() -> void:
	sprint_released_requested = true

func update_extension_state(movement_state: MovementState, _delta: float) -> void:
	var was_active: bool = is_active

	if use_toggle_input:
		if sprint_pressed_requested:
			is_active = not is_active
	else:
		if sprint_pressed_requested:
			is_active = true
		if sprint_released_requested:
			is_active = false

	sprint_pressed_requested = false
	sprint_released_requested = false

	if not was_active and is_active:
		sprint_entered.emit()
	elif was_active and not is_active:
		sprint_exited.emit()

	if not is_active:
		return
	if require_grounded and not movement_state.is_grounded:
		return
	if require_move_input and movement_state.move_input.length_squared() <= 0.0:
		return

	movement_state.speed_multiplier *= sprint_speed_multiplier
