extends ScrollContainer

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
	"Classic": Color("2b2b2b"),   # Default
	"Midnight": Color("121212"),  
	"Ocean": Color("0f2027"),     
	"Pine": Color("1b4332"),      
	"Wine": Color("4a0404"),      
	"Eggplant": Color("311b3d"),  
	"Chocolate": Color("3e2723"), 
	"Rust": Color("8a3324"),      
	"Navy": Color("000033"),      
	"Olive": Color("33691e"),     
	"Charcoal": Color("36454F"),  
	"Indigo": Color("1a0b2e")     
}

func _ready() -> void:
	# 1. Initialize Sets (THIS WAS MISSING!)
	_setup_sets_list()
	
	# 2. Setup Checkboxes & Shop Locks
	_setup_checkboxes()
	
	# 3. Setup Audio Sliders from GVar
	slider_music.value = GVar.music_volume
	slider_sfx.value = GVar.sfx_volume
	
	slider_music.value_changed.connect(_on_music_changed)
	slider_sfx.value_changed.connect(_on_sfx_changed)
	
	# 4. Clean editor junk & Generate Color Buttons
	for child in color_grid.get_children():
		child.queue_free()
	
	for color_name in COLOR_PALETTE.keys():
		_create_color_button(color_name, COLOR_PALETTE[color_name])

# --- LOCK LOGIC: SETS ---

func _setup_sets_list() -> void:
	if GVar.active_set < 1 or GVar.active_set > 6:
		GVar.active_set = 1

	for i in range(set_buttons.size()):
		var btn: Button = set_buttons[i]
		if not btn: continue
		
		var set_num = i + 1
		var is_unlocked = _is_set_unlocked(set_num)
		
		if not btn.pressed.is_connected(_on_set_selected):
			btn.pressed.connect(_on_set_selected.bind(set_num))
		
		if is_unlocked:
			btn.disabled = false
			btn.text = "Set " + str(set_num)
			
			if set_num == GVar.active_set:
				btn.modulate = Color.YELLOW
				btn.text = "Set " + str(set_num) + " (Active)"
			else:
				btn.modulate = Color.WHITE
		else:
			btn.disabled = true
			btn.text = "Set " + str(set_num) + " (Locked)"
			btn.modulate = Color(0.4, 0.4, 0.4) 

func _is_set_unlocked(set_num: int) -> bool:
	if set_num == 1: return true 
	
	if GVar.shop_unlocks.has("SET_" + str(set_num)):
		return true
		
	var ach = GVar.unlocked_achievements
	if set_num == 2 and ach.has("Amateur"): return true
	if set_num == 3 and ach.has("Novice"): return true
	if set_num == 4 and ach.has("Intermediate"): return true
	if set_num == 5 and ach.has("Expert"): return true
	if set_num == 6 and ach.has("Master"): return true
	
	return false

func _on_set_selected(set_num: int) -> void:
	# 1. Update the variable
	GVar.active_set = set_num
	
	# 2. Visually update the Set buttons
	_setup_sets_list()
	
	# 3. Apply the preset logic for this specific set
	_apply_set_preset(set_num)
	
	# 4. Save
	SaveManager.save_game()

# --- PRESET LOGIC ---
func _apply_set_preset(set_num: int) -> void:
	# Define what aesthetic each set represents. 
	# You can change these colors and toggles to match your desired themes!
	var presets = {
		1: {"color": "Classic", "curved": false, "shadow": false, "invert": false},
		2: {"color": "Ocean", "curved": true, "shadow": true, "invert": false},
		3: {"color": "Pine", "curved": true, "shadow": false, "invert": true},
		4: {"color": "Midnight", "curved": false, "shadow": true, "invert": false},
		5: {"color": "Wine", "curved": true, "shadow": true, "invert": false},
		6: {"color": "Indigo", "curved": true, "shadow": true, "invert": true}
	}
	
	var p = presets[set_num]
	
	# 1. Update UI Checkboxes
	chk_curved.button_pressed = p["curved"]
	chk_shadow.button_pressed = p["shadow"]
	chk_invert.button_pressed = p["invert"]
	
	# 2. Update ThemeEngine Memory
	ThemeEngine.use_curves = p["curved"]
	ThemeEngine.use_shadows = p["shadow"]
	ThemeEngine.use_light_mode = p["invert"]
	ThemeEngine.current_background_color = COLOR_PALETTE[p["color"]]
	
	# 3. Manually trigger the Color Button highlight to move
	for child in color_grid.get_children():
		if child.name == p["color"]:
			# Look inside the button for the Label to highlight it
			var lbl = child.get_node_or_null("VBox/Label")
			if lbl:
				# Temporarily disconnect the signal to avoid loops, run logic, reconnect
				_on_color_selected(COLOR_PALETTE[p["color"]], lbl)
				
	# 4. Execute the global visual change
	ThemeEngine.refresh_theme(ThemeEngine.current_background_color)

