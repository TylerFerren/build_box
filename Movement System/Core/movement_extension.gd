@abstract
class_name MovementExtension
extends Node

enum ExtensionBlendMode {ADDITIVE, SUBTRACTIVE, OVERRIDING, CONSTANT}

signal extension_entered
signal extension_exited
signal extension_active_changed(is_active: bool)

var manager :  MovementManager
@export var blend_mode : ExtensionBlendMode = ExtensionBlendMode.ADDITIVE
@export var affects_movement: bool = true
@export var affects_rotation: bool = false

var is_active : bool = true

func set_active(value: bool) -> void:
	request_active_state(value)

func request_active_state(should_be_active: bool) -> void:
	if is_active == should_be_active:
		return
	is_active = should_be_active
	extension_active_changed.emit(is_active)
	if is_active:
		extension_entered.emit()
	else:
		extension_exited.emit()

func update_extension_state(_movement_state: MovementState, _delta: float) -> void:
	pass

func get_movement_velocity(_movement_state: MovementState, _delta: float) -> Vector3:
	return Vector3.ZERO

func get_rotation_euler(_movement_state: MovementState, _delta: float) -> Vector3:
	return Vector3.ZERO

func clear_mode_override() -> void:
	pass
