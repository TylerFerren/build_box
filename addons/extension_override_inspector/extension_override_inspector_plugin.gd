@tool
class_name ExtensionOverrideInspectorPlugin
extends EditorInspectorPlugin

const RANGE_HINT_MIN_INDEX: int = 0
const RANGE_HINT_MAX_INDEX: int = 1
const RANGE_HINT_STEP_INDEX: int = 2

var property_info_by_name: Dictionary = {}
var replaced_value_property_names: Dictionary = {}
var hidden_override_property_names: Dictionary = {}

func _can_handle(object: Object) -> bool:
	return object is ExtensionModeOverride

func _parse_begin(object: Object) -> void:
	property_info_by_name.clear()
	replaced_value_property_names.clear()
	hidden_override_property_names.clear()

	for property_info_variant in object.get_property_list():
		var property_info: Dictionary = property_info_variant as Dictionary
		if property_info.is_empty():
			continue
		var property_name: String = String(property_info.get("name", ""))
		if property_name.is_empty():
			continue
		property_info_by_name[property_name] = property_info

func _parse_property(
	_object: Object,
	type: Variant.Type,
	name: String,
	_hint_type: PropertyHint,
	_hint_string: String,
	_usage_flags: int,
	_wide: bool
) -> bool:
	if hidden_override_property_names.has(name):
		return true

	if replaced_value_property_names.has(name):
		return true

	if not name.begins_with("override_"):
		return false
	if type != TYPE_BOOL:
		return false

	var value_property_name: String = name.trim_prefix("override_")
	if not property_info_by_name.has(value_property_name):
		return false

	var value_property_info: Dictionary = property_info_by_name[value_property_name] as Dictionary
	if value_property_info.is_empty():
		return false

	var inline_editor := OverrideInlineEditorProperty.new()
	inline_editor.configure(name, value_property_name, value_property_info)
	add_property_editor(value_property_name, inline_editor)

	hidden_override_property_names[name] = true
	replaced_value_property_names[value_property_name] = true
	return true

