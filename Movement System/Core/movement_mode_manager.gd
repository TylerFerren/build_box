class_name MovementModeManager
extends Node

signal mode_changed(previous_mode: StringName, current_mode: StringName)
signal mode_exited(mode_name: StringName)
signal mode_entered(mode_name: StringName)

@export var mode_profiles: Array[MovementModeProfile] = []
@export var starting_mode: StringName
@export var transition_rules: Array[MovementModeTransitionRule] = []

var movement_manager: MovementManager
var current_mode: StringName = StringName()
var time_in_current_mode: float = 0.0

var default_extension_active_state: Dictionary = {}

func _ready() -> void:
	if movement_manager == null and get_parent() is MovementManager:
		set_movement_manager(get_parent() as MovementManager)

	if mode_profiles.is_empty():
		return

	var initial_mode_name := starting_mode
	if initial_mode_name == StringName():
		initial_mode_name = mode_profiles[0].mode_name

	set_mode(initial_mode_name)

func set_movement_manager(new_movement_manager: MovementManager) -> void:
	movement_manager = new_movement_manager
	_cache_default_extension_state()

func set_mode(mode_name: StringName) -> bool:
	var mode_profile := _find_mode_profile(mode_name)
	if mode_profile == null:
		return false
	if current_mode == mode_profile.mode_name:
		return false

	var previous_mode := current_mode
	_apply_mode_profile(mode_profile)
	current_mode = mode_profile.mode_name
	time_in_current_mode = 0.0
	if previous_mode != StringName():
		mode_exited.emit(previous_mode)
	mode_entered.emit(current_mode)
	mode_changed.emit(previous_mode, current_mode)
	return true

func evaluate_mode_transitions(movement_state: MovementState, delta: float) -> void:
	time_in_current_mode += delta

	for transition_rule in transition_rules:
		if transition_rule == null:
			continue
		if transition_rule.can_transition(current_mode, time_in_current_mode, movement_state):
			set_mode(transition_rule.to_mode)
			return

func _find_mode_profile(mode_name: StringName) -> MovementModeProfile:
	for mode_profile in mode_profiles:
		if mode_profile != null and mode_profile.mode_name == mode_name:
			return mode_profile
	return null

func _cache_default_extension_state() -> void:
	default_extension_active_state.clear()
	if movement_manager == null:
		return

	for extension in movement_manager.extensions:
		var extension_path := String(movement_manager.get_path_to(extension))
		default_extension_active_state[extension_path] = extension.is_active

func _apply_mode_profile(mode_profile: MovementModeProfile) -> void:
	if movement_manager == null:
		return

	movement_manager.set_mode_multipliers(
		mode_profile.movement_speed_multiplier,
		mode_profile.gravity_scale
	)

	if mode_profile.restore_default_extension_activity:
		_restore_default_extension_state()

	for extension_path in mode_profile.enabled_extensions:
		var extension_node := movement_manager.get_node_or_null(extension_path) as MovementExtension
		if extension_node != null:
			extension_node.set_active(true)

	for extension_path in mode_profile.disabled_extensions:
		var extension_node := movement_manager.get_node_or_null(extension_path) as MovementExtension
		if extension_node != null:
			extension_node.set_active(false)

func _restore_default_extension_state() -> void:
	if movement_manager == null:
		return

	for extension_path in default_extension_active_state.keys():
		var extension_node := movement_manager.get_node_or_null(NodePath(extension_path)) as MovementExtension
		if extension_node == null:
			continue
		var default_is_active := bool(default_extension_active_state[extension_path])
		extension_node.set_active(default_is_active)
