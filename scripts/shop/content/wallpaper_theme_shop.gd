extends Control # Or VBoxContainer

signal item_selected(item_id: String, item_title: String, price: int, btn: Button)

@onready var grid: GridContainer = $WallpaperThemeGrid

var wp_upgrades = [
	{"id": "BG_Picker", "title": "BG Color Picker", "price": 1200},
	{"id": "BG_Rand", "title": "BG Random Color", "price": 200},
	{"id": "WP_Opacity", "title": "Wallpaper Opacity", "price": 500},
	{"id": "WP_Scale", "title": "Wallpaper Scale", "price": 2000},
	{"id": "WP_Rand", "title": "WP Random Color", "price": 200},
	{"id": "WP_Motion", "title": "Wallpaper Motion", "price": 7000},
	{"id": "WP_Warp", "title": "Wallpaper Warp", "price": 6500}
]

func _ready() -> void:
	_generate_wp_upgrades()

func _generate_wp_upgrades() -> void:
	# Clear placeholder UI
	for child in grid.get_children():
		child.queue_free()
		
	await get_tree().process_frame
	
	for i in range(wp_upgrades.size()):
		var item = wp_upgrades[i]
		var btn = _create_upgrade_button(item.id, item.title, item.price)
		grid.add_child(btn)
		
		if i % 3 == 0: await get_tree().process_frame

func _create_upgrade_button(item_id: String, title: String, price: int) -> Button:
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
	
	# Placeholder Icon (Dark Grey Box)
	var p_rect = ColorRect.new()
	p_rect.color = Color(0.2, 0.2, 0.2)
	p_rect.custom_minimum_size = Vector2(0, 70)
	p_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(p_rect)
		
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
