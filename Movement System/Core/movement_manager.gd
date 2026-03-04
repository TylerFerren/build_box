class_name MovementManager
extends Node

@export var controller: CharacterBody3D
@export var camera: Camera3D

var extensions: Array[MovementExtension] = []
var additive_extensions: Array[MovementExtension] = []
var subtractive_extensions: Array[MovementExtension] = []
var overriding_extensions: Array[MovementExtension] = []
var constant_extensions: Array[MovementExtension] = []
var mode_manager: MovementModeManager

var is_grounded: bool = false
var move_input: Vector2 = Vector2.ZERO
var mode_speed_multiplier: float = 1.0
var mode_gravity_scale: float = 1.0
var current_mode: StringName = StringName()
var requested_mode_change: StringName = StringName()

func _ready() -> void:
	_ensure_controller_and_camera_are_assigned()

	extensions.clear()
	additive_extensions.clear()
	subtractive_extensions.clear()
	overriding_extensions.clear()
	constant_extensions.clear()

	for child in get_children():
		if child is MovementExtension:
			extensions.append(child)
	
	for extension in extensions:
		extension.manager = self
		match extension.blend_mode:
			MovementExtension.ExtensionBlendMode.ADDITIVE:
				additive_extensions.append(extension)
			MovementExtension.ExtensionBlendMode.SUBTRACTIVE:
				subtractive_extensions.append(extension)
			MovementExtension.ExtensionBlendMode.OVERRIDING:
				overriding_extensions.append(extension)
			MovementExtension.ExtensionBlendMode.CONSTANT:
				constant_extensions.append(extension)

	for child in get_children():
		if child is MovementModeManager:
			mode_manager = child as MovementModeManager
			mode_manager.set_movement_manager(self)
			mode_manager.mode_changed.connect(_on_mode_changed)
			current_mode = mode_manager.current_mode

	call_deferred("_validate_configuration")

func _physics_process(delta: float) -> void:
	if controller == null:
		_ensure_controller_and_camera_are_assigned()
		if controller == null:
			return

	_update_grounded_state()

	var movement_state := _create_movement_state(delta)
	_update_extension_states(movement_state, delta)
	_apply_requested_mode_change()
	_evaluate_mode_transitions(movement_state, delta)
	_sync_mode_name_to_state(movement_state)

	var resolved_velocity := _resolve_movement_velocity(movement_state, delta)
	movement_state.current_velocity = resolved_velocity
	controller.velocity = resolved_velocity
	controller.move_and_slide()

	movement_state.character_global_position = controller.global_position

	controller.rotation = _resolve_rotation_euler(movement_state, delta)

func _update_grounded_state() -> void:
	is_grounded = controller.is_on_floor()

func _ensure_controller_and_camera_are_assigned() -> void:
	if controller == null and get_parent() is CharacterBody3D:
		controller = get_parent() as CharacterBody3D

	if camera == null:
		camera = get_viewport().get_camera_3d()

func _create_movement_state(delta: float) -> MovementState:
	var movement_state := MovementState.new()
	movement_state.delta_time = delta
	movement_state.is_grounded = is_grounded
	movement_state.ground_normal = controller.get_floor_normal()
	movement_state.is_on_wall = controller.is_on_wall()
	if movement_state.is_on_wall:
		movement_state.wall_normal = controller.get_wall_normal()
	else:
		movement_state.wall_normal = Vector3.ZERO
	movement_state.current_velocity = controller.velocity
	movement_state.up_direction = controller.up_direction
	movement_state.character_global_position = controller.global_position
	movement_state.camera = camera if camera != null else get_viewport().get_camera_3d()
	movement_state.move_input = move_input
	movement_state.base_speed_multiplier = mode_speed_multiplier
	movement_state.base_gravity_scale = mode_gravity_scale
	movement_state.speed_multiplier = mode_speed_multiplier
	movement_state.gravity_scale = mode_gravity_scale
	movement_state.current_mode = current_mode
	return movement_state

func _update_extension_states(movement_state: MovementState, delta: float) -> void:
	for extension in extensions:
		extension.update_extension_state(movement_state, delta)

func _evaluate_mode_transitions(movement_state: MovementState, delta: float) -> void:
	if mode_manager == null:
		return
	mode_manager.evaluate_mode_transitions(movement_state, delta)

func _apply_requested_mode_change() -> void:
	if requested_mode_change == StringName():
		return
	if mode_manager != null:
		mode_manager.set_mode(requested_mode_change)
	requested_mode_change = StringName()

