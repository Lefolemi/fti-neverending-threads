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
