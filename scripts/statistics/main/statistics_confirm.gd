extends HBoxContainer

@onready var btn_close: Button = $Close

func _ready() -> void:
	btn_close.pressed.connect(_on_close_pressed)

func _on_close_pressed() -> void:
	# Return to the previous scene, or fallback to Main Menu if none exists
	if GVar.last_scene != "":
		Load.load_res([GVar.last_scene], GVar.last_scene)
	else:
		Load.load_res(["res://scenes/main/main_menu/main_menu.tscn"], "res://scenes/main/main_menu/main_menu.tscn")
