class_name AnimationController
extends Node

@export_group("Node Paths")
@export var character_body_path: NodePath
@export var movement_manager_path: NodePath
@export var animation_tree_path: NodePath

@export_group("Animation Tree")
@export var auto_activate_animation_tree: bool = true
@export var state_machine_playback_parameter_path: StringName = &"parameters/playback"

@export_group("State Names")
@export var locomotion_state_name: StringName = &"locomotion"
@export var falling_state_name: StringName = &"fall"
@export var jump_state_name: StringName = &"jump"
@export var impulse_state_name: StringName = &"dash"
@export var climb_state_name: StringName = MovementModeNames.CLIMBING

@export_group("State Lock")
@export var jump_state_lock_time: float = 0.18
@export var impulse_state_lock_time: float = 0.18

@export_group("Parameter Paths")
@export var horizontal_speed_parameter_path: StringName = &""
@export var normalized_speed_parameter_path: StringName = &""
@export var vertical_speed_parameter_path: StringName = &""
@export var move_input_x_parameter_path: StringName = &""
@export var move_input_y_parameter_path: StringName = &""
@export var is_grounded_parameter_path: StringName = &""
@export var is_crouching_parameter_path: StringName = &""
@export var is_sprinting_parameter_path: StringName = &""
@export var is_climbing_parameter_path: StringName = &""

@export_group("Speed Normalization")
@export var max_reference_speed: float = 8.0

var character_body: CharacterBody3D
var movement_manager: MovementManager
var animation_tree: AnimationTree
var state_machine_playback: AnimationNodeStateMachinePlayback

var jump_extension: Jump
var impulse_extension: Impulse
var crouch_extension: Crouch
var sprint_extension: Sprint
var climb_extension: Climb
var mode_manager: MovementModeManager

var last_move_input: Vector2 = Vector2.ZERO
var state_lock_timer: float = 0.0

func _ready() -> void:
	_resolve_nodes()
	_cache_extensions()
	_cache_state_machine_playback()
	_connect_signals()
	_set_animation_tree_active()

func _process(delta: float) -> void:
	_update_state_lock(delta)
	_sync_parameters()
	_apply_fallback_state()

func _resolve_nodes() -> void:
	character_body = _resolve_character_body()
	movement_manager = _resolve_movement_manager()
	animation_tree = _resolve_animation_tree()

func _resolve_character_body() -> CharacterBody3D:
	if character_body_path != NodePath():
		var node_at_path := get_node_or_null(character_body_path)
		if node_at_path is CharacterBody3D:
			return node_at_path as CharacterBody3D

	if get_parent() is CharacterBody3D:
		return get_parent() as CharacterBody3D

	return null

func _resolve_movement_manager() -> MovementManager:
	if movement_manager_path != NodePath():
		var node_at_path := get_node_or_null(movement_manager_path)
		if node_at_path is MovementManager:
			return node_at_path as MovementManager

	if get_parent() != null:
		var sibling_manager := get_parent().get_node_or_null("MovementManager")
		if sibling_manager is MovementManager:
			return sibling_manager as MovementManager

	return null

func _resolve_animation_tree() -> AnimationTree:
	if animation_tree_path != NodePath():
		var node_at_path := get_node_or_null(animation_tree_path)
		if node_at_path is AnimationTree:
			return node_at_path as AnimationTree

	if get_parent() != null:
		var sibling_tree := get_parent().get_node_or_null("AnimationTree")
		if sibling_tree is AnimationTree:
			return sibling_tree as AnimationTree

	return null

func _cache_extensions() -> void:
	if movement_manager == null:
		return

	jump_extension = movement_manager.get_node_or_null("Jump") as Jump
	impulse_extension = movement_manager.get_node_or_null("Impulse") as Impulse
	crouch_extension = movement_manager.get_node_or_null("Crouch") as Crouch
	sprint_extension = movement_manager.get_node_or_null("Sprint") as Sprint
	climb_extension = movement_manager.get_node_or_null("Climb") as Climb
	mode_manager = movement_manager.get_node_or_null("ModeManager") as MovementModeManager

