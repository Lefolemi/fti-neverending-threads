extends GridContainer

@onready var btn_general: Button = $Menu/General
@onready var btn_background: Button = $Menu/Background

@onready var scroll_general: ScrollContainer = $Content/General
@onready var scroll_background: ScrollContainer = $Content/Background

# Bottom Confirmation Buttons
@onready var btn_apply: Button = $Confirm/Apply
@onready var btn_cancel: Button = $Confirm/Cancel
@onready var btn_reset: Button = $Confirm/ResetSet

# Flags to track if a tab has been generated yet
var is_general_loaded: bool = false
var is_background_loaded: bool = false

func _ready() -> void:
	# 1. Connect Tab Signals
	btn_general.pressed.connect(_on_general_tab_pressed)
	btn_background.pressed.connect(_on_background_tab_pressed)
	
	# 2. Connect Utility Signals
	btn_cancel.pressed.connect(_on_cancel_pressed)
	btn_apply.pressed.connect(_on_apply_pressed)
	if btn_reset:
		btn_reset.pressed.connect(_on_reset_pressed)
	
	# 3. Connect the Data-Swap Signal from General Settings
	scroll_general.set_change_requested.connect(_on_set_change_requested)
	
	# 4. Open default tab
	_on_general_tab_pressed()

# --- TAB NAVIGATION LOGIC ---

func _on_general_tab_pressed() -> void:
	scroll_general.show()
	scroll_background.hide()
	
	btn_general.modulate = Color.WHITE
	btn_background.modulate = Color(0.5, 0.5, 0.5)
	
	# LAZY LOAD: Only build the UI if it hasn't been built yet
	if not is_general_loaded:
		is_general_loaded = true

func _on_background_tab_pressed() -> void:
	scroll_general.hide()
	scroll_background.show()

	btn_background.modulate = Color.WHITE
	btn_general.modulate = Color(0.5, 0.5, 0.5)
	
	# LAZY LOAD: Wait until the user actually clicks this tab!
	if not is_background_loaded:
		if scroll_background.has_method("init_tab"):
			scroll_background.init_tab()
		is_background_loaded = true

# --- AESTHETIC SET MANAGEMENT LOGIC ---

func _on_set_change_requested(new_set: int) -> void:
	# 1. SAVE THE CURRENT SET
	# Before we switch away, save whatever the player was tweaking into the current slot
	SaveManager.save_game()
	
	# 2. CHANGE THE ACTIVE SLOT
	GVar.active_set = new_set
	
	# 3. UNPACK THE NEW SET'S DATA INTO LIVE VARIABLES
	var active_id = str(new_set)
	if GVar.aesthetic_sets.has(active_id):
		var config = GVar.aesthetic_sets[active_id]
		
		GVar.ui_color = config.get("ui_color", 0)
		GVar.invert_ui_color = config.get("invert_ui_color", false)
		GVar.curved_borders = config.get("curved_borders", false)
		GVar.ui_shadow = config.get("ui_shadow", false)
		
		GVar.current_bg_color = Color(config.get("bg_color", "4d4d4d"))
		GVar.current_wp_color = Color(config.get("wp_color", "ffffff"))
		GVar.current_opacity = config.get("wp_opacity", 1.0)
		GVar.current_wp_id = config.get("wp_id", 0)
		
		GVar.current_velocity = Vector2(config.get("wp_motion_x", 0.0), config.get("wp_motion_y", 0.0))
		GVar.current_scale = config.get("wp_scale", 1.0)
		GVar.current_warp = config.get("wp_warp", 0.0)
	
	# 4. APPLY THE NEW AESTHETICS GLOBALLY
	ThemeEngine.use_curves = GVar.curved_borders
	ThemeEngine.use_shadows = GVar.ui_shadow
	ThemeEngine.use_light_mode = GVar.invert_ui_color
	
	# FIX: Look up the ACTUAL UI Color Hex from the General Settings palette!
	var actual_ui_color = Color("2b2b2b") # Default Classic
	if is_instance_valid(scroll_general) and "COLOR_PALETTE" in scroll_general:
		var ui_palette_values = scroll_general.COLOR_PALETTE.values()
		if GVar.ui_color >= 0 and GVar.ui_color < ui_palette_values.size():
			actual_ui_color = ui_palette_values[GVar.ui_color]
			
	ThemeEngine.refresh_theme(actual_ui_color)
	
	var wp_tex: Texture2D = null
	if GVar.current_wp_id > 0:
		var full_wp_path = "res://sprites/bg/bg_" + str(GVar.current_wp_id) + ".png"
		if ResourceLoader.exists(full_wp_path):
			wp_tex = load(full_wp_path)
			
	BG.apply_background_settings(wp_tex, GVar.current_wp_color, GVar.current_opacity, GVar.current_scale, GVar.current_velocity, GVar.current_warp)
	
	# 5. REFRESH BOTH MENUS VISUALLY
	if is_general_loaded and scroll_general.has_method("refresh_all_ui"):
		scroll_general.refresh_all_ui()
		
	if is_background_loaded and scroll_background.has_method("_sync_ui_to_state"):
		scroll_background._sync_ui_to_state()

# --- UTILITY BUTTONS ---

func _on_apply_pressed() -> void:
	# Because of the way SaveManager is built, calling save_game() automatically 
	# grabs everything on screen and locks it into the Active Set dictionary!
	SaveManager.save_game()
	
	if has_node("/root/Audio"):
		Audio.play_sfx("res://audio/sfx/notification.wav")
		
	# Optional visual feedback
	btn_apply.text = "Saved!"
	await get_tree().create_timer(1.5).timeout
	btn_apply.text = "Apply"

func _on_reset_pressed() -> void:
	var is_sure = await ConfirmManager.ask("Are you sure you want to reset Set " + str(GVar.active_set) + " to its default look? This cannot be undone.")
	
	if is_sure:
		# 1. Reset Live Variables to standard defaults
		GVar.ui_color = 0 # Classic
		GVar.invert_ui_color = false
		GVar.curved_borders = false
		GVar.ui_shadow = false
		
		GVar.current_bg_color = Color("4d4d4d")
		GVar.current_wp_color = Color("ffffff")
		GVar.current_opacity = 1.0
		GVar.current_wp_id = 0
		
		GVar.current_velocity = Vector2.ZERO
		GVar.current_scale = 1.0
		GVar.current_warp = 0.0
		
		# 2. Apply Defaults Globally
		ThemeEngine.use_curves = false
		ThemeEngine.use_shadows = false
		ThemeEngine.use_light_mode = false
		
		# FIX: Safely grab the Classic Color
		var reset_ui_color = Color("2b2b2b")
		if is_instance_valid(scroll_general) and "COLOR_PALETTE" in scroll_general:
			var palette = scroll_general.COLOR_PALETTE.values()
			if palette.size() > 0:
				reset_ui_color = palette[0]
				
		ThemeEngine.refresh_theme(reset_ui_color)
		BG.apply_background_settings(null, GVar.current_wp_color, 1.0, 1.0, Vector2.ZERO, 0.0)
		
		# 3. Save the reset state to the JSON
		SaveManager.save_game()
		
		# 4. Force the UI to update to match the newly reset variables
		if is_general_loaded and scroll_general.has_method("refresh_all_ui"):
			scroll_general.refresh_all_ui()
		if is_background_loaded and scroll_background.has_method("_sync_ui_to_state"):
			scroll_background._sync_ui_to_state()

func _on_cancel_pressed() -> void:
	if GVar.last_scene != "":
		Load.load_res([GVar.last_scene], GVar.last_scene)
	else:
		push_warning("GVar.last_scene is empty!")
