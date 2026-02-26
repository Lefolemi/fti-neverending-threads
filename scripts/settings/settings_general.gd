extends ScrollContainer

# Signal to tell the Root script to handle the data swap
signal set_change_requested(set_num: int)

@onready var color_grid: GridContainer = $Margin/VBox/UIColorGrid
@onready var chk_curved: CheckBox = $Margin/VBox/ThemeOptions/CurvedBorders
@onready var chk_shadow: CheckBox = $Margin/VBox/ThemeOptions/UIShadow
@onready var chk_invert: CheckBox = $Margin/VBox/ThemeOptions/InvertUIColor

# --- Sets ---
@onready var set_buttons: Array = [
	$Margin/VBox/SetList/Set1,
	$Margin/VBox/SetList/Set2,
	$Margin/VBox/SetList/Set3,
	$Margin/VBox/SetList/Set4,
	$Margin/VBox/SetList/Set5,
	$Margin/VBox/SetList/Set6
]

# --- Audio Sliders ---
@onready var slider_music: Slider = $Margin/VBox/MusicSlider
@onready var slider_sfx: Slider = $Margin/VBox/SoundSlider

var current_selected_label: Label = null

const COLOR_PALETTE = {
	"Classic": Color("2b2b2b"),   # Index 0
	"Midnight": Color("121212"),  # Index 1
	"Ocean": Color("0f2027"),     # Index 2
	"Pine": Color("1b4332"),      # Index 3
	"Wine": Color("4a0404"),      # Index 4
	"Eggplant": Color("311b3d"),  # Index 5
	"Chocolate": Color("3e2723"), # Index 6
	"Rust": Color("8a3324"),      # Index 7
	"Navy": Color("000033"),      # Index 8
	"Olive": Color("33691e"),     # Index 9
	"Charcoal": Color("36454F"),  # Index 10
	"Indigo": Color("1a0b2e")     # Index 11
}

func _ready() -> void:
	# 1. Initialize Sets
	_setup_sets_list()
	
	# 2. Setup Checkboxes & Shop Locks
	_setup_checkboxes()
	
	# Connect checkbox signals ONCE in ready
	chk_curved.toggled.connect(_on_curved_toggled)
	chk_shadow.toggled.connect(_on_shadow_toggled)
	chk_invert.toggled.connect(_on_invert_toggled)
	
	# 3. Setup Audio Sliders from GVar
	slider_music.value = GVar.music_volume
	slider_sfx.value = GVar.sfx_volume
	
	slider_music.value_changed.connect(_on_music_changed)
	slider_sfx.value_changed.connect(_on_sfx_changed)
	
	# 4. Generate Color Buttons
	_refresh_color_grid()

# --- REFRESHER (Called by Root after loading a new Set Profile) ---

func refresh_all_ui() -> void:
	_setup_sets_list()
	_setup_checkboxes()
	_refresh_color_grid()

func _refresh_color_grid() -> void:
	for child in color_grid.get_children():
		child.queue_free()
	
	var keys = COLOR_PALETTE.keys()
	for i in range(keys.size()):
		_create_color_button(keys[i], COLOR_PALETTE[keys[i]], i)

# --- NEW HELPER: CREDIT CALCULATION (THE SOURCE OF TRUTH) ---

func _calculate_total_achievement_credits() -> int:
	var total_cr = 0
	var path = "res://resources/csv/menu/achievement.csv"
	
	if not FileAccess.file_exists(path):
		return 0
		
	var file = FileAccess.open(path, FileAccess.READ)
	file.get_csv_line() # Skip header
	
	var ach_values = {}
	while not file.eof_reached():
		var line = file.get_csv_line()
		if line.size() >= 2:
			var title = line[0].strip_edges()
			var desc = line[1]
			var credits = 0
			var split_desc = desc.split("(")
			if split_desc.size() > 1:
				credits = split_desc[split_desc.size() - 1].to_int()
			ach_values[title] = credits
	file.close()
	
	for unlocked_title in GVar.unlocked_achievements:
		if ach_values.has(unlocked_title):
			total_cr += ach_values[unlocked_title]
			
	return total_cr

# --- LOCK LOGIC: SETS ---

func _setup_sets_list() -> void:
	if GVar.active_set < 1 or GVar.active_set > 6:
		GVar.active_set = 1

	var current_credits = _calculate_total_achievement_credits()

	for i in range(set_buttons.size()):
		var btn: Button = set_buttons[i]
		if not btn: continue
		
		var set_num = i + 1
		var is_unlocked = _is_set_unlocked(set_num, current_credits)
		
		if not btn.pressed.is_connected(_on_set_selected):
			btn.pressed.connect(_on_set_selected.bind(set_num))
		
		if is_unlocked:
			btn.disabled = false
			if set_num == GVar.active_set:
				btn.modulate = Color.YELLOW
				btn.text = "Set " + str(set_num) + " (Active)"
			else:
				btn.modulate = Color.WHITE
				btn.text = "Set " + str(set_num)
		else:
			btn.disabled = true
			if set_num == 2 or set_num == 3:
				btn.text = "Set " + str(set_num) + " (Buy in Shop)"
			elif set_num == 4:
				btn.text = "Set " + str(set_num) + " (Reach Intermediate)"
			elif set_num == 5:
				btn.text = "Set " + str(set_num) + " (Reach Expert)"
			elif set_num == 6:
				btn.text = "Set " + str(set_num) + " (Reach Master)"
			btn.modulate = Color(0.4, 0.4, 0.4) 

