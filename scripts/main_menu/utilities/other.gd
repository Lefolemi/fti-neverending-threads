extends GridContainer

func _on_decks_pressed() -> void:
	GVar.last_scene = "res://scenes/main/main_menu/main_menu.tscn";
	Load.load_res(["res://scenes/utilities/csv/deck_view.tscn"], "res://scenes/utilities/csv/deck_view.tscn")
