@tool
class_name InputActionRoute
extends Resource

enum TriggerType {PRESSED, RELEASED}

@export var action_name: StringName
@export var trigger_type: TriggerType = TriggerType.PRESSED
@export var target_callable: Callable
@export var pass_action_name_argument: bool = false

func _validate_property(property: Dictionary) -> void:
	if property.name != "action_name":
		return

	var action_names: PackedStringArray = PackedStringArray()

	# Include actions currently registered in the runtime input map.
	for input_action_name in InputMap.get_actions():
		action_names.append(String(input_action_name))

	# Include project-defined actions from ProjectSettings so editor lists stay complete.
	var input_settings: Dictionary = ProjectSettings.get_setting("input", {})
	for input_action_name in input_settings.keys():
		var action_name := String(input_action_name)
		if not action_names.has(action_name):
			action_names.append(action_name)

	action_names.sort()

	property.hint = PROPERTY_HINT_ENUM
	property.hint_string = ",".join(action_names)
