extends Control # Change to VBoxContainer or whatever node type WallpaperShop is

# We emit this so the Root Shop script knows what we clicked!
signal item_selected(item_id: String, item_title: String, price: int, btn: Button)

@onready var grid: GridContainer = $WallpaperGrid

func _ready() -> void:
	_generate_wallpapers()

func _generate_wallpapers() -> void:
	# Clear placeholder UI
	for child in grid.get_children():
		child.queue_free()
		
	await get_tree().process_frame
	
	for i in range(1, 16):
		var price = 1500 if i <= 12 else 3000
		var tex_path = "res://sprites/bg_thumbnail/tmb_" + str(i) + ".png"
		var tex = load(tex_path) if ResourceLoader.exists(tex_path) else null
		
		var btn = _create_wp_button("WP_" + str(i), "Wallpaper " + str(i), price, tex)
		grid.add_child(btn)
		
		# Yield occasionally to prevent stuttering on load
		if i % 4 == 0: await get_tree().process_frame

func _create_wp_button(item_id: String, title: String, price: int, tex: Texture2D) -> Button:
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
	
	# Wallpaper Thumbnail
	if tex:
		var tex_rect = TextureRect.new()
		tex_rect.texture = tex
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex_rect.custom_minimum_size = Vector2(0, 70)
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(tex_rect)
	else:
		# Fallback if image is missing
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
		
	# When clicked, emit the signal with all the data the Root needs
	btn.pressed.connect(func():
		item_selected.emit(item_id, title, price, btn)
	)
	
	return btn
