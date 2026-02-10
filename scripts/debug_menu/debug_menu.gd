extends Control

func _on_back_pressed() -> void:
	Load.load_res(["res://scenes/main/main_menu/main_menu.tscn"], "res://scenes/main/main_menu/main_menu.tscn")
