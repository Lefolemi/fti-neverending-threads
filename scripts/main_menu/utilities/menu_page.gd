class_name MenuPage extends ScrollContainer

# Define a custom signal. 
# The MainMenu only listens for this. It doesn't care about the buttons inside.
signal item_selected(index: int, button_name: String)

@onready var vbox: VBoxContainer = $VBox

func _ready() -> void:
	# This script handles its own children. MainMenu doesn't need to know.
	for child in vbox.get_children():
		if child is Button:
			child.pressed.connect(_on_button_pressed.bind(child))

func _on_button_pressed(button: Button) -> void:
	var idx = _get_index_from_name(button.name)
	# Bubble the signal up to the parent (MainMenu)
	item_selected.emit(idx, button.name)

# This logic is now isolated here. 
# If you change how buttons are named, you only fix it here.
func _get_index_from_name(btn_name: String) -> int:
	var regex = RegEx.new()
	regex.compile("\\d+")
	var result = regex.search(btn_name)
	if result:
		return int(result.get_string()) - 1
	return -1
