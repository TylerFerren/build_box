class_name MovementModeManager
extends Node

signal mode_changed(previous_mode: StringName, current_mode: StringName)
signal mode_exited(mode_name: StringName)
signal mode_entered(mode_name: StringName)

@export var starting_mode: StringName
@export var mode_switch_lock_duration: float = 0.05
@export var default_transition_cooldown_duration: float = 0.05

var movement_manager: MovementManager
var current_mode: StringName = StringName()
var time_in_current_mode: float = 0.0

var default_extension_active_state: Dictionary = {}
var mode_nodes_by_name: Dictionary = {}
var current_mode_node: MovementMode
var mode_switch_lock_remaining: float = 0.0
var transition_cooldown_remaining_by_key: Dictionary = {}

func _ready() -> void:
	if movement_manager == null and get_parent() is MovementManager:
		set_movement_manager(get_parent() as MovementManager)

	_cache_child_modes()
	_validate_mode_setup()
	_initialize_starting_mode()

func set_movement_manager(new_movement_manager: MovementManager) -> void:
	movement_manager = new_movement_manager
	_cache_default_extension_state()

func set_mode(mode_name: StringName) -> bool:
	return _set_mode_using_child_modes(mode_name)

func evaluate_mode_transitions(movement_state: MovementState, delta: float) -> void:
	time_in_current_mode += delta
	_update_transition_timers(delta)

	if mode_switch_lock_remaining > 0.0:
		return

	if bool(movement_state.metadata.get("suppress_mode_transitions", false)):
		return

	if current_mode_node == null:
		return

	for transition_rule in current_mode_node.transition_rules:
		if transition_rule == null:
			continue
		if _is_transition_on_cooldown(current_mode, transition_rule.to_mode):
			continue
		if not transition_rule.can_transition(current_mode, time_in_current_mode, movement_state):
			continue

		var from_mode_name: StringName = current_mode
		if _set_mode_using_child_modes(transition_rule.to_mode):
			_start_transition_cooldowns(from_mode_name, transition_rule)
		return

func get_registered_mode_names() -> Array[StringName]:
	var registered_mode_names: Array[StringName] = []
	for mode_key_variant in mode_nodes_by_name.keys():
		var mode_key: StringName = mode_key_variant as StringName
		registered_mode_names.append(mode_key)
	return registered_mode_names

func _initialize_starting_mode() -> void:
	if not _has_child_modes():
		return

	var initial_mode_name := starting_mode
	if initial_mode_name == StringName():
		var child_mode_names: Array[StringName] = get_registered_mode_names()
		if not child_mode_names.is_empty():
			initial_mode_name = child_mode_names[0]
	set_mode(initial_mode_name)

func _cache_child_modes() -> void:
	mode_nodes_by_name.clear()
	current_mode_node = null

	for child in get_children():
		if child is not MovementMode:
			continue
		var child_mode := child as MovementMode
		var child_mode_name := child_mode.get_mode_name_or_fallback()
		if child_mode_name == StringName():
			continue
		if mode_nodes_by_name.has(child_mode_name):
			push_warning("Duplicate movement mode '%s' on node '%s'." % [String(child_mode_name), child.name])
			continue
		mode_nodes_by_name[child_mode_name] = child_mode

func _has_child_modes() -> bool:
	return not mode_nodes_by_name.is_empty()

func _set_mode_using_child_modes(mode_name: StringName) -> bool:
	if not mode_nodes_by_name.has(mode_name):
		return false

	var next_mode_node := mode_nodes_by_name[mode_name] as MovementMode
	if next_mode_node == null:
		return false

	if current_mode == mode_name:
		return false

	var previous_mode := current_mode
	_apply_mode_node(next_mode_node)
	current_mode_node = next_mode_node
	current_mode = mode_name
	time_in_current_mode = 0.0

	if previous_mode != StringName():
		mode_exited.emit(previous_mode)
		mode_switch_lock_remaining = max(mode_switch_lock_duration, 0.0)
	mode_entered.emit(current_mode)
	mode_changed.emit(previous_mode, current_mode)
	return true

func _cache_default_extension_state() -> void:
	default_extension_active_state.clear()
	if movement_manager == null:
		return

	for extension in movement_manager.extensions:
		var extension_path := String(movement_manager.get_path_to(extension))
		default_extension_active_state[extension_path] = extension.is_active

func _apply_mode_node(mode_node: MovementMode) -> void:
	if movement_manager == null:
		return

	movement_manager.set_mode_multipliers(
		mode_node.resolve_speed_multiplier(),
		mode_node.resolve_gravity_scale()
	)

	if mode_node.restore_default_extension_activity:
		_restore_default_extension_state()

	_clear_extension_mode_overrides()

	for extension_path in mode_node.enabled_extensions:
		var extension_node := movement_manager.get_node_or_null(extension_path) as MovementExtension
		if extension_node != null:
			extension_node.request_active_state(true)

	for extension_path in mode_node.disabled_extensions:
		if extension_path == NodePath():
			continue
		var extension_node := movement_manager.get_node_or_null(extension_path) as MovementExtension
		if extension_node != null:
			extension_node.request_active_state(false)

	_apply_extension_mode_overrides(mode_node)