class OverrideInlineEditorProperty extends EditorProperty:
	var override_property_name: String = ""
	var value_property_name: String = ""
	var value_property_type: Variant.Type = TYPE_NIL
	var value_property_hint: PropertyHint = PROPERTY_HINT_NONE
	var value_property_hint_string: String = ""

	var value_editor: Control
	var override_toggle: CheckBox
	var is_refreshing: bool = false

	func configure(new_override_property_name: String, new_value_property_name: String, value_property_info: Dictionary) -> void:
		override_property_name = new_override_property_name
		value_property_name = new_value_property_name
		value_property_type = int(value_property_info.get("type", TYPE_NIL))
		value_property_hint = int(value_property_info.get("hint", PROPERTY_HINT_NONE))
		value_property_hint_string = String(value_property_info.get("hint_string", ""))

	func _ready() -> void:
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_child(row)

		override_toggle = CheckBox.new()
		override_toggle.tooltip_text = "Enable override"
		override_toggle.toggled.connect(_on_override_toggled)
		row.add_child(override_toggle)

		value_editor = _build_value_editor()
		if value_editor == null:
			var fallback_label := Label.new()
			fallback_label.text = "Unsupported"
			value_editor = fallback_label

		value_editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(value_editor)

		_refresh_from_object()

	func _update_property() -> void:
		_refresh_from_object()

	func _set_read_only(read_only: bool) -> void:
		if override_toggle != null:
			override_toggle.disabled = read_only
		if value_editor != null:
			_set_editor_enabled(value_editor, not read_only and override_toggle.button_pressed)

	func _refresh_from_object() -> void:
		var edited_object := get_edited_object()
		if edited_object == null:
			return

		is_refreshing = true
		var override_enabled: bool = bool(edited_object.get(override_property_name))
		override_toggle.button_pressed = override_enabled
		_update_value_editor_from_object(edited_object)
		_set_editor_enabled(value_editor, override_enabled)
		is_refreshing = false

	func _on_override_toggled(is_enabled: bool) -> void:
		if is_refreshing:
			return
		emit_changed(override_property_name, is_enabled)
		_set_editor_enabled(value_editor, is_enabled)

	func _build_value_editor() -> Control:
		if value_property_hint == PROPERTY_HINT_ENUM and (value_property_type == TYPE_INT or value_property_type == TYPE_STRING):
			var enum_picker := OptionButton.new()
			var enum_items: PackedStringArray = value_property_hint_string.split(",")
			for index in enum_items.size():
				enum_picker.add_item(enum_items[index].strip_edges(), index)
			enum_picker.item_selected.connect(func(selected_index: int) -> void:
				if is_refreshing:
					return
				if value_property_type == TYPE_INT:
					emit_changed(value_property_name, selected_index)
				else:
					emit_changed(value_property_name, enum_picker.get_item_text(selected_index))
			)
			return enum_picker

		match value_property_type:
			TYPE_BOOL:
				var bool_toggle := CheckBox.new()
				bool_toggle.toggled.connect(func(next_value: bool) -> void:
					if is_refreshing:
						return
					emit_changed(value_property_name, next_value)
				)
				return bool_toggle
			TYPE_INT:
				return _build_numeric_line_edit(true)
			TYPE_FLOAT:
				return _build_numeric_line_edit(false)
			TYPE_VECTOR3:
				return _build_vector3_editor()
			TYPE_STRING, TYPE_STRING_NAME:
				var text_editor := LineEdit.new()
				text_editor.text_submitted.connect(func(next_text: String) -> void:
					if is_refreshing:
						return
					if value_property_type == TYPE_STRING_NAME:
						emit_changed(value_property_name, StringName(next_text))
					else:
						emit_changed(value_property_name, next_text)
				)
				text_editor.focus_exited.connect(func() -> void:
					if is_refreshing:
						return
					if value_property_type == TYPE_STRING_NAME:
						emit_changed(value_property_name, StringName(text_editor.text))
					else:
						emit_changed(value_property_name, text_editor.text)
				)
				return text_editor
			_:
				return null

	func _build_vector3_editor() -> Control:
		var container := HBoxContainer.new()
		container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var x_editor := _build_vector_component_editor()
		var y_editor := _build_vector_component_editor()
		var z_editor := _build_vector_component_editor()

		x_editor.value_changed.connect(func(_next: float) -> void:
			if is_refreshing:
				return
			emit_changed(value_property_name, Vector3(x_editor.value, y_editor.value, z_editor.value))
		)
		y_editor.value_changed.connect(func(_next: float) -> void:
			if is_refreshing:
				return
			emit_changed(value_property_name, Vector3(x_editor.value, y_editor.value, z_editor.value))
		)
		z_editor.value_changed.connect(func(_next: float) -> void:
			if is_refreshing:
				return
			emit_changed(value_property_name, Vector3(x_editor.value, y_editor.value, z_editor.value))
		)

		container.add_child(x_editor)
		container.add_child(y_editor)
		container.add_child(z_editor)
		return container

	func _build_vector_component_editor() -> SpinBox:
		var component_editor := SpinBox.new()
		component_editor.step = 0.01
		component_editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		return component_editor

	func _build_numeric_line_edit(is_integer: bool) -> LineEdit:
		var numeric_editor := LineEdit.new()
		numeric_editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		numeric_editor.text_submitted.connect(func(next_text: String) -> void:
			if is_refreshing:
				return
			_commit_numeric_text(numeric_editor, next_text, is_integer)
		)

		numeric_editor.focus_exited.connect(func() -> void:
			if is_refreshing:
				return
			_commit_numeric_text(numeric_editor, numeric_editor.text, is_integer)
		)

		return numeric_editor

	func _update_value_editor_from_object(edited_object: Object) -> void:
		if value_editor == null:
			return

		var current_value: Variant = edited_object.get(value_property_name)
		if value_editor is OptionButton:
			var enum_editor := value_editor as OptionButton
			if value_property_type == TYPE_INT:
				enum_editor.selected = clamp(int(current_value), 0, max(enum_editor.item_count - 1, 0))
			else:
				var text_value: String = String(current_value)
				for item_index in enum_editor.item_count:
					if enum_editor.get_item_text(item_index) == text_value:
						enum_editor.selected = item_index
						break
		elif value_editor is CheckBox:
			(value_editor as CheckBox).button_pressed = bool(current_value)
		elif value_editor is LineEdit:
			if value_property_type == TYPE_INT:
				(value_editor as LineEdit).text = str(int(current_value))
			elif value_property_type == TYPE_FLOAT:
				(value_editor as LineEdit).text = str(float(current_value))
			else:
				(value_editor as LineEdit).text = String(current_value)
		elif value_editor is HBoxContainer and value_property_type == TYPE_VECTOR3:
			var vector_value: Vector3 = current_value as Vector3
			if value_editor.get_child_count() >= 3:
				(value_editor.get_child(0) as SpinBox).value = vector_value.x
				(value_editor.get_child(1) as SpinBox).value = vector_value.y
				(value_editor.get_child(2) as SpinBox).value = vector_value.z

	func _commit_numeric_text(text_editor: LineEdit, text_value: String, is_integer: bool) -> void:
		var sanitized_text := text_value.strip_edges()
		if sanitized_text.is_empty():
			_refresh_from_object()
			return

		if is_integer:
			if not sanitized_text.is_valid_int():
				_refresh_from_object()
				return
			emit_changed(value_property_name, int(sanitized_text))
		else:
			if not sanitized_text.is_valid_float():
				_refresh_from_object()
				return
			emit_changed(value_property_name, float(sanitized_text))

	func _set_editor_enabled(editor: Control, is_enabled: bool) -> void:
		if editor is LineEdit:
			(editor as LineEdit).editable = is_enabled
		elif editor is SpinBox:
			(editor as SpinBox).editable = is_enabled
		elif editor is OptionButton:
			(editor as OptionButton).disabled = not is_enabled
		elif editor is BaseButton:
			(editor as BaseButton).disabled = not is_enabled

		editor.modulate = Color(1.0, 1.0, 1.0, 1.0) if is_enabled else Color(0.65, 0.65, 0.65, 1.0)
		for child in editor.get_children():
			if child is Control:
				_set_editor_enabled(child as Control, is_enabled)

	func _apply_range_hint(spin_box: SpinBox, hint_type: PropertyHint, hint_string: String) -> void:
		if hint_type != PROPERTY_HINT_RANGE:
			return

		var hint_parts: PackedStringArray = hint_string.split(",")
		if hint_parts.size() > RANGE_HINT_MIN_INDEX:
			spin_box.min_value = float(hint_parts[RANGE_HINT_MIN_INDEX])
		if hint_parts.size() > RANGE_HINT_MAX_INDEX:
			spin_box.max_value = float(hint_parts[RANGE_HINT_MAX_INDEX])
		if hint_parts.size() > RANGE_HINT_STEP_INDEX:
			spin_box.step = float(hint_parts[RANGE_HINT_STEP_INDEX])
