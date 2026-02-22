extends ScrollContainer

# Map the button nodes to their destination scenes
@onready var menu_map: Dictionary = {
	$VBox/Shop: "res://scenes/utilities/shop/shop.tscn",
	$VBox/Statistics: "res://scenes/utilities/statistics/statistics.tscn",
	$VBox/Achievement: "res://scenes/utilities/achievement/achievement.tscn",
	$VBox/Settings: "res://scenes/utilities/settings/settings.tscn"
}

func _ready() -> void:
	# Loop through the map to connect all buttons automatically
	for btn in menu_map.keys():
		if btn:
			# Bind the specific path to the generic navigate function
			btn.pressed.connect(_on_menu_button_pressed.bind(menu_map[btn]))

func _on_menu_button_pressed(target_path: String) -> void:
	# 1. Store the current scene so the 'Back' button knows where to return
	# We use owner.filename to get the path of the scene root
	GVar.last_scene = owner.scene_file_path 
	
	# 2. Trigger your Scene Loader
	# Using your existing Load.load_res pattern
	Load.load_res([target_path], target_path)
