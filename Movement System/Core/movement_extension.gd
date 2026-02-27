@abstract
class_name MovementExtension
extends Node

enum ExtensionBlendMode {ADDITIVE, SUBTRACTIVE, OVERRIDING, CONSTANT}

var manager :  MovementManager
@export var blend_mode : ExtensionBlendMode = ExtensionBlendMode.ADDITIVE
@export var affects_movement: bool = true
@export var affects_rotation: bool = false
@export var allowed_modes: Array[StringName] = []
@export var blocked_modes: Array[StringName] = []

var is_active : bool = true

func set_active(value: bool) -> void:
	is_active = value

func is_mode_allowed(mode_name: StringName) -> bool:
	if not allowed_modes.is_empty() and not allowed_modes.has(mode_name):
		return false
	if blocked_modes.has(mode_name):
		return false
	return true

func update_extension_state(_movement_state: MovementState, _delta: float) -> void:
	pass

func get_movement_velocity(_movement_state: MovementState, _delta: float) -> Vector3:
	return Vector3.ZERO

func get_rotation_euler(_movement_state: MovementState, _delta: float) -> Vector3:
	return Vector3.ZERO
