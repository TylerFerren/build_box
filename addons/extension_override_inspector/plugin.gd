@tool
extends EditorPlugin

const EXTENSION_OVERRIDE_INSPECTOR_PLUGIN := preload("res://addons/extension_override_inspector/extension_override_inspector_plugin.gd")

var extension_override_inspector: EditorInspectorPlugin

func _enter_tree() -> void:
	extension_override_inspector = EXTENSION_OVERRIDE_INSPECTOR_PLUGIN.new()
	add_inspector_plugin(extension_override_inspector)

func _exit_tree() -> void:
	if extension_override_inspector != null:
		remove_inspector_plugin(extension_override_inspector)
	extension_override_inspector = null
