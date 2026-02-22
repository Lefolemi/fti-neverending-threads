extends GridContainer

# --- Node References ---
@onready var title_label: Label = $Title
@onready var content_panel: Control = $Content
@onready var confirm_panel: Control = $Confirm

@onready var grid_wp: GridContainer = $Content/Scroll/VBox/WallpaperShop/WallpaperGrid
@onready var grid_colors: GridContainer = $Content/Scroll/VBox/UIColorShop/ColorThemeGrid
@onready var grid_ui_theme: GridContainer = $Content/Scroll/VBox/UIThemeShop/UIThemeGrid
@onready var grid_wp_theme: GridContainer = $Content/Scroll/VBox/WallpaperThemeShop/WallpaperThemeGrid
@onready var grid_sets: GridContainer = $Content/Scroll/VBox/SetShop/SetGrid

@onready var lbl_points: Label = $Confirm/PointsCounter
@onready var btn_buy: Button = $Confirm/Buy
@onready var btn_preview: Button = $Confirm/Preview
@onready var btn_close: Button = $Confirm/Close


# --- Shop Data ---
const COLOR_PALETTE = {
	"Classic": Color("2b2b2b"), "Midnight": Color("121212"), "Ocean": Color("0f2027"),
	"Pine": Color("1b4332"), "Wine": Color("4a0404"), "Eggplant": Color("311b3d"),
	"Chocolate": Color("3e2723"), "Rust": Color("8a3324"), "Navy": Color("000033"),
	"Olive": Color("33691e"), "Charcoal": Color("36454F"), "Indigo": Color("1a0b2e")
}

var ui_upgrades = [
	{"id": "UI_Curved", "title": "Curved Borders", "price": 750},
	{"id": "UI_Shadow", "title": "UI Shadow", "price": 750},
	{"id": "UI_Invert", "title": "Invert UI Color", "price": 3500}
]

var wp_upgrades = [
	{"id": "BG_Picker", "title": "BG Color Picker", "price": 1200},
	{"id": "BG_Rand", "title": "BG Random Color", "price": 200},
	{"id": "WP_Opacity", "title": "Wallpaper Opacity", "price": 500},
	{"id": "WP_Scale", "title": "Wallpaper Scale", "price": 2000},
	{"id": "WP_Rand", "title": "WP Random Color", "price": 200},
	{"id": "WP_Motion", "title": "Wallpaper Motion", "price": 7000},
	{"id": "WP_Warp", "title": "Wallpaper Warp", "price": 6500}
]

var set_upgrades = [
	{"id": "SET_2", "title": "Set 2", "price": 10000},
	{"id": "SET_3", "title": "Set 3", "price": 10000}
]

# State
var current_selected_btn: Button = null
var current_selected_id: String = ""

# Preview State
# Preview State
var is_previewing_wp: bool = false
var is_previewing_color: bool = false
var original_title_text: String = "Shop"
var pre_preview_ui_color: Color # <-- ADD THIS SNAPSHOT VARIABLE

func _ready() -> void:
	# Store the original title so we can restore it
	original_title_text = title_label.text
	
	# Enable GUI input on the Title Label so players can click it to cancel
	title_label.mouse_filter = Control.MOUSE_FILTER_STOP
	title_label.gui_input.connect(_on_title_gui_input)
	
	btn_close.pressed.connect(_on_close_pressed)
	btn_preview.pressed.connect(_on_preview_pressed)
	
	btn_buy.disabled = true
	btn_preview.disabled = true
	
	_generate_shop_ui()

# --- Async UI Generation ---
func _generate_shop_ui() -> void:
	for grid in [grid_wp, grid_colors, grid_ui_theme, grid_wp_theme, grid_sets]:
		if grid:
			for child in grid.get_children():
				child.queue_free()
	
	await get_tree().process_frame
	
	# 1. Wallpapers (1-15)
	for i in range(1, 16):
		var price = 1500 if i <= 12 else 3000
		var tex_path = "res://sprites/bg_thumbnail/tmb_" + str(i) + ".png"
		var tex = load(tex_path) if ResourceLoader.exists(tex_path) else null
		
		var btn = _create_shop_button("WP_" + str(i), "Wallpaper " + str(i), price, tex, Color.TRANSPARENT)
		grid_wp.add_child(btn)
		if i % 4 == 0: await get_tree().process_frame 
		
	# 2. UI Colors
	var color_names = COLOR_PALETTE.keys()
	for i in range(color_names.size()):
		var c_name = color_names[i]
		var btn = _create_shop_button("CLR_" + c_name, c_name, 300, null, COLOR_PALETTE[c_name])
		grid_colors.add_child(btn)
		if i % 4 == 0: await get_tree().process_frame
		
	# 3. UI Theme Upgrades
	for i in range(ui_upgrades.size()):
		var item = ui_upgrades[i]
		grid_ui_theme.add_child(_create_shop_button(item.id, item.title, item.price))
		if i % 2 == 0: await get_tree().process_frame
	
	# 4. Wallpaper Theme Upgrades
	for i in range(wp_upgrades.size()):
		var item = wp_upgrades[i]
		grid_wp_theme.add_child(_create_shop_button(item.id, item.title, item.price))
		if i % 3 == 0: await get_tree().process_frame
	
	# 5. Sets
	for i in range(set_upgrades.size()):
		var item = set_upgrades[i]
		grid_sets.add_child(_create_shop_button(item.id, item.title, item.price))
		if i % 2 == 0: await get_tree().process_frame

