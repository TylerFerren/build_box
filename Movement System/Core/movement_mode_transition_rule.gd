class_name MovementModeTransitionRule
extends Resource

enum TransitionCondition {
	IS_GROUNDED,
	NOT_GROUNDED,
	IS_ON_WALL,
	NOT_ON_WALL,
	IS_CROUCHING,
	NOT_CROUCHING,
	HAS_MOVE_INPUT,
	NO_MOVE_INPUT,
	MIN_SPEED,
	MAX_SPEED
}

@export var from_mode: StringName = StringName()
@export var to_mode: StringName = StringName()
@export var minimum_time_in_mode: float = 0.0
@export var required_conditions: Array[TransitionCondition] = []
@export var speed_threshold: float = 0.0

func can_transition(
	current_mode: StringName,
	time_in_current_mode: float,
	movement_state: MovementState
) -> bool:
	if to_mode == StringName():
		return false

	if from_mode != StringName() and from_mode != current_mode:
		return false

	if time_in_current_mode < minimum_time_in_mode:
		return false

	for condition in required_conditions:
		if not _evaluate_condition(condition, movement_state):
			return false

	return true

func _evaluate_condition(condition: TransitionCondition, movement_state: MovementState) -> bool:
	match condition:
		TransitionCondition.IS_GROUNDED:
			return movement_state.is_grounded
		TransitionCondition.NOT_GROUNDED:
			return not movement_state.is_grounded
		TransitionCondition.IS_ON_WALL:
			return movement_state.is_on_wall
		TransitionCondition.NOT_ON_WALL:
			return not movement_state.is_on_wall
		TransitionCondition.IS_CROUCHING:
			return movement_state.is_crouching
		TransitionCondition.NOT_CROUCHING:
			return not movement_state.is_crouching
		TransitionCondition.HAS_MOVE_INPUT:
			return movement_state.move_input.length_squared() > 0.0
		TransitionCondition.NO_MOVE_INPUT:
			return movement_state.move_input.length_squared() <= 0.0
		TransitionCondition.MIN_SPEED:
			return movement_state.current_velocity.length() >= speed_threshold
		TransitionCondition.MAX_SPEED:
			return movement_state.current_velocity.length() <= speed_threshold
		_:
			return false
