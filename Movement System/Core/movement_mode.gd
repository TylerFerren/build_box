class_name MovementMode
extends Node

@export var mode_name: StringName
@export var movement_speed_multiplier: float = 1.0
@export var gravity_scale: float = 1.0

@export var restore_default_extension_activity: bool = true
@export var enabled_extensions: Array[NodePath] = []
@export var disabled_extensions: Array[NodePath] = []
@export_group("Extension Overrides")
@export var apply_extension_overrides: bool = true

@export var state_setting_overrides: Array[MovementStateSettingOverride] = []
@export var transition_rules: Array[MovementModeTransitionRule] = []

func get_mode_name_or_fallback() -> StringName:
	if mode_name != StringName():
		return mode_name
	return StringName(name.to_lower())

func resolve_speed_multiplier() -> float:
	var resolved_speed_multiplier := movement_speed_multiplier
	for setting_override in state_setting_overrides:
		if setting_override == null:
			continue
		if setting_override.setting_key == MovementStateSettingOverride.SettingKey.SPEED_MULTIPLIER:
			resolved_speed_multiplier = setting_override.value
	return resolved_speed_multiplier

func resolve_gravity_scale() -> float:
	var resolved_gravity_scale := gravity_scale
	for setting_override in state_setting_overrides:
		if setting_override == null:
			continue
		if setting_override.setting_key == MovementStateSettingOverride.SettingKey.GRAVITY_SCALE:
			resolved_gravity_scale = setting_override.value
	return resolved_gravity_scale

func get_extension_override_entries() -> Array[ExtensionModeOverride]:
	var extension_override_entries: Array[ExtensionModeOverride] = []

	for child_node in get_children():
		var mode_override_entry := child_node as ExtensionModeOverride
		if mode_override_entry != null:
			extension_override_entries.append(mode_override_entry)

	return extension_override_entries
