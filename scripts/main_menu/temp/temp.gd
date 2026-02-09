extends Node2D

func _ready() -> void:
	# List all the heavy things you want ready before the menu appears
	var assets_to_load = [
		"res://scenes/main/main_menu/main_menu.tscn",         # The destination scene
		"res://scripts/global/vars/global_constant.gd", # Heavy textures
		"res://scripts/global/vars/global_variable.gd",       # Scripts
	]

	# Go!
	# We pass MainMenu.tscn as the second argument so it switches there automatically.
	Load.load_res(assets_to_load, "res://scenes/main/main_menu/main_menu.tscn")
