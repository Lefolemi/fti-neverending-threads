extends ScrollContainer

@onready var color_grid: GridContainer = $Margin/VBox/UIColorGrid
@onready var chk_curved: CheckBox = $Margin/VBox/ThemeOptions/CurvedBorders
@onready var chk_shadow: CheckBox = $Margin/VBox/ThemeOptions/UIShadow
@onready var chk_invert: CheckBox = $Margin/VBox/ThemeOptions/InvertUIColor

# --- NEW: Audio Sliders ---
@onready var slider_music: Slider = $Margin/VBox/MusicSlider
@onready var slider_sfx: Slider = $Margin/VBox/SoundSlider

# Track the currently selected label to reset its color
var current_selected_label: Label = null

# 12 Distinct Dark Colors. Inverting these creates 12 Light Themes.
const COLOR_PALETTE = {
	"Classic": Color("2b2b2b"),   # Dark Gray
	"Midnight": Color("121212"),  # Pitch Dark
	"Ocean": Color("0f2027"),     # Deep Abyss Blue
	"Pine": Color("1b4332"),      # Dark Forest
	"Wine": Color("4a0404"),      # Dark Blood Red
	"Eggplant": Color("311b3d"),  # Dark Violet
	"Chocolate": Color("3e2723"), # Dark Brown
	"Rust": Color("8a3324"),      # Dark Orange/Rust
	"Navy": Color("000033"),      # True Dark Blue
	"Olive": Color("33691e"),     # Dark Yellow-Green
	"Charcoal": Color("36454F"),  # Slate/Blue-Gray
	"Indigo": Color("1a0b2e")     # Deep Purple/Blue
}

func _ready() -> void:
	# 1. Setup Checkboxes
	chk_curved.button_pressed = ThemeEngine.use_curves
	chk_shadow.button_pressed = ThemeEngine.use_shadows
	chk_invert.button_pressed = ThemeEngine.use_light_mode 
	
	# Connect checkbox signals
	chk_curved.toggled.connect(_on_curved_toggled)
	chk_shadow.toggled.connect(_on_shadow_toggled)
	chk_invert.toggled.connect(_on_invert_toggled)
	
	# 2. Setup Audio Sliders from GVar
	# Make sure your GVar has: var music_volume: float = 1.0 and sfx_volume: float = 1.0
	slider_music.value = GVar.music_volume
	slider_sfx.value = GVar.sfx_volume
	
	# Connect slider signals
	slider_music.value_changed.connect(_on_music_changed)
	slider_sfx.value_changed.connect(_on_sfx_changed)
	
	# 3. Clean any editor junk in the grid
	for child in color_grid.get_children():
		child.queue_free()
	
	# 4. Generate the 12 buttons
	for color_name in COLOR_PALETTE.keys():
		_create_color_button(color_name, COLOR_PALETTE[color_name])

func _create_color_button(c_name: String, c_value: Color) -> void:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(100, 120)
	btn.name = c_name
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE, 5)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vbox)
	
	var rect = ColorRect.new()
	rect.color = c_value
	rect.custom_minimum_size = Vector2(0, 80)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(rect)
	
	var lbl = Label.new()
	lbl.text = c_name
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(lbl)
	
	if c_value.is_equal_approx(ThemeEngine.current_background_color):
		lbl.add_theme_color_override("font_color", Color.YELLOW)
		current_selected_label = lbl
	
	btn.pressed.connect(_on_color_selected.bind(c_value, lbl))
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

# --- NEW: Audio Interactions ---

func _on_music_changed(value: float) -> void:
	GVar.music_volume = value
	var bus_idx = AudioServer.get_bus_index("Music")
	
	if bus_idx == -1: return
	
	# value = 1.0 (100%) -> 0 dB (Full original volume)
	# value = 0.5 (50%)  -> -6 dB (Half perceived volume)
	# value = 0.0 (0%)   -> -80 dB (Silent)
	
	if value <= 0.001:
		AudioServer.set_bus_mute(bus_idx, true)
	else:
		AudioServer.set_bus_mute(bus_idx, false)
		# This ensures 1.0 is the ceiling, not a starting point for boosting
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