func _restore_default_extension_state() -> void:
	if movement_manager == null:
		return

	for extension_path in default_extension_active_state.keys():
		var extension_node := movement_manager.get_node_or_null(NodePath(extension_path)) as MovementExtension
		if extension_node == null:
			continue
		var default_is_active := bool(default_extension_active_state[extension_path])
		extension_node.request_active_state(default_is_active)

func _clear_extension_mode_overrides() -> void:
	if movement_manager == null:
		return
	for extension in movement_manager.extensions:
		extension.clear_mode_override()

func _apply_extension_mode_overrides(mode_node: MovementMode) -> void:
	if movement_manager == null:
		return
	if not mode_node.apply_extension_overrides:
		return

	var mode_override_entries := mode_node.get_extension_override_entries()
	for mode_override_entry in mode_override_entries:
		if mode_override_entry == null:
			continue
		if not mode_override_entry.can_apply():
			continue

		var extension_node := _resolve_mode_override_target_extension(mode_override_entry)
		if extension_node == null:
			push_warning(
				"Mode '%s' override target is missing: %s"
				% [String(mode_node.get_mode_name_or_fallback()), String(mode_override_entry.target_extension_path)]
			)
			continue

		mode_override_entry.apply_extension_active_state(extension_node)
		mode_override_entry.apply_to_extension(extension_node)

func _update_transition_timers(delta: float) -> void:
	mode_switch_lock_remaining = max(mode_switch_lock_remaining - delta, 0.0)

	if transition_cooldown_remaining_by_key.is_empty():
		return

	var keys_to_clear: Array[String] = []
	for transition_key_variant in transition_cooldown_remaining_by_key.keys():
		var transition_key: String = String(transition_key_variant)
		var remaining_time: float = float(transition_cooldown_remaining_by_key[transition_key]) - delta
		if remaining_time <= 0.0:
			keys_to_clear.append(transition_key)
		else:
			transition_cooldown_remaining_by_key[transition_key] = remaining_time

	for expired_key in keys_to_clear:
		transition_cooldown_remaining_by_key.erase(expired_key)

func _is_transition_on_cooldown(from_mode: StringName, to_mode: StringName) -> bool:
	var transition_key := _make_transition_key(from_mode, to_mode)
	return float(transition_cooldown_remaining_by_key.get(transition_key, 0.0)) > 0.0

func _start_transition_cooldowns(from_mode: StringName, transition_rule: MovementModeTransitionRule) -> void:
	var rule_cooldown : float = max(transition_rule.cooldown_duration, 0.0)
	var cooldown_duration : float = max(default_transition_cooldown_duration, rule_cooldown)
	if cooldown_duration <= 0.0:
		return
	var transition_key := _make_transition_key(from_mode, transition_rule.to_mode)
	transition_cooldown_remaining_by_key[transition_key] = cooldown_duration

func _make_transition_key(from_mode: StringName, to_mode: StringName) -> String:
	return "%s->%s" % [String(from_mode), String(to_mode)]

func _validate_mode_setup() -> void:
	if mode_nodes_by_name.is_empty():
		push_warning("MovementModeManager has no MovementMode child nodes.")
		return

	if starting_mode != StringName() and not mode_nodes_by_name.has(starting_mode):
		push_warning("Starting mode '%s' is not defined by any MovementMode node." % [String(starting_mode)])

	for mode_node_variant in mode_nodes_by_name.values():
		var mode_node := mode_node_variant as MovementMode
		if mode_node == null:
			continue
		for transition_rule in mode_node.transition_rules:
			if transition_rule == null:
				continue
			if transition_rule.to_mode == StringName():
				push_warning("Mode '%s' contains a transition rule with no target mode." % [String(mode_node.get_mode_name_or_fallback())])
				continue
			if not mode_nodes_by_name.has(transition_rule.to_mode):
				push_warning(
					"Mode '%s' transition target '%s' does not exist."
					% [String(mode_node.get_mode_name_or_fallback()), String(transition_rule.to_mode)]
				)

		if not mode_node.apply_extension_overrides:
			continue

		for mode_override_entry in mode_node.get_extension_override_entries():
			if mode_override_entry == null:
				continue
			if mode_override_entry.target_extension_path == NodePath():
				push_warning(
					"Mode '%s' has override entry '%s' without target extension path."
					% [String(mode_node.get_mode_name_or_fallback()), mode_override_entry.name]
				)
				continue

			if _resolve_mode_override_target_extension(mode_override_entry) == null:
				push_warning(
					"Mode '%s' override entry '%s' cannot resolve target path '%s'."
					% [
						String(mode_node.get_mode_name_or_fallback()),
						mode_override_entry.name,
						String(mode_override_entry.target_extension_path)
					]
				)

func _resolve_mode_override_target_extension(mode_override_entry: ExtensionModeOverride) -> MovementExtension:
	if movement_manager == null or mode_override_entry == null:
		return null
	if mode_override_entry.target_extension_path == NodePath():
		return null

	# Prefer paths relative to the override node for editor-friendly setup.
	var local_target_extension := mode_override_entry.get_node_or_null(mode_override_entry.target_extension_path) as MovementExtension
	if local_target_extension != null:
		return local_target_extension

	# Fallback to paths relative to MovementManager for direct references.
	return movement_manager.get_node_or_null(mode_override_entry.target_extension_path) as MovementExtension