func _sync_mode_name_to_state(movement_state: MovementState) -> void:
	var speed_modifier_factor: float = 1.0
	if not is_zero_approx(movement_state.base_speed_multiplier):
		speed_modifier_factor = movement_state.speed_multiplier / movement_state.base_speed_multiplier

	var gravity_modifier_factor: float = 1.0
	if not is_zero_approx(movement_state.base_gravity_scale):
		gravity_modifier_factor = movement_state.gravity_scale / movement_state.base_gravity_scale

	movement_state.base_speed_multiplier = mode_speed_multiplier
	movement_state.base_gravity_scale = mode_gravity_scale
	movement_state.speed_multiplier = movement_state.base_speed_multiplier * speed_modifier_factor
	movement_state.gravity_scale = movement_state.base_gravity_scale * gravity_modifier_factor
	movement_state.current_mode = current_mode

func _resolve_movement_velocity(movement_state: MovementState, delta: float) -> Vector3:
	var constant_velocity: Vector3 = Vector3.ZERO
	for extension in constant_extensions:
		if extension.is_active and extension.affects_movement:
			constant_velocity += extension.get_movement_velocity(movement_state, delta)

	for extension in overriding_extensions:
		if extension.is_active and extension.affects_movement:
			return constant_velocity + extension.get_movement_velocity(movement_state, delta)

	var blended_velocity: Vector3 = Vector3.ZERO
	for extension in additive_extensions:
		if extension.is_active and extension.affects_movement:
			blended_velocity += extension.get_movement_velocity(movement_state, delta)

	for extension in subtractive_extensions:
		if extension.is_active and extension.affects_movement:
			blended_velocity -= extension.get_movement_velocity(movement_state, delta)

	return constant_velocity + blended_velocity

func _resolve_rotation_euler(movement_state: MovementState, delta: float) -> Vector3:
	var constant_rotation: Vector3 = Vector3.ZERO
	for extension in constant_extensions:
		if extension.is_active and extension.affects_rotation:
			constant_rotation += extension.get_rotation_euler(movement_state, delta)

	for extension in overriding_extensions:
		if extension.is_active and extension.affects_rotation:
			return constant_rotation + extension.get_rotation_euler(movement_state, delta)

	var blended_rotation: Vector3 = Vector3.ZERO
	for extension in additive_extensions:
		if extension.is_active and extension.affects_rotation:
			blended_rotation += extension.get_rotation_euler(movement_state, delta)

	for extension in subtractive_extensions:
		if extension.is_active and extension.affects_rotation:
			blended_rotation -= extension.get_rotation_euler(movement_state, delta)

	return constant_rotation + blended_rotation

func get_extension_by_blend_mode(blend_mode : MovementExtension.ExtensionBlendMode) -> Array[MovementExtension]:
	match blend_mode:
		MovementExtension.ExtensionBlendMode.ADDITIVE:
			return additive_extensions
		MovementExtension.ExtensionBlendMode.SUBTRACTIVE:
			return subtractive_extensions
		MovementExtension.ExtensionBlendMode.OVERRIDING:
			return overriding_extensions
		MovementExtension.ExtensionBlendMode.CONSTANT:
			return constant_extensions
	return []

func get_camera_relative_input(input_vector: Vector3) -> Vector3:
	var active_camera := camera if camera != null else get_viewport().get_camera_3d()
	if active_camera == null:
		return input_vector

	var character_up := controller.up_direction if controller != null else Vector3.UP

	var camera_forward := (-active_camera.global_basis.z).slide(character_up)
	if camera_forward.length_squared() > 0.0:
		camera_forward = camera_forward.normalized()
	else:
		camera_forward = -active_camera.global_basis.z.normalized()

	var camera_right := active_camera.global_basis.x.slide(character_up)
	if camera_right.length_squared() > 0.0:
		camera_right = camera_right.normalized()
	else:
		camera_right = active_camera.global_basis.x.normalized()

	return (camera_right * input_vector.x) + (camera_forward * -input_vector.z) + (character_up * input_vector.y)

func set_move_input(input_value: Vector2) -> void:
	move_input = input_value

func request_mode_change(mode_name: StringName) -> void:
	requested_mode_change = mode_name

func set_mode_multipliers(speed_multiplier: float, gravity_scale: float) -> void:
	mode_speed_multiplier = speed_multiplier
	mode_gravity_scale = gravity_scale

func _on_mode_changed(_previous_mode: StringName, next_mode: StringName) -> void:
	current_mode = next_mode

func _validate_configuration() -> void:
	if controller == null:
		push_warning("MovementManager controller is not assigned.")
	if camera == null:
		push_warning("MovementManager camera is not assigned. Using viewport active camera fallback.")
	if mode_manager == null:
		push_warning("MovementManager has no MovementModeManager child.")
	if extensions.is_empty():
		push_warning("MovementManager has no MovementExtension children.")
