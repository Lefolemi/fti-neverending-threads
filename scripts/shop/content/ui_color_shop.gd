extends Control # Or VBoxContainer

signal item_selected(item_id: String, item_title: String, price: int, btn: Button)

@onready var grid: GridContainer = $ColorThemeGrid

# We keep the palette here so it knows what colors to build the shop with!
const COLOR_PALETTE = {
	"Classic": Color("2b2b2b"), "Midnight": Color("121212"), "Ocean": Color("0f2027"),
	"Pine": Color("1b4332"), "Wine": Color("4a0404"), "Eggplant": Color("311b3d"),
	"Chocolate": Color("3e2723"), "Rust": Color("8a3324"), "Navy": Color("000033"),
	"Olive": Color("33691e"), "Charcoal": Color("36454F"), "Indigo": Color("1a0b2e")
}

func _ready() -> void:
	_generate_colors()

func _generate_colors() -> void:
	# Clear placeholder UI
	for child in grid.get_children():
		child.queue_free()
		
	await get_tree().process_frame
	
	var color_names = COLOR_PALETTE.keys()
	for i in range(color_names.size()):
		var c_name = color_names[i]
		var btn = _create_color_button("CLR_" + c_name, c_name, 300, COLOR_PALETTE[c_name])
		grid.add_child(btn)
		
		if i % 4 == 0: await get_tree().process_frame

func _create_color_button(item_id: String, title: String, price: int, color_val: Color) -> Button:
	var btn = Button.new()
	btn.name = item_id
	btn.custom_minimum_size = Vector2(110, 140)
	btn.self_modulate = Color.WHITE
	btn.mouse_filter = Control.MOUSE_FILTER_PASS
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE, 5)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn.add_child(vbox)
	
	# Color Display Square
	var c_rect = ColorRect.new()
	c_rect.color = color_val
	c_rect.custom_minimum_size = Vector2(0, 70)
	c_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(c_rect)
		
	# Title
	var lbl_title = Label.new()
	lbl_title.text = title
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_title.add_theme_font_size_override("font_size", 12)
	lbl_title.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(lbl_title)
	
	# Price / Sold Status
	var lbl_price = Label.new()
	lbl_price.name = "PriceLabel" 
	lbl_price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_price.add_theme_font_size_override("font_size", 12)
	
	if GVar.shop_unlocks.has(item_id):
		lbl_price.text = "SOLD"
		lbl_price.add_theme_color_override("font_color", Color.GREEN)
	else:
		lbl_price.text = str(price) + " Pts"
		lbl_price.add_theme_color_override("font_color", Color.YELLOW)
		
	vbox.add_child(lbl_price)
		
	# Connect the signal to shout to the Root
	btn.pressed.connect(func():
		item_selected.emit(item_id, title, price, btn)
	)
	
	return btn