# --- The Universal Shop Button Builder ---
func _create_shop_button(item_id: String, title: String, price: int, tex: Texture2D = null, color_val: Color = Color.TRANSPARENT) -> Button:
	var btn = Button.new()
	btn.name = item_id
	btn.custom_minimum_size = Vector2(110, 140)
	btn.self_modulate = Color.WHITE 
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE, 5)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn.add_child(vbox)
	
	if tex:
		var tex_rect = TextureRect.new()
		tex_rect.texture = tex
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex_rect.custom_minimum_size = Vector2(0, 70)
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(tex_rect)
	elif color_val != Color.TRANSPARENT:
		var c_rect = ColorRect.new()
		c_rect.color = color_val
		c_rect.custom_minimum_size = Vector2(0, 70)
		c_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(c_rect)
	else:
		var p_rect = ColorRect.new()
		p_rect.color = Color(0.2, 0.2, 0.2)
		p_rect.custom_minimum_size = Vector2(0, 70)
		p_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(p_rect)
		
	var lbl_title = Label.new()
	lbl_title.text = title
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_title.add_theme_font_size_override("font_size", 12)
	lbl_title.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(lbl_title)
	
	var lbl_price = Label.new()
	lbl_price.text = str(price) + " Pts"
	lbl_price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_price.add_theme_color_override("font_color", Color.YELLOW)
	lbl_price.add_theme_font_size_override("font_size", 12)
	vbox.add_child(lbl_price)
	
	btn.pressed.connect(_on_item_clicked.bind(item_id, price, btn))
	return btn

# --- Interactions ---
func _on_item_clicked(item_id: String, price: int, btn: Button) -> void:
	# If they click a new item while previewing a UI color, cancel the preview
	if is_previewing_color:
		_stop_preview()
		
	current_selected_id = item_id
	
	if current_selected_btn and is_instance_valid(current_selected_btn):
		current_selected_btn.self_modulate = Color.WHITE
		
	current_selected_btn = btn
	current_selected_btn.self_modulate = Color.YELLOW 
	
	btn_buy.disabled = false
	
	if item_id.begins_with("CLR_") or (item_id.begins_with("WP_") and item_id.trim_prefix("WP_").is_valid_int()):
		btn_preview.disabled = false
	else:
		btn_preview.disabled = true

# --- Preview Logic ---
func _on_preview_pressed() -> void:
	if current_selected_id.begins_with("WP_"):
		is_previewing_wp = true
		content_panel.hide()
		confirm_panel.hide()
		title_label.text = "Press anywhere to stop preview"
		
		var wp_id = current_selected_id.trim_prefix("WP_").to_int()
		var full_wp_path = "res://sprites/bg/bg_" + str(wp_id) + ".png"
		var wp_tex = load(full_wp_path) if ResourceLoader.exists(full_wp_path) else null
		
		BG.apply_background_settings(wp_tex, GVar.current_wp_color, GVar.current_opacity, GVar.current_scale, GVar.current_velocity, GVar.current_warp)
		
	elif current_selected_id.begins_with("CLR_"):
		is_previewing_color = true
		title_label.text = "Press Title to stop preview"
		
		# 1. SNAPSHOT THE ORIGINAL COLOR BEFORE CHANGING IT
		pre_preview_ui_color = ThemeEngine.current_background_color
		
		# 2. Apply the preview color
		var c_name = current_selected_id.trim_prefix("CLR_")
		ThemeEngine.current_background_color = COLOR_PALETTE[c_name] # Force the state change
		ThemeEngine.refresh_theme(COLOR_PALETTE[c_name])

func _stop_preview() -> void:
	if is_previewing_wp:
		is_previewing_wp = false
		content_panel.show()
		confirm_panel.show()
		title_label.text = original_title_text
		
		var wp_tex: Texture2D = null
		if GVar.current_wp_id > 0:
			var full_wp_path = "res://sprites/bg/bg_" + str(GVar.current_wp_id) + ".png"
			if ResourceLoader.exists(full_wp_path):
				wp_tex = load(full_wp_path)
		BG.apply_background_settings(wp_tex, GVar.current_wp_color, GVar.current_opacity, GVar.current_scale, GVar.current_velocity, GVar.current_warp)
		
	if is_previewing_color:
		is_previewing_color = false
		title_label.text = original_title_text
		
		# 3. RESTORE FROM THE SNAPSHOT
		ThemeEngine.current_background_color = pre_preview_ui_color 
		ThemeEngine.refresh_theme(pre_preview_ui_color)

# Detect clicks on the Title to stop the preview
func _on_title_gui_input(event: InputEvent) -> void:
	if (is_previewing_wp or is_previewing_color) and (event is InputEventMouseButton or event is InputEventScreenTouch) and event.is_pressed():
		_stop_preview()

# Detect clicks ANYWHERE on the screen when wallpaper is fullscreen
func _input(event: InputEvent) -> void:
	if is_previewing_wp and (event is InputEventMouseButton or event is InputEventScreenTouch) and event.is_pressed():
		_stop_preview()
		get_viewport().set_input_as_handled() # Prevent the click from triggering anything else

func _on_close_pressed() -> void:
	if is_previewing_color or is_previewing_wp:
		_stop_preview()
		
	if GVar.last_scene != "":
		Load.load_res([GVar.last_scene], GVar.last_scene)
	else:
		push_warning("GVar.last_scene is empty!")
