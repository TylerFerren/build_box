class_name MovementState
extends RefCounted

var delta_time: float = 0.0
var is_grounded: bool = false
var ground_normal : Vector3 = Vector3.UP
var is_on_wall: bool = false
var wall_normal: Vector3 = Vector3.ZERO
var current_velocity: Vector3 = Vector3.ZERO
var up_direction: Vector3 = Vector3.UP
var character_global_position: Vector3 = Vector3.ZERO

var camera: Camera3D = null
var move_input: Vector2 = Vector2.ZERO
var base_speed_multiplier: float = 1.0
var base_gravity_scale: float = 1.0
var speed_multiplier: float = 1.0
var gravity_scale: float = 1.0
var is_crouching: bool = false
var current_mode: StringName = StringName()

var metadata: Dictionary = {}
