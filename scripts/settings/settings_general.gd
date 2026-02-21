extends ScrollContainer

@onready var color_grid: GridContainer = $Margin/Vbox/UIColorGrid
@onready var chk_curved: CheckBox = $Margin/Vbox/ThemeOptions/CurvedBorders
@onready var chk_shadow: CheckBox = $Margin/Vbox/ThemeOptions/UIShadow
@onready var chk_invert: CheckBox = $Margin/Vbox/ThemeOptions/InvertUIColor

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
	# 1. Setup Checkboxes based on current ThemeEngine state
	chk_curved.button_pressed = ThemeEngine.use_curves
	chk_shadow.button_pressed = ThemeEngine.use_shadows
	chk_invert.button_pressed = ThemeEngine.use_light_mode # WE WILL ADD THIS TO ENGINE
	
	# Connect checkbox signals
	chk_curved.toggled.connect(_on_curved_toggled)
	chk_shadow.toggled.connect(_on_shadow_toggled)
	chk_invert.toggled.connect(_on_invert_toggled)
	
	# 2. Clean any editor junk in the grid
	for child in color_grid.get_children():
		child.queue_free()
	
	# 3. Generate the 12 buttons
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
	
	# Automatically highlight the button if it matches the current theme
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
