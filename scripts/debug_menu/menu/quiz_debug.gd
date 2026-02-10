extends GridContainer

func show_menu(node: String):
	# 1. Hide this container (MenuVBox)
	hide()

	# 2. Access the 'QuizDebug' node via the scene root (owner)
	# This is the "root.QuizDebug" equivalent you wanted.
	var quiz_debug = owner.get_node(node)
	quiz_debug.show()

func _on_cancel_pressed() -> void:
	show_menu("MenuVBox")

func _on_file_path_button_pressed() -> void:
	show_menu("SelectFile")
