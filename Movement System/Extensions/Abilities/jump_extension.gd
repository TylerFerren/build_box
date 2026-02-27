class_name Jump
extends MovementExtension

@export var jump_height: float = 3.0
@export var air_jumps: int = 1
@export var fast_fall_multiplier: float = 2.0
@export var low_jump_multiplier: float = 2.0
@export var coyote_time: float = 0.2
@export_group("Wall Jump")
@export var enable_wall_jump: bool = true
@export var wall_jump_push_speed: float = 8.0
@export var wall_jump_push_dampening: float = 6.0
@export var wall_jump_cooldown: float = 0.1

signal jumped

var can_jump: bool = false
var jump_velocity: float = 0.0
var active_fast_fall_multiplier: float = 1.0
var active_low_jump_multiplier: float = 1.0
var coyote_timer: float = 0.0
var gravity_magnitude: float = 9.8
var current_air_jump_count: int = 0
var is_jump_press_requested: bool = false
var is_jump_release_requested: bool = false
var wall_jump_push_velocity: Vector3 = Vector3.ZERO
var wall_jump_cooldown_remaining: float = 0.0

func _ready() -> void:
	gravity_magnitude = _get_gravity_magnitude()

func on_jump_pressed() -> void:
	is_jump_press_requested = true

func on_jump_released() -> void:
	is_jump_release_requested = true

func update_extension_state(movement_state: MovementState, delta: float) -> void:
	if wall_jump_cooldown_remaining > 0.0:
		wall_jump_cooldown_remaining = max(wall_jump_cooldown_remaining - delta, 0.0)

	_update_coyote_time(movement_state, delta)

	if is_jump_release_requested:
		active_low_jump_multiplier = low_jump_multiplier

	if is_jump_press_requested:
		_try_jump(movement_state)

	is_jump_release_requested = false
	is_jump_press_requested = false

func _try_jump(movement_state: MovementState) -> void:
	if manager == null or manager.controller == null:
		return
		
	gravity_magnitude = _get_gravity_magnitude()
	var used_wall_jump: bool = false

	if movement_state.is_grounded:
		current_air_jump_count = 0
	elif can_jump:
		can_jump = false
	elif _can_wall_jump(movement_state):
		used_wall_jump = true
	elif current_air_jump_count >= air_jumps:
		return

	jump_velocity = sqrt(2.0 * jump_height * gravity_magnitude)

	# Offset falling speed so jump remains responsive while descending.
	if movement_state.current_velocity.y < 0.0:
		jump_velocity -= movement_state.current_velocity.y

	active_fast_fall_multiplier = 1.0
	active_low_jump_multiplier = 1.0
	is_active = true

	if used_wall_jump:
		wall_jump_push_velocity = _get_wall_jump_push_direction(movement_state) * wall_jump_push_speed
		wall_jump_cooldown_remaining = wall_jump_cooldown
		can_jump = false
	elif not can_jump:
		current_air_jump_count += 1

	jumped.emit()

func get_movement_velocity(movement_state: MovementState, delta: float) -> Vector3:
	var movement_velocity: Vector3 = Vector3.ZERO

	if is_active:
		if movement_state.current_velocity.y < 0.0 and is_equal_approx(active_fast_fall_multiplier, 1.0):
			active_fast_fall_multiplier = fast_fall_multiplier

		if jump_velocity > 0.0:
			jump_velocity -= active_fast_fall_multiplier * active_low_jump_multiplier * gravity_magnitude * delta

		jump_velocity = max(jump_velocity, 0.0)
		movement_velocity += movement_state.up_direction * jump_velocity

	var has_wall_push: bool = wall_jump_push_velocity.length_squared() > 0.0001
	if has_wall_push:
		wall_jump_push_velocity = wall_jump_push_velocity.move_toward(Vector3.ZERO, wall_jump_push_dampening * delta)
		movement_velocity += wall_jump_push_velocity

	if jump_velocity <= 0.0 and wall_jump_push_velocity.length_squared() <= 0.0001:
		is_active = false

	return movement_velocity

func _update_coyote_time(movement_state: MovementState, delta: float) -> void:
	if movement_state.is_grounded and not is_active:
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

func _can_wall_jump(movement_state: MovementState) -> bool:
	if not enable_wall_jump:
		return false
	if wall_jump_cooldown_remaining > 0.0:
		return false
	if not movement_state.is_on_wall:
		return false
	return movement_state.wall_normal.length_squared() > 0.0

func _get_wall_jump_push_direction(movement_state: MovementState) -> Vector3:
	var wall_push_direction := movement_state.wall_normal.slide(movement_state.up_direction)
	if wall_push_direction.length_squared() > 0.0:
		return wall_push_direction.normalized()

	var fallback_forward := -manager.controller.global_basis.z.slide(movement_state.up_direction)
	if fallback_forward.length_squared() > 0.0:
		return fallback_forward.normalized()
	return Vector3.FORWARD
