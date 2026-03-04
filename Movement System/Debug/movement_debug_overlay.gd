class_name MovementDebugOverlay
extends CanvasLayer

@export var movement_manager_path: NodePath = NodePath("../MovementManager")
@export var is_enabled: bool = true
@export var start_visible: bool = true
@export var toggle_action: StringName = &"movement_debug_toggle"

var movement_manager: MovementManager
var debug_label: Label

func _ready() -> void:
	if movement_manager_path != NodePath():
		movement_manager = get_node_or_null(movement_manager_path) as MovementManager

	debug_label = Label.new()
	debug_label.name = "DebugLabel"
	debug_label.position = Vector2(16.0, 16.0)
	add_child(debug_label)

	visible = is_enabled and start_visible
	set_process(is_enabled)

func _process(_delta: float) -> void:
	if not is_enabled:
		return

	if toggle_action != StringName() and Input.is_action_just_pressed(toggle_action):
		visible = not visible

	if not visible:
		return

	_refresh_text()

func _refresh_text() -> void:
	if movement_manager == null:
		debug_label.text = "Movement Debug\nmanager: missing"
		return

	var velocity := Vector3.ZERO
	if movement_manager.controller != null:
		velocity = movement_manager.controller.velocity

	var mode_name := movement_manager.current_mode
	if mode_name == StringName():
		mode_name = &"<none>"

	var active_extensions: PackedStringArray = []
	for extension in movement_manager.extensions:
		if extension.is_active:
			active_extensions.append(extension.name)

	debug_label.text = "\n".join([
		"Movement Debug",
		"mode: %s" % String(mode_name),
		"grounded: %s" % String(movement_manager.is_grounded),
		"move_input: %s" % String(movement_manager.move_input),
		"velocity: (%.2f, %.2f, %.2f)" % [velocity.x, velocity.y, velocity.z],
		"active_extensions: %s" % ", ".join(active_extensions),
	])
