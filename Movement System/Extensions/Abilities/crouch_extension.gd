class_name Crouch
extends MovementExtension

@export var crouch_speed_multiplier: float = 0.55
@export var crouch_height_scale: float = 0.65
@export var crouch_transition_speed: float = 8.0
@export var use_toggle_input: bool = false
@export var collision_shape_path: NodePath
@export var require_headroom_to_stand: bool = true
@export var stand_check_margin: float = 0.05

signal crouch_entered
signal crouch_exited

var crouch_pressed_requested: bool = false
var crouch_released_requested: bool = false

var collision_shape_node: CollisionShape3D
var capsule_shape: CapsuleShape3D
var default_capsule_height: float = 0.0
var default_collision_shape_position: Vector3 = Vector3.ZERO

func _ready() -> void:
	affects_movement = false
	affects_rotation = false
	if allowed_modes.is_empty():
		allowed_modes = [&"ground"]
	is_active = false
	_cache_collision_shape()

func on_crouch_pressed() -> void:
	crouch_pressed_requested = true

func on_crouch_released() -> void:
	crouch_released_requested = true

func update_extension_state(movement_state: MovementState, delta: float) -> void:
	if capsule_shape == null or collision_shape_node == null:
		_cache_collision_shape()

	var was_active: bool = is_active
	var requested_active_state: bool = is_active

	if use_toggle_input:
		if crouch_pressed_requested:
			requested_active_state = not is_active
	else:
		if crouch_pressed_requested:
			requested_active_state = true
		if crouch_released_requested:
			requested_active_state = false

	if not requested_active_state and is_active and require_headroom_to_stand and not _can_stand():
		requested_active_state = true

	is_active = requested_active_state

	crouch_pressed_requested = false
	crouch_released_requested = false

	if is_active:
		movement_state.speed_multiplier *= crouch_speed_multiplier
		movement_state.is_crouching = true

	_update_crouch_shape(delta)

	if not was_active and is_active:
		crouch_entered.emit()
	elif was_active and not is_active:
		crouch_exited.emit()

func _cache_collision_shape() -> void:
	if manager == null or manager.controller == null:
		return

	if collision_shape_path != NodePath():
		collision_shape_node = get_node_or_null(collision_shape_path) as CollisionShape3D
	else:
		collision_shape_node = manager.controller.get_node_or_null("CollisionShape3D") as CollisionShape3D

	if collision_shape_node == null:
		return

	capsule_shape = collision_shape_node.shape as CapsuleShape3D
	if capsule_shape == null:
		return

	default_capsule_height = capsule_shape.height
	default_collision_shape_position = collision_shape_node.position

func _update_crouch_shape(delta: float) -> void:
	if capsule_shape == null or collision_shape_node == null:
		return

	var desired_height_scale := crouch_height_scale if is_active else 1.0
	var desired_height := default_capsule_height * desired_height_scale
	var height_step := crouch_transition_speed * delta
	capsule_shape.height = move_toward(capsule_shape.height, desired_height, height_step)

	var height_delta := default_capsule_height - capsule_shape.height
	collision_shape_node.position = default_collision_shape_position - Vector3(0.0, height_delta * 0.5, 0.0)

func _can_stand() -> bool:
	if capsule_shape == null or collision_shape_node == null:
		return true
	if manager == null or manager.controller == null:
		return true

	var current_half_extent := (capsule_shape.height * 0.5) + capsule_shape.radius
	var full_half_extent := (default_capsule_height * 0.5) + capsule_shape.radius
	var required_clearance := full_half_extent - current_half_extent
	if required_clearance <= 0.0:
		return true

	var up_direction := manager.controller.up_direction.normalized()
	var ray_start := collision_shape_node.global_position + (up_direction * current_half_extent)
	var ray_end := ray_start + (up_direction * (required_clearance + stand_check_margin))

	var ray_query := PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	ray_query.exclude = [manager.controller.get_rid()]
	ray_query.collide_with_areas = true

	var space_state := manager.controller.get_world_3d().direct_space_state
	var raycast_hit := space_state.intersect_ray(ray_query)
	return not raycast_hit.has("position")
