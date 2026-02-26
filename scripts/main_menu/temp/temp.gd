extends Node2D

# We bring the palette here so it knows exactly what hex colors to use
const COLOR_PALETTE = [
	Color("2b2b2b"),   # 0: Classic
	Color("121212"),   # 1: Midnight
	Color("0f2027"),   # 2: Ocean
	Color("1b4332"),   # 3: Pine
	Color("4a0404"),   # 4: Wine
	Color("311b3d"),   # 5: Eggplant
	Color("3e2723"),   # 6: Chocolate
	Color("8a3324"),   # 7: Rust
	Color("000033"),   # 8: Navy
	Color("33691e"),   # 9: Olive
	Color("36454F"),   # 10: Charcoal
	Color("1a0b2e")    # 11: Indigo
]

func _ready() -> void:
	# Wait for 1 frame so the "Loading" text/logo actually draws on the screen
	await get_tree().process_frame
	
	# Now do the work
	_start_boot_sequence()

func _start_boot_sequence() -> void:
	_apply_boot_aesthetics()

	var assets_to_load = [
		"res://scenes/main/main_menu/main_menu.tscn",
		"res://scripts/global/vars/global_constant.gd",
		"res://scripts/global/vars/global_variable.gd",
	]

	Load.load_res(assets_to_load, "res://scenes/main/main_menu/main_menu.tscn")


# --- INITIALIZATION LOGIC ---

func _apply_boot_aesthetics() -> void:
	# SaveManager has already unpacked the active set into GVar.
	# Now we just need to wake up ThemeEngine and BG to apply them!
	
	# 1. Apply UI Theme
	ThemeEngine.use_curves = GVar.curved_borders
	ThemeEngine.use_shadows = GVar.ui_shadow
	ThemeEngine.use_light_mode = GVar.invert_ui_color
	
	var actual_ui_color = COLOR_PALETTE[0] # Fallback to Classic
	if typeof(GVar.ui_color) == TYPE_INT and GVar.ui_color >= 0 and GVar.ui_color < COLOR_PALETTE.size():
		actual_ui_color = COLOR_PALETTE[GVar.ui_color]
		
	ThemeEngine.refresh_theme(actual_ui_color)
	
	# 2. Apply Background
	var wp_tex: Texture2D = null
	if GVar.current_wp_id > 0:
		var full_wp_path = "res://sprites/bg/bg_" + str(GVar.current_wp_id) + ".png"
		if ResourceLoader.exists(full_wp_path):
			wp_tex = load(full_wp_path)
			
	BG.apply_background_settings(
		wp_tex, 
		GVar.current_wp_color, 
		GVar.current_opacity, 
		GVar.current_scale, 
		GVar.current_velocity, 
		GVar.current_warp
	)
	
	print("SYSTEM: Boot aesthetics successfully applied for Set ", GVar.active_set)
