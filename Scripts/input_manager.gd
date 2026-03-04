class_name InputManager
extends Node

# InputManager.gd

signal move(direction: Vector2)
signal jump_pressed
signal jump_released
signal dash_pressed
signal sprint_pressed
signal sprint_released
signal crouch_pressed
signal crouch_released
signal flight_toggle_pressed
signal flight_transition_pressed
signal attack_pressed
signal interact_pressed
signal action_pressed(action_name: StringName)
signal action_released(action_name: StringName)

@export_group("Movement Input")
@export var move_left_action: StringName = &"move_left"
@export var move_right_action: StringName = &"move_right"
@export var move_up_action: StringName = &"move_up"
@export var move_down_action: StringName = &"move_down"

@export_group("Editor Action Routes")
@export var action_routes: Array[InputActionRoute] = []
@export_group("Validation")
@export var required_action_names: Array[StringName] = [
	&"jump",
	&"dash",
	&"sprint",
	&"crouch",
	&"flight_toggle",
	&"flight_transition"
]

func _ready() -> void:
	_validate_actions()

func _physics_process(_delta: float) -> void:
	_handle_movement()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump_pressed.emit()
	elif event.is_action_released("jump"):
		jump_released.emit()

	if event.is_action_pressed("dash"):
		dash_pressed.emit()

	if event.is_action_pressed("sprint"):
		sprint_pressed.emit()
	elif event.is_action_released("sprint"):
		sprint_released.emit()

	if event.is_action_pressed("crouch"):
		crouch_pressed.emit()
	elif event.is_action_released("crouch"):
		crouch_released.emit()

	if event.is_action_pressed("flight_toggle"):
		flight_toggle_pressed.emit()

	if event.is_action_pressed("flight_transition"):
		flight_transition_pressed.emit()

	if event.is_action_pressed("attack"):
		attack_pressed.emit()

	if event.is_action_pressed("interact"):
		interact_pressed.emit()

	_process_action_routes(event)

var move_input: Vector2 = Vector2.ZERO
func _handle_movement() -> void:
	var current_move_input: Vector2 = Input.get_vector(move_left_action, move_right_action, move_up_action, move_down_action)
	if current_move_input != move_input:
		move_input = current_move_input
		move.emit(move_input)
	#if direction != Vector2.ZERO:
		#move.emit(direction)

func _process_action_routes(event: InputEvent) -> void:
	for action_route in action_routes:
		if action_route == null or action_route.action_name == StringName():
			continue

		match action_route.trigger_type:
			InputActionRoute.TriggerType.PRESSED:
				if event.is_action_pressed(action_route.action_name):
					action_pressed.emit(action_route.action_name)
					_invoke_action_route(action_route)
			InputActionRoute.TriggerType.RELEASED:
				if event.is_action_released(action_route.action_name):
					action_released.emit(action_route.action_name)
					_invoke_action_route(action_route)

func _invoke_action_route(action_route: InputActionRoute) -> void:
	if action_route.target_callable.is_null():
		return

	if not action_route.target_callable.is_valid():
		push_warning("Input route callable is invalid for action: %s" % [String(action_route.action_name)])
		return

	if action_route.pass_action_name_argument:
		action_route.target_callable.call(action_route.action_name)
	else:
		action_route.target_callable.call()

func _validate_actions() -> void:
	var movement_actions: Array[StringName] = [
		move_left_action,
		move_right_action,
		move_up_action,
		move_down_action
	]
	for action_name in movement_actions:
		if action_name == StringName():
			push_warning("InputManager has an empty movement action reference.")
			continue
		if not InputMap.has_action(action_name):
			push_warning("InputManager movement action '%s' does not exist." % [String(action_name)])

	for action_name in required_action_names:
		if action_name == StringName():
			continue
		if not InputMap.has_action(action_name):
			push_warning("InputManager required action '%s' does not exist." % [String(action_name)])
