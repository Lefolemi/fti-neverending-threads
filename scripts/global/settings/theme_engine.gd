extends Node

# --- Configuration State ---
var active_theme: Theme
var current_background_color: Color = Color("2b2b2b")
var use_curves: bool = true
var use_shadows: bool = true
var use_light_mode: bool = false

func _ready():
	# Initial build
	refresh_theme(current_background_color)

func refresh_theme(base_color: Color):
	current_background_color = base_color
	active_theme = Theme.new()
	
	# 1. INVERT LOGIC: If light mode is on, we flip the color before building styles
	var actual_color = base_color.inverted() if use_light_mode else base_color
	
	# Generate Styles using actual_color instead of base_color
	var panel_style = _create_panel_style(actual_color)
	var btn_normal = _create_button_style(actual_color, "normal")
	var btn_hover = _create_button_style(actual_color, "hover")
	var btn_pressed = _create_button_style(actual_color, "pressed")
	
	# Inject into Theme Resource
	active_theme.set_stylebox("panel", "PanelContainer", panel_style)
	active_theme.set_stylebox("normal", "Button", btn_normal)
	active_theme.set_stylebox("hover", "Button", btn_hover)
	active_theme.set_stylebox("pressed", "Button", btn_pressed)
	active_theme.set_stylebox("focus", "Button", StyleBoxEmpty.new()) 
	
	# 2. BRUTE FORCE FONT COLORS
	# Because all base colors are dark, if use_light_mode is true, we know the bg is light.
	var font_color = Color("1a1a1a") if use_light_mode else Color.WHITE
	var shadow_color = Color(1, 1, 1, 0.4) if use_light_mode else Color(0, 0, 0, 0.5)
	
	# Label
	active_theme.set_color("font_color", "Label", font_color)
	active_theme.set_color("font_shadow_color", "Label", shadow_color)
	
	# RichTextLabel (Needs 'default_color' instead of 'font_color')
	active_theme.set_color("default_color", "RichTextLabel", font_color)
	active_theme.set_color("font_shadow_color", "RichTextLabel", shadow_color)
	
	# Button (Overwriting all states so it doesn't flash white when hovered)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		active_theme.set_color(state, "Button", font_color)
	
	# 3. APPLY TO THE WHOLE GAME
	get_tree().root.theme = active_theme

# --- THE GENERATOR LOGIC ---

func _create_panel_style(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	
	# Fix: Use the helper function instead of the property
	style.set_corner_radius_all(20 if use_curves else 0)
	
	if use_shadows:
		style.shadow_color = Color(0, 0, 0, 0.4)
		style.shadow_size = 12
		style.shadow_offset = Vector2(4, 4)
	else:
		style.shadow_size = 0
	
	# Fix: Use the helper function here too
	style.set_border_width_all(2)
	style.border_color = color.lightened(0.1)
	return style

func _create_button_style(color: Color, state: String) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	
	match state:
		"normal":
			style.bg_color = color.darkened(0.1)
		"hover":
			style.bg_color = color.lightened(0.1)
		"pressed":
			style.bg_color = color.darkened(0.3)
	
	# Updated: Respect the Curves flag (smaller radius for buttons)
	style.set_corner_radius_all(8 if use_curves else 0)
	
	# 3D clickable effect
	style.border_width_bottom = 4
	style.border_color = color.darkened(0.4)
	
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	
	return style
