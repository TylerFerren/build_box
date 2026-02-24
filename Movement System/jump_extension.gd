class_name Jump
extends MovementExtension

@export var jump_height: float = 3.0
@export var air_jumps: int = 1
@export var fast_fall_multiplier: float = 2.0
@export var low_jump_multiplier: float = 2.0
@export var coyote_time: float = 0.2

signal jumped

var can_jump: bool = false
var jump_velocity: float = 0.0
var active_fast_fall_multiplier: float = 1.0
var active_low_jump_multiplier: float = 1.0
var coyote_timer: float = 0.0
var gravity_magnitude: float = 9.8
var current_air_jump_count: int = 0

func _ready() -> void:
	gravity_magnitude = _get_gravity_magnitude()

func on_jump_pressed() -> void:
	try_jump()

func on_jump_released() -> void:
	active_low_jump_multiplier = low_jump_multiplier

func try_jump() -> void:
	if manager == null or manager.controller == null:
		return

	gravity_magnitude = _get_gravity_magnitude()

	if manager.is_grounded:
		current_air_jump_count = 0
	elif can_jump:
		can_jump = false
	elif current_air_jump_count >= air_jumps:
		return

	jump_velocity = sqrt(2.0 * jump_height * gravity_magnitude)

	# Offset falling speed so jump remains responsive while descending.
	if manager.controller.velocity.y < 0.0:
		jump_velocity -= manager.controller.velocity.y

	active_fast_fall_multiplier = 1.0
	active_low_jump_multiplier = 1.0
	is_active = true

	if not can_jump:
		current_air_jump_count += 1

	jumped.emit()

func get_movement_vector(delta: float = 0.0) -> Vector3:
	_update_coyote_time(delta)

	if is_active:
		if manager.controller.velocity.y < 0.0 and is_equal_approx(active_fast_fall_multiplier, 1.0):
			active_fast_fall_multiplier = fast_fall_multiplier

		if jump_velocity > 0.0:
			jump_velocity -= active_fast_fall_multiplier * active_low_jump_multiplier * gravity_magnitude * delta

		jump_velocity = max(jump_velocity, 0.0)
		if jump_velocity <= 0.0:
			is_active = false

		movement_vector = manager.controller.up_direction * jump_velocity
		return movement_vector

	movement_vector = Vector3.ZERO
	return movement_vector

func _update_coyote_time(delta: float) -> void:
	if manager.is_grounded and not is_active:
		coyote_timer = coyote_time
		can_jump = true
		return

	if can_jump:
		coyote_timer -= delta
		if coyote_timer <= 0.0:
			coyote_timer = 0.0
			can_jump = false

func _get_gravity_magnitude() -> float:
	if manager != null:
		for _extension in manager.get_children():
			if _extension is Gravity:
				return (_extension as Gravity).gravity_force.length()
	return float(ProjectSettings.get_setting("physics/3d/default_gravity"))
