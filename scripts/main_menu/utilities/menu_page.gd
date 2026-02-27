class_name MenuPage extends ScrollContainer

signal item_selected(index: int, button_name: String)

@onready var vbox: VBoxContainer = $VBox

func _ready() -> void:
	for child in vbox.get_children():
		if child is Button:
			child.pressed.connect(_on_button_pressed.bind(child))
			# Store original text so the Root can read it later
			child.set_meta("original_text", child.text)

func _on_button_pressed(button: Button) -> void:
	var idx = _get_safe_index(button)
	item_selected.emit(idx, button.name)

func _get_safe_index(btn: Button) -> int:
	var text = str(btn.get_meta("original_text")).to_lower()
	
	if "quiz" in text: return 0
	if "elearn" in text: return 1
	if "midtest" in text: return 2
	if "final" in text: return 3
	if "all" in text: return 4
	
	var regex = RegEx.new()
	regex.compile("\\d+")
	var result = regex.search(text)
	if result:
		return int(result.get_string()) - 1
		
	return btn.get_index()