# --- LOCK LOGIC: CHECKBOXES ---

func _setup_checkboxes() -> void:
	if GVar.shop_unlocks.has("UI_Curved"):
		chk_curved.disabled = false
		chk_curved.button_pressed = ThemeEngine.use_curves
	else:
		chk_curved.disabled = true
		chk_curved.text = "Curved Borders (Locked)"
		chk_curved.button_pressed = false

	if GVar.shop_unlocks.has("UI_Shadow"):
		chk_shadow.disabled = false
		chk_shadow.button_pressed = ThemeEngine.use_shadows
	else:
		chk_shadow.disabled = true
		chk_shadow.text = "UI Shadow (Locked)"
		chk_shadow.button_pressed = false

	if GVar.shop_unlocks.has("UI_Invert"):
		chk_invert.disabled = false
		chk_invert.button_pressed = ThemeEngine.use_light_mode 
	else:
		chk_invert.disabled = true
		chk_invert.text = "Invert UI Color (Locked)"
		chk_invert.button_pressed = false

	chk_curved.toggled.connect(_on_curved_toggled)
	chk_shadow.toggled.connect(_on_shadow_toggled)
	chk_invert.toggled.connect(_on_invert_toggled)

# --- LOCK LOGIC: COLORS ---

func _create_color_button(c_name: String, c_value: Color) -> void:
	var is_unlocked = (c_name == "Classic") or GVar.shop_unlocks.has("CLR_" + c_name)
	
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(100, 120)
	btn.name = c_name
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBox" # Set name to find the label later
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE, 5)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vbox)
	
	var rect = ColorRect.new()
	rect.color = c_value if is_unlocked else Color(0.1, 0.1, 0.1) 
	rect.custom_minimum_size = Vector2(0, 80)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(rect)
	
	var lbl = Label.new()
	lbl.name = "Label" # Set name to find it later
	lbl.text = c_name if is_unlocked else "Locked"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(lbl)
	
	if is_unlocked:
		if c_value.is_equal_approx(ThemeEngine.current_background_color):
			lbl.add_theme_color_override("font_color", Color.YELLOW)
			current_selected_label = lbl
		btn.pressed.connect(_on_color_selected.bind(c_value, lbl))
	else:
		btn.disabled = true 
		lbl.add_theme_color_override("font_color", Color.GRAY)
		
	color_grid.add_child(btn)

# --- Interactions ---

func _on_color_selected(color: Color, label: Label) -> void:
	if current_selected_label and is_instance_valid(current_selected_label):
		current_selected_label.remove_theme_color_override("font_color")
	
	label.add_theme_color_override("font_color", Color.YELLOW)
	current_selected_label = label
	
	ThemeEngine.current_background_color = color
	ThemeEngine.refresh_theme(color)

func _on_curved_toggled(toggled_on: bool) -> void:
	ThemeEngine.use_curves = toggled_on
	ThemeEngine.refresh_theme(ThemeEngine.current_background_color)

func _on_shadow_toggled(toggled_on: bool) -> void:
	ThemeEngine.use_shadows = toggled_on
	ThemeEngine.refresh_theme(ThemeEngine.current_background_color)

func _on_invert_toggled(toggled_on: bool) -> void:
	ThemeEngine.use_light_mode = toggled_on
	ThemeEngine.refresh_theme(ThemeEngine.current_background_color)

# --- Audio Interactions ---

func _on_music_changed(value: float) -> void:
	GVar.music_volume = value
	var bus_idx = AudioServer.get_bus_index("Music")
	
	if bus_idx == -1: return
	
	if value <= 0.001:
		AudioServer.set_bus_mute(bus_idx, true)
	else:
		AudioServer.set_bus_mute(bus_idx, false)
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))

func _on_sfx_changed(value: float) -> void:
	GVar.sfx_volume = value
	var bus_idx = AudioServer.get_bus_index("SFX")
	
	if bus_idx == -1: return
	
	if value <= 0.001:
		AudioServer.set_bus_mute(bus_idx, true)
	else:
		AudioServer.set_bus_mute(bus_idx, false)
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
