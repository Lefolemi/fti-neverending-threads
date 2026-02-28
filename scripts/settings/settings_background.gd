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

const COURSE_LIST = [
	"Manajemen Proyek Perangkat Lunak",
	"Jaringan Komputer",
	"Keamanan Siber",
	"Pemrograman Web 1",
	"Mobile Programming",
	"Metodologi Riset",
	"Computer Vision",
	"Pengolahan Citra Digital"
]

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

	# 2. Lock features the player hasn't bought yet
	_setup_shop_locks()

	# 3. Sync UI to GVar state without triggering signals
	_sync_ui_to_state()

# The Root Script calls this when the tab is clicked for the first time
func init_tab() -> void:
	_generate_wallpaper_grid()
	_setup_shop_locks() # Re-verify locks just in case they bought something
	_sync_ui_to_state()
	_update_live_background()

# --- SHOP LOCK LOGIC ---

func _setup_shop_locks() -> void:
	# Color Pickers
	var has_bg_picker = GVar.shop_unlocks.has("BG_Picker")
	bg_color_picker.disabled = not has_bg_picker
	wp_color_picker.disabled = not has_bg_picker
	
	# Random Buttons
	btn_rand_bg.disabled = not GVar.shop_unlocks.has("BG_Rand")
	btn_rand_wp.disabled = not GVar.shop_unlocks.has("WP_Rand")
	
	# Opacity
	var has_opacity = GVar.shop_unlocks.has("WP_Opacity")
	slider_opacity.editable = has_opacity
	slider_opacity.modulate = Color.WHITE if has_opacity else Color.DIM_GRAY
	
	# Motion
	var has_motion = GVar.shop_unlocks.has("WP_Motion")
	spin_motion_x.editable = has_motion
	spin_motion_x.modulate = Color.WHITE if has_motion else Color.DIM_GRAY
	spin_motion_y.editable = has_motion
	spin_motion_y.modulate = Color.WHITE if has_motion else Color.DIM_GRAY

	# Scale
	var has_scale = GVar.shop_unlocks.has("WP_Scale")
	spin_scale.editable = has_scale
	spin_scale.modulate = Color.WHITE if has_scale else Color.DIM_GRAY
	
	# Warp
	var has_warp = GVar.shop_unlocks.has("WP_Warp")
	spin_warp.editable = has_warp
	spin_warp.modulate = Color.WHITE if has_warp else Color.DIM_GRAY

# --- Grid Generation ---
func _generate_wallpaper_grid() -> void:
	for child in grid_wp.get_children():
		child.queue_free()
		
	# Grab total credits to check for Novice Rank
	var total_credits = _calculate_total_achievement_credits()
		
	# Generate all 24 Wallpapers
	for i in range(1, 25):
		var btn = TextureButton.new()
		btn.name = "WP_" + str(i)
		
		var tmb_path = "res://sprites/bg_thumbnail/tmb_" + str(i) + ".png"
		if ResourceLoader.exists(tmb_path):
			btn.texture_normal = load(tmb_path)
		
		btn.custom_minimum_size = Vector2(100, 100) 
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_COVERED
		btn.mouse_filter = Control.MOUSE_FILTER_PASS
		
		var is_unlocked = false
		
		# --- DYNAMIC UNLOCK LOGIC ---
		if i <= 15:
			# Wallpapers 1-15: Shop Unlocks
			is_unlocked = GVar.shop_unlocks.has("WP_" + str(i))
		elif i >= 16 and i <= 23:
			# Wallpapers 16-23: Course Specific Mastery (70% on all 14 sets)
			var course_idx = i - 16 # WP 16 maps to Course 0, WP 23 maps to Course 7
			is_unlocked = _has_70_percent_in_all_sets(course_idx)
		elif i == 24:
			# Wallpaper 24: Novice Rank (500 Credits)
			is_unlocked = total_credits >= 500
		
		if is_unlocked:
			btn.self_modulate = Color.WHITE 
			btn.pressed.connect(_on_wallpaper_clicked.bind(i, btn))
		else:
			btn.disabled = true
			btn.self_modulate = Color(0.2, 0.2, 0.2) # Dim the locked wallpapers heavily
			
		grid_wp.add_child(btn)
		
		if i % 4 == 0:
			await get_tree().process_frame

# --- UNLOCK HELPERS ---

func _has_70_percent_in_all_sets(course_index: int) -> bool:
	var course_name = COURSE_LIST[course_index]
	var stats = GVar.course_stats[course_name]
	
	for i in range(1, 15):
		var set_name = "Set " + str(i)
		var q_grade = stats["Quizizz"][set_name]["grade"]
		var e_grade = stats["Elearning"][set_name]["grade"]
		
		var highest_grade = 0.0
		
		if str(q_grade) != "Locked" and str(q_grade) != "Unplayed":
			highest_grade = max(highest_grade, float(q_grade))
		if str(e_grade) != "Locked" and str(e_grade) != "Unplayed":
			highest_grade = max(highest_grade, float(e_grade))
			
		# If even a single set is below 70%, it is locked.
		if highest_grade < 70.0:
			return false
			
	return true

func _calculate_total_achievement_credits() -> int:
	var total_cr = 0
	var path = "res://resources/csv/menu/achievement.csv"
	
	if not FileAccess.file_exists(path): return 0
		
	var file = FileAccess.open(path, FileAccess.READ)
	file.get_csv_line()
	
	var ach_values = {}
	while not file.eof_reached():
		var line = file.get_csv_line()
		if line.size() >= 2:
			var title = line[0].strip_edges()
			var credits = 0
			var split_desc = line[1].split("(")
			if split_desc.size() > 1:
				credits = split_desc[split_desc.size() - 1].to_int()
			ach_values[title] = credits
	file.close()
	
	for unlocked_title in GVar.unlocked_achievements:
		if ach_values.has(unlocked_title):
			total_cr += ach_values[unlocked_title]
			
	return total_cr

# --- UI LOGIC ---

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
		
		if current_selected_btn and is_instance_valid(current_selected_btn):
			current_selected_btn.self_modulate = Color.WHITE
			
		current_selected_btn = btn
		current_selected_btn.self_modulate = GVar.current_wp_color
		
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
	bg_color_picker.color = GVar.current_bg_color
	wp_color_picker.color = GVar.current_wp_color
	slider_opacity.set_value_no_signal(GVar.current_opacity)
	spin_motion_x.set_value_no_signal(GVar.current_velocity.x)
	spin_motion_y.set_value_no_signal(GVar.current_velocity.y)
	spin_scale.set_value_no_signal(GVar.current_scale)
	spin_warp.set_value_no_signal(GVar.current_warp)
	
	await get_tree().process_frame 
	
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
