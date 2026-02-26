extends CanvasLayer

# We create a custom signal that passes a boolean (true for Yes, false for No)
signal confirmed(result: bool)

@onready var bg_menu: ColorRect = $BGMenu
@onready var confirm_label: Label = $ConfirmPanel/VBox/ConfirmLabel
@onready var btn_yes: Button = $ConfirmPanel/VBox/HBox/Yes
@onready var btn_no: Button = $ConfirmPanel/VBox/HBox/No

func _ready() -> void:
	# Always hide the menu when the game starts
	self.hide()
	
	# Connect the buttons
	btn_yes.pressed.connect(_on_yes_pressed)
	btn_no.pressed.connect(_on_no_pressed)

# --- THE MAGIC FUNCTION ---
# We use Godot's 'await' feature so other scripts can pause and wait for the answer
func ask(message: String) -> bool:
	# 1. Update the text and show the popup
	confirm_label.text = message
	self.show()
	
	# 2. Pause this specific function execution until 'confirmed' is emitted
	var result = await self.confirmed

	# 3. The player clicked something! Hide the menu and return their choice.
	self.hide()
	return result

# --- BUTTON RECEIVERS ---
func _on_yes_pressed() -> void:
	confirmed.emit(true)

func _on_no_pressed() -> void:
	confirmed.emit(false)
