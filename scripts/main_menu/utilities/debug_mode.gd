extends Button

func _on_pressed() -> void:
	Load.load_res(["res://scenes/main/debug_menu/debug_menu.tscn"], "res://scenes/main/debug_menu/debug_menu.tscn")
