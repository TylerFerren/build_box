@abstract
class_name MovementExtension
extends Node

enum ExtensionBlendMode {ADDITIVE, SUBTRACTIVE, OVERRIDING, CONSTANT}

var manager :  MovementManager
@export var blend_mode : ExtensionBlendMode = ExtensionBlendMode.ADDITIVE

var is_active : bool = true

func set_active(value: bool):
	is_active = value

var movement_vector : Vector3
func get_movement_vector(_delta: float = 0.0) -> Vector3 :
	return movement_vector
	
var rotation_vector : Vector3
func get_rotation_vector(_delta: float = 0.0) -> Vector3 :
	return rotation_vector
