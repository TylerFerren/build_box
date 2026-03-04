@abstract
class_name ExtensionModeOverride
extends Node

@export var enabled: bool = true
@export var target_extension_path: NodePath
@export_group("Activation")
@export var override_extension_active_state: bool = false
@export var extension_should_be_active: bool = true

func can_apply() -> bool:
	return enabled and target_extension_path != NodePath()

func apply_extension_active_state(target_extension: MovementExtension) -> void:
	if target_extension == null:
		return
	if not override_extension_active_state:
		return
	target_extension.request_active_state(extension_should_be_active)

@abstract
func apply_to_extension(_target_extension: MovementExtension) -> void
