extends GridContainer

# --- Node References ---
@onready var title_label: Label = $Title
@onready var content_panel: Control = $Content
@onready var confirm_panel: Control = $Confirm

# The 5 self-sufficient shop categories
@onready var shop_wp = $Content/Scroll/VBox/WallpaperShop
@onready var shop_colors = $Content/Scroll/VBox/UIColorShop
@onready var shop_ui_theme = $Content/Scroll/VBox/UIThemeShop
@onready var shop_wp_theme = $Content/Scroll/VBox/WallpaperThemeShop
@onready var shop_sets = $Content/Scroll/VBox/SetShop

# We still need the palette here just to know what color to preview!
const COLOR_PALETTE = {
	"Classic": Color("2b2b2b"), "Midnight": Color("121212"), "Ocean": Color("0f2027"),
	"Pine": Color("1b4332"), "Wine": Color("4a0404"), "Eggplant": Color("311b3d"),
	"Chocolate": Color("3e2723"), "Rust": Color("8a3324"), "Navy": Color("000033"),
	"Olive": Color("33691e"), "Charcoal": Color("36454F"), "Indigo": Color("1a0b2e")
}

# --- State ---
var current_selected_btn: Button = null
var current_selected_id: String = ""
var current_selected_title: String = "" 
var current_selected_price: int = 0 

# Preview State
var is_previewing_wp: bool = false
var is_previewing_color: bool = false
var original_title_text: String = "Shop"
var pre_preview_ui_color: Color 

func _ready() -> void:
	# 1. Title setup for stopping previews
	original_title_text = title_label.text
	title_label.mouse_filter = Control.MOUSE_FILTER_STOP
	title_label.gui_input.connect(_on_title_gui_input)
	
	# 2. Wire up the Confirm Panel
	confirm_panel.buy_requested.connect(_on_buy_requested)
	confirm_panel.preview_requested.connect(_on_preview_requested)
	confirm_panel.close_requested.connect(_on_close_requested)
	
	# 3. Wire up ALL Shop Categories with a single loop!
	for category in [shop_wp, shop_colors, shop_ui_theme, shop_wp_theme, shop_sets]:
		category.item_selected.connect(_on_item_selected)
		
	# 4. Initial UI State
	confirm_panel.update_points_display(GVar.current_points)

# --- Signal Handlers ---

func _on_item_selected(item_id: String, item_title: String, price: int, btn: Button) -> void:
	# Stop any active preview if we are clicking around
	if is_previewing_color:
		_stop_preview()
		
	current_selected_id = item_id
	current_selected_title = item_title
	current_selected_price = price
	
	# Handle button highlight toggling
	if current_selected_btn and is_instance_valid(current_selected_btn):
		current_selected_btn.self_modulate = Color.WHITE
		
	current_selected_btn = btn
	current_selected_btn.self_modulate = Color.YELLOW 
	
	# Check states to tell the Confirm panel what to do
	var is_owned = GVar.shop_unlocks.has(item_id)
	var can_preview = item_id.begins_with("CLR_") or (item_id.begins_with("WP_") and item_id.trim_prefix("WP_").is_valid_int())
	
	confirm_panel.setup_buttons_for_item(is_owned, price, can_preview)

func _on_buy_requested() -> void:
	if current_selected_id == "" or GVar.shop_unlocks.has(current_selected_id):
		return
		
	# --- 1. THE POOR CHECK ---
	if GVar.current_points < current_selected_price:
		Audio.play_sfx("res://audio/sfx/wrong.wav")
		title_label.text = "Not enough money!!"
		title_label.add_theme_color_override("font_color", Color.RED)
		
		# Wait 2 seconds, then reset
		await get_tree().create_timer(2.0).timeout
		title_label.text = original_title_text
		title_label.remove_theme_color_override("font_color")
		return
		
	# --- 2. THE CONFIRMATION MANAGER ---
	var is_sure = await ConfirmManager.ask("Are you sure you want to buy " + current_selected_title + " for " + str(current_selected_price) + " Pts?")
	
	# --- 3. THE PURCHASE ---
	if is_sure:
		Audio.play_sfx("res://audio/sfx/buy.wav")
		
		# Deduct Points & Add to Unlocks
		GVar.current_points -= current_selected_price
		GVar.shop_unlocks.append(current_selected_id)
		SaveManager.save_game()
		
		# Update UI
		confirm_panel.update_points_display(GVar.current_points)
		
		if current_selected_btn and is_instance_valid(current_selected_btn):
			var price_node = current_selected_btn.get_node("VBox/PriceLabel")
			if price_node:
				price_node.text = "SOLD"
				price_node.add_theme_color_override("font_color", Color.GREEN)
				
		# Refresh the confirm button text to "Owned"
		confirm_panel.setup_buttons_for_item(true, current_selected_price, false)

func _on_close_requested() -> void:
	if is_previewing_color or is_previewing_wp:
		_stop_preview()
		
	if GVar.last_scene != "":
		Load.load_res([GVar.last_scene], GVar.last_scene)
	else:
		push_warning("GVar.last_scene is empty!")

# --- Preview Logic ---

func _on_preview_requested() -> void:
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
		
		pre_preview_ui_color = ThemeEngine.current_background_color
		
		var c_name = current_selected_id.trim_prefix("CLR_")
		ThemeEngine.current_background_color = COLOR_PALETTE[c_name] 
		ThemeEngine.refresh_theme(COLOR_PALETTE[c_name])

func _stop_preview() -> void:
	if is_previewing_wp:
		is_previewing_wp = false
		content_panel.show()
		confirm_panel.show()
		title_label.text = original_title_text
		
		# Restore original Wallpaper
		var wp_tex: Texture2D = null
		if GVar.current_wp_id > 0:
			var full_wp_path = "res://sprites/bg/bg_" + str(GVar.current_wp_id) + ".png"
			if ResourceLoader.exists(full_wp_path):
				wp_tex = load(full_wp_path)
		BG.apply_background_settings(wp_tex, GVar.current_wp_color, GVar.current_opacity, GVar.current_scale, GVar.current_velocity, GVar.current_warp)
		
	if is_previewing_color:
		is_previewing_color = false
		title_label.text = original_title_text
		
		# Restore original Color
		ThemeEngine.current_background_color = pre_preview_ui_color 
		ThemeEngine.refresh_theme(pre_preview_ui_color)

# --- Input / Interrupt Handlers ---

func _on_title_gui_input(event: InputEvent) -> void:
	if (is_previewing_wp or is_previewing_color) and (event is InputEventMouseButton or event is InputEventScreenTouch) and event.is_pressed():
		_stop_preview()

func _input(event: InputEvent) -> void:
	if is_previewing_wp and (event is InputEventMouseButton or event is InputEventScreenTouch) and event.is_pressed():
		_stop_preview()
		get_viewport().set_input_as_handled()