func _is_set_unlocked(set_num: int, credits: int) -> bool:
	if set_num == 1: 
		return true 
	if set_num == 2 or set_num == 3:
		return GVar.shop_unlocks.has("SET_" + str(set_num))
	match set_num:
		4: return credits >= 1200 # Intermediate
		5: return credits >= 2000 # Expert
		6: return credits >= 2600 # Master
	return false

func _on_set_selected(set_num: int) -> void:
	# Inform the Root script to handle the data migration!
	emit_signal("set_change_requested", set_num)

# --- LOCK LOGIC: CHECKBOXES ---

func _setup_checkboxes() -> void:
	# Use set_pressed_no_signal so it doesn't trigger UI updates when loading
	chk_curved.set_pressed_no_signal(GVar.curved_borders)
	chk_shadow.set_pressed_no_signal(GVar.ui_shadow)
	chk_invert.set_pressed_no_signal(GVar.invert_ui_color)
	
	if GVar.shop_unlocks.has("UI_Curved"):
		chk_curved.disabled = false
		chk_curved.text = "Curved Borders"
	else:
		chk_curved.disabled = true
		chk_curved.text = "Curved Borders (Locked)"

	if GVar.shop_unlocks.has("UI_Shadow"):
		chk_shadow.disabled = false
		chk_shadow.text = "UI Shadow"
	else:
		chk_shadow.disabled = true
		chk_shadow.text = "UI Shadow (Locked)"

	if GVar.shop_unlocks.has("UI_Invert"):
		chk_invert.disabled = false
		chk_invert.text = "Invert UI Color"
	else:
		chk_invert.disabled = true
		chk_invert.text = "Invert UI Color (Locked)"

# --- LOCK LOGIC: COLORS ---

func _create_color_button(c_name: String, c_value: Color, color_index: int) -> void:
	var is_unlocked = (c_name == "Classic") or GVar.shop_unlocks.has("CLR_" + c_name)
	
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(100, 120)
	btn.name = c_name
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE, 5)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vbox)
	
	var rect = ColorRect.new()
	rect.color = c_value if is_unlocked else Color(0.1, 0.1, 0.1) 
	rect.custom_minimum_size = Vector2(0, 80)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(rect)
	
	var lbl = Label.new()
	lbl.name = "Label"
	lbl.text = c_name if is_unlocked else "Locked"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(lbl)
	
	if is_unlocked:
		# INTEGERS TO THE RESCUE: Check the integer ID against GVar
		if GVar.ui_color == color_index:
			lbl.add_theme_color_override("font_color", Color.YELLOW)
			current_selected_label = lbl
			
		# Pass the INTEGER index to the interaction function!
		btn.pressed.connect(_on_color_selected.bind(color_index, c_value, lbl))
	else:
		btn.disabled = true 
		lbl.add_theme_color_override("font_color", Color.GRAY)
		
	color_grid.add_child(btn)

# --- Interactions ---

func _on_color_selected(color_index: int, color: Color, label: Label) -> void:
	if current_selected_label and is_instance_valid(current_selected_label):
		current_selected_label.remove_theme_color_override("font_color")
	
	label.add_theme_color_override("font_color", Color.YELLOW)
	current_selected_label = label
	
	# Save the INTEGER to GVar
	GVar.ui_color = color_index
	
	ThemeEngine.current_background_color = color
	ThemeEngine.refresh_theme(color)

func _on_curved_toggled(toggled_on: bool) -> void:
	GVar.curved_borders = toggled_on
	ThemeEngine.use_curves = toggled_on
	ThemeEngine.refresh_theme(ThemeEngine.current_background_color)

func _on_shadow_toggled(toggled_on: bool) -> void:
	GVar.ui_shadow = toggled_on
	ThemeEngine.use_shadows = toggled_on
	ThemeEngine.refresh_theme(ThemeEngine.current_background_color)

func _on_invert_toggled(toggled_on: bool) -> void:
	GVar.invert_ui_color = toggled_on
	ThemeEngine.use_light_mode = toggled_on
	ThemeEngine.refresh_theme(ThemeEngine.current_background_color)

# --- Audio Interactions ---

func _on_music_changed(value: float) -> void:
	GVar.music_volume = value
	var bus_idx = AudioServer.get_bus_index("Music")
	if bus_idx != -1:
		AudioServer.set_bus_mute(bus_idx, value <= 0.001)
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))

func _on_sfx_changed(value: float) -> void:
	GVar.sfx_volume = value
	var bus_idx = AudioServer.get_bus_index("SFX")
	if bus_idx != -1:
		AudioServer.set_bus_mute(bus_idx, value <= 0.001)
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