func _cache_state_machine_playback() -> void:
	state_machine_playback = null
	if animation_tree == null:
		return
	if state_machine_playback_parameter_path == StringName():
		return

	var playback_variant: Variant = animation_tree.get(String(state_machine_playback_parameter_path))
	if playback_variant is AnimationNodeStateMachinePlayback:
		state_machine_playback = playback_variant as AnimationNodeStateMachinePlayback

func _connect_signals() -> void:
	if jump_extension != null and not jump_extension.jumped.is_connected(_on_jumped):
		jump_extension.jumped.connect(_on_jumped)

	if impulse_extension != null:
		if not impulse_extension.impulse_entered.is_connected(_on_impulse_entered):
			impulse_extension.impulse_entered.connect(_on_impulse_entered)

	if mode_manager != null:
		if not mode_manager.mode_entered.is_connected(_on_mode_entered):
			mode_manager.mode_entered.connect(_on_mode_entered)

func _set_animation_tree_active() -> void:
	if animation_tree == null:
		return
	if auto_activate_animation_tree:
		animation_tree.active = true

func _update_state_lock(delta: float) -> void:
	if state_lock_timer > 0.0:
		state_lock_timer = max(state_lock_timer - delta, 0.0)

func _sync_parameters() -> void:
	if animation_tree == null:
		return

	var active_velocity := Vector3.ZERO
	if character_body != null:
		active_velocity = character_body.velocity
	elif movement_manager != null and movement_manager.controller != null:
		active_velocity = movement_manager.controller.velocity

	var horizontal_velocity := Vector3(active_velocity.x, 0.0, active_velocity.z)
	var horizontal_speed := horizontal_velocity.length()

	var move_input := Vector2.ZERO
	if movement_manager != null:
		move_input = movement_manager.move_input
	last_move_input = move_input

	var normalized_speed := 0.0
	if max_reference_speed > 0.0:
		normalized_speed = clamp(horizontal_speed / max_reference_speed, 0.0, 1.0)

	var is_grounded := false
	if movement_manager != null:
		is_grounded = movement_manager.is_grounded

	var is_crouching := crouch_extension != null and crouch_extension.is_active
	var is_sprinting := sprint_extension != null and sprint_extension.is_active
	var is_climbing := mode_manager != null and mode_manager.current_mode == MovementModeNames.CLIMBING

	_set_tree_parameter(horizontal_speed_parameter_path, horizontal_speed)
	_set_tree_parameter(normalized_speed_parameter_path, normalized_speed)
	_set_tree_parameter(vertical_speed_parameter_path, active_velocity.y)
	_set_tree_parameter(move_input_x_parameter_path, move_input.x)
	_set_tree_parameter(move_input_y_parameter_path, move_input.y)
	_set_tree_parameter(is_grounded_parameter_path, is_grounded)
	_set_tree_parameter(is_crouching_parameter_path, is_crouching)
	_set_tree_parameter(is_sprinting_parameter_path, is_sprinting)
	_set_tree_parameter(is_climbing_parameter_path, is_climbing)

func _set_tree_parameter(parameter_path: StringName, value: Variant) -> void:
	if animation_tree == null:
		return
	if parameter_path == StringName():
		return
	animation_tree.set(String(parameter_path), value)

func _apply_fallback_state() -> void:
	if state_machine_playback == null:
		return
	if state_lock_timer > 0.0:
		return

	if mode_manager != null and mode_manager.current_mode == MovementModeNames.CLIMBING:
		_travel_to_state(climb_state_name)
		return

	var is_grounded := movement_manager != null and movement_manager.is_grounded
	if not is_grounded:
		_travel_to_state(falling_state_name)
		return

	_travel_to_state(locomotion_state_name)

func _travel_to_state(state_name: StringName) -> void:
	if state_machine_playback == null:
		return
	if state_name == StringName():
		return
	if state_machine_playback.get_current_node() == String(state_name):
		return
	state_machine_playback.travel(String(state_name))

func _on_jumped() -> void:
	_travel_to_state(jump_state_name)
	state_lock_timer = max(state_lock_timer, jump_state_lock_time)

func _on_impulse_entered() -> void:
	_travel_to_state(impulse_state_name)
	state_lock_timer = max(state_lock_timer, impulse_state_lock_time)

func _on_mode_entered(mode_name: StringName) -> void:
	if mode_name == MovementModeNames.CLIMBING:
		_travel_to_state(climb_state_name)
