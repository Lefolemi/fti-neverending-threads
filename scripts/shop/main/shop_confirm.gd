extends Control # Or whatever node type your Confirm panel is

signal buy_requested
signal preview_requested
signal close_requested

@onready var lbl_points: Label = $PointsCounter
@onready var btn_buy: Button = $Buy
@onready var btn_preview: Button = $Preview
@onready var btn_close: Button = $Close

func _ready() -> void:
	# Wire up the buttons to shout to the Root script
	btn_buy.pressed.connect(func(): buy_requested.emit())
	btn_preview.pressed.connect(func(): preview_requested.emit())
	btn_close.pressed.connect(func(): close_requested.emit())
	
	# Default safe state so players can't buy nothing
	btn_buy.disabled = true
	btn_preview.disabled = true

# --- Helper functions for the Root Script to call ---

func update_points_display(points: int) -> void:
	lbl_points.text = "Wallet: " + str(points) + " Pts"

func setup_buttons_for_item(is_owned: bool, price: int, can_preview: bool) -> void:
	if is_owned:
		btn_buy.text = "Owned"
		btn_buy.disabled = true
	else:
		# We leave it enabled even if they are poor so they get the "Not enough money!" feedback
		btn_buy.text = "Buy (-" + str(price) + ")"
		btn_buy.disabled = false
		
	btn_preview.disabled = not can_preview
