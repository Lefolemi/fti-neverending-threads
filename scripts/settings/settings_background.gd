extends ScrollContainer

# --- Node References ---
@onready var bg_color_picker: ColorPickerButton = $Margin/VBox/BGColorPicker
@onready var btn_rand_bg: Button = $Margin/VBox/BGColorButtons/RandomColor

@onready var wp_color_picker: ColorPickerButton = $Margin/VBox/WallpaperColorPicker
@onready var btn_rand_wp: Button = $Margin/VBox/WallpaperColorButtons/RandomColor

@onready var grid_wp: GridContainer = $Margin/VBox/WallpaperGrid
@onready var slider_opacity: Slider = $Margin/VBox/WallpaperOpacitySlider

@onready var spin_motion_x: SpinBox = $Margin/VBox/WallpaperMotionBox/MotionX
@onready var spin_motion_y: SpinBox = $Margin/VBox/WallpaperMotionBox/MotionY
@onready var spin_scale: SpinBox = $Margin/VBox/WallpaperScale
@onready var spin_warp: SpinBox = $Margin/VBox/WallpaperWarp

# UI Tracking
var selection_label: Label
var current_selected_btn: TextureButton = null # Track exactly which button is active

func _ready() -> void:
	_setup_selection_label()

	# 1. Connect Signals
	bg_color_picker.color_changed.connect(_on_bg_color_changed)
	btn_rand_bg.pressed.connect(_on_rand_bg_pressed)
	
	wp_color_picker.color_changed.connect(_on_wp_color_changed)
	btn_rand_wp.pressed.connect(_on_rand_wp_pressed)
	
	slider_opacity.value_changed.connect(_on_opacity_changed)
	spin_motion_x.value_changed.connect(_on_motion_x_changed)
	spin_motion_y.value_changed.connect(_on_motion_y_changed)
	spin_scale.value_changed.connect(_on_scale_changed)
	spin_warp.value_changed.connect(_on_warp_changed)

	# 2. Sync UI to GVar state without triggering signals
	_sync_ui_to_state()

# The Root Script calls this when the tab is clicked for the first time
func init_tab() -> void:
	_generate_wallpaper_grid()
	_sync_ui_to_state()
	_update_live_background()

# --- Grid Generation ---
func _generate_wallpaper_grid() -> void:
	for child in grid_wp.get_children():
		child.queue_free()
		
	for i in range(1, 25):
		var btn = TextureButton.new()
		btn.name = "WP_" + str(i)
		
		var tmb_path = "res://sprites/bg_thumbnail/tmb_" + str(i) + ".png"
		if ResourceLoader.exists(tmb_path):
			btn.texture_normal = load(tmb_path)
		
		btn.custom_minimum_size = Vector2(100, 100) 
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_COVERED
		btn.self_modulate = Color.WHITE 
		
		btn.pressed.connect(_on_wallpaper_clicked.bind(i, btn))
		grid_wp.add_child(btn)
		
		# --- THE CHUNKING FIX ---
		# Every 4 wallpapers, pause execution until the next visual frame.
		# This keeps the game running at 60fps while loading in the background!
		if i % 4 == 0:
			await get_tree().process_frame

func _setup_selection_label() -> void:
	selection_label = Label.new()
	selection_label.text = "SELECTED"
	selection_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	selection_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	selection_label.add_theme_color_override("font_color", Color.YELLOW)
	selection_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	selection_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)

# --- Interactions ---

func _on_wallpaper_clicked(id: int, btn: TextureButton) -> void:
	# Check if we are clicking the one already selected
	if GVar.current_wp_id == id:
		# DESELECT LOGIC
		GVar.current_wp_id = 0
		btn.self_modulate = Color.WHITE
		if selection_label.get_parent():
			selection_label.get_parent().remove_child(selection_label)
		current_selected_btn = null
	else:
		# SELECT LOGIC
		GVar.current_wp_id = id
		
		# Reset the OLD button to pure white
		if current_selected_btn and is_instance_valid(current_selected_btn):
			current_selected_btn.self_modulate = Color.WHITE
			
		# Set the NEW button
		current_selected_btn = btn
		current_selected_btn.self_modulate = GVar.current_wp_color
		
		# Move the "Selected" label
		if selection_label.get_parent():
			selection_label.get_parent().remove_child(selection_label)
		btn.add_child(selection_label)
	
	_update_live_background()

func _on_bg_color_changed(color: Color) -> void:
	GVar.current_bg_color = color
	_update_live_background()

func _on_rand_bg_pressed() -> void:
	var rand_c = Color(randf(), randf(), randf())
	bg_color_picker.color = rand_c
	_on_bg_color_changed(rand_c)

func _on_wp_color_changed(color: Color) -> void:
	GVar.current_wp_color = color
	# ONLY tint the actively selected thumbnail
	if current_selected_btn and is_instance_valid(current_selected_btn):
		current_selected_btn.self_modulate = color
		
	_update_live_background()

func _on_rand_wp_pressed() -> void:
	var rand_c = Color(randf(), randf(), randf())
	wp_color_picker.color = rand_c
	_on_wp_color_changed(rand_c)

func _on_opacity_changed(value: float) -> void:
	GVar.current_opacity = value
	_update_live_background()

func _on_motion_x_changed(value: float) -> void:
	GVar.current_velocity.x = value
	_update_live_background()

func _on_motion_y_changed(value: float) -> void:
	GVar.current_velocity.y = value
	_update_live_background()

func _on_scale_changed(value: float) -> void:
	GVar.current_scale = value
	_update_live_background()

func _on_warp_changed(value: float) -> void:
	GVar.current_warp = value
	_update_live_background()

# --- Core Update Logic ---

func _sync_ui_to_state() -> void:
	# Use set_value_no_signal to prevent firing signals during UI setup
	bg_color_picker.color = GVar.current_bg_color
	wp_color_picker.color = GVar.current_wp_color
	slider_opacity.set_value_no_signal(GVar.current_opacity)
	spin_motion_x.set_value_no_signal(GVar.current_velocity.x)
	spin_motion_y.set_value_no_signal(GVar.current_velocity.y)
	spin_scale.set_value_no_signal(GVar.current_scale)
	spin_warp.set_value_no_signal(GVar.current_warp)
	
	await get_tree().process_frame 
	
	# Manually attach the selection label to the correct button WITHOUT simulating a click
	if GVar.current_wp_id > 0:
		var active_btn = grid_wp.get_node_or_null("WP_" + str(GVar.current_wp_id))
		if active_btn:
			current_selected_btn = active_btn
			current_selected_btn.self_modulate = GVar.current_wp_color
			if selection_label.get_parent():
				selection_label.get_parent().remove_child(selection_label)
			current_selected_btn.add_child(selection_label)

func _update_live_background() -> void:
	BG.set_bg_color(GVar.current_bg_color)

	var wp_tex: Texture2D = null
	# Only attempt to load if ID is valid (greater than 0)
	if GVar.current_wp_id > 0:
		var full_wp_path = "res://sprites/bg/bg_" + str(GVar.current_wp_id) + ".png"
		if ResourceLoader.exists(full_wp_path):
			wp_tex = load(full_wp_path)

	# Send updated GVar data to the Autoload Shader
	BG.apply_background_settings(
		wp_tex, 
		GVar.current_wp_color, 
		GVar.current_opacity, 
		GVar.current_scale, 
		GVar.current_velocity, 
		GVar.current_warp
	)
