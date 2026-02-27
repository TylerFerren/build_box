class_name MovementModeProfile
extends Resource

@export var mode_name: StringName
@export var movement_speed_multiplier: float = 1.0
@export var gravity_scale: float = 1.0

@export var restore_default_extension_activity: bool = true
@export var enabled_extensions: Array[NodePath] = []
@export var disabled_extensions: Array[NodePath] = []
