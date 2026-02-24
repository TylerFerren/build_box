extends Node

func transition_to_scene(new_scene : PackedScene):
	get_tree().change_scene_to_packed(new_scene)

func transition_to_main_menu():
	get_tree().change_scene_to_file("res://Main Menu/main_menu.tscn")

func transition_to_movement_pllayground():
	get_tree().change_scene_to_file("res://Testing Scenes/movement_playground.tscn")
