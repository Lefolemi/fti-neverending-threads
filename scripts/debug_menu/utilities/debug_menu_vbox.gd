extends VBoxContainer

func show_menu(node: String):
	# 1. Hide this container (MenuVBox)
	hide()

	# 2. Access the 'QuizDebug' node via the scene root (owner)
	# This is the "root.QuizDebug" equivalent you wanted.
	var quiz_debug = owner.get_node(node)
	quiz_debug.show()

func _on_quiz_debug_button_pressed() -> void:
	show_menu("QuizDebug");

func _on_current_info_button_pressed() -> void:
	show_menu("CurrentInformation");

func _on_toggle_achievement_pressed() -> void:
	show_menu("ToggleAchievement");

func _on_back_pressed() -> void:
	Load.load_res(["res://scenes/main/main_menu/main_menu.tscn"], "res://scenes/main/main_menu/main_menu.tscn")
