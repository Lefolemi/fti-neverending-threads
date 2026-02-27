extends Node

# --- Configuration State ---
var active_theme: Theme
var current_background_color: Color = Color("2b2b2b")
var use_curves: bool = true
var use_shadows: bool = true
var use_light_mode: bool = false

func _ready():
	refresh_theme(current_background_color)

func refresh_theme(base_color: Color):
	current_background_color = base_color
	active_theme = Theme.new()
	
	var actual_color = base_color.inverted() if use_light_mode else base_color
	
	# Generate Base Styles
	var panel_style = _create_panel_style(actual_color)
	var btn_normal = _create_button_style(actual_color, "normal")
	var btn_hover = _create_button_style(actual_color, "hover")
	var btn_pressed = _create_button_style(actual_color, "pressed")
	var empty_style = StyleBoxEmpty.new()
	
	# --- PANELS & LINEEDIT ---
	active_theme.set_stylebox("panel", "PanelContainer", panel_style)
	active_theme.set_stylebox("panel", "PopupPanel", panel_style)
	
	var line_edit_style = panel_style.duplicate()
	line_edit_style.content_margin_left = 10
	line_edit_style.bg_color = actual_color.darkened(0.2) if not use_light_mode else actual_color.darkened(0.05)
	active_theme.set_stylebox("normal", "LineEdit", line_edit_style)
	active_theme.set_stylebox("focus", "LineEdit", line_edit_style)
	active_theme.set_stylebox("read_only", "LineEdit", line_edit_style)
	
	# --- BUTTONS & INTERACTABLES ---
	var btn_types = ["Button", "CheckBox", "ColorPickerButton", "OptionButton"]
	for type in btn_types:
		active_theme.set_stylebox("normal", type, btn_normal)
		active_theme.set_stylebox("hover", type, btn_hover)
		active_theme.set_stylebox("pressed", type, btn_pressed)
		active_theme.set_stylebox("focus", type, empty_style) 
	
	# --- SCROLLBARS (Thin & Dark) ---
	var scroll_bg = StyleBoxFlat.new()
	scroll_bg.bg_color = Color(0, 0, 0, 0.2) # Very subtle track
	scroll_bg.set_corner_radius_all(10 if use_curves else 0)
	
	var scroll_grabber = StyleBoxFlat.new()
	scroll_grabber.bg_color = actual_color.darkened(0.4) if not use_light_mode else actual_color.darkened(0.2)
	scroll_grabber.set_corner_radius_all(10 if use_curves else 0)
	
	# Logic to make them "Thinner" via margins
	var v_grabber = scroll_grabber.duplicate()
	v_grabber.content_margin_left = 4 # Pushes the width inward
	v_grabber.content_margin_right = 4
	
	var h_grabber = scroll_grabber.duplicate()
	h_grabber.content_margin_top = 4 # Pushes the height inward
	h_grabber.content_margin_bottom = 4

	active_theme.set_stylebox("scroll", "VScrollBar", scroll_bg)
	active_theme.set_stylebox("grabber", "VScrollBar", v_grabber)
	active_theme.set_stylebox("grabber_highlight", "VScrollBar", v_grabber)
	active_theme.set_stylebox("grabber_pressed", "VScrollBar", v_grabber)
	
	active_theme.set_stylebox("scroll", "HScrollBar", scroll_bg)
	active_theme.set_stylebox("grabber", "HScrollBar", h_grabber)
	active_theme.set_stylebox("grabber_highlight", "HScrollBar", h_grabber)
	active_theme.set_stylebox("grabber_pressed", "HScrollBar", h_grabber)
	
	# --- PROGRESS BAR ---
	var pb_bg = _create_panel_style(actual_color.darkened(0.2))
	var pb_fill = _create_button_style(actual_color, "hover")
	active_theme.set_stylebox("background", "ProgressBar", pb_bg)
	active_theme.set_stylebox("fill", "ProgressBar", pb_fill)
	
	# --- TREE (TABLES) ---
	var tree_bg = _create_panel_style(actual_color.darkened(0.1) if not use_light_mode else actual_color.lightened(0.05))
	active_theme.set_stylebox("panel", "Tree", tree_bg)
	active_theme.set_stylebox("selected", "Tree", btn_pressed)
	active_theme.set_stylebox("selected_focus", "Tree", btn_pressed)
	active_theme.set_stylebox("cursor", "Tree", btn_hover)
	
	# --- SLIDERS ---
	var slider_bg = StyleBoxFlat.new()
	slider_bg.bg_color = actual_color.darkened(0.3)
	slider_bg.set_corner_radius_all(10 if use_curves else 0)
	slider_bg.content_margin_top = 4
	slider_bg.content_margin_bottom = 4
	
	for slider_type in ["HSlider", "VSlider"]:
		active_theme.set_stylebox("slider", slider_type, slider_bg)
	
	# --- 2. FONT COLORS ---
	var font_color = Color("1a1a1a") if use_light_mode else Color.WHITE
	var shadow_color = Color(1, 1, 1, 0.4) if use_light_mode else Color(0, 0, 0, 0.5)
	
	active_theme.set_color("font_color", "Label", font_color)
	active_theme.set_color("font_color", "LineEdit", font_color)
	active_theme.set_color("font_color", "Tree", font_color)
	active_theme.set_color("title_button_color", "Tree", font_color)
	active_theme.set_color("default_color", "RichTextLabel", font_color)
	
	for type in btn_types:
		for state in ["font_color", "font_hover_color", "font_pressed_color"]:
			active_theme.set_color(state, type, font_color)
	
	get_tree().root.theme = active_theme

func _create_panel_style(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(20 if use_curves else 0)
	if use_shadows:
		style.shadow_color = Color(0, 0, 0, 0.4) if not use_light_mode else Color(0, 0, 0, 0.1)
		style.shadow_size = 12
		style.shadow_offset = Vector2(4, 4)
	style.set_border_width_all(2)
	style.border_color = color.lightened(0.1) if not use_light_mode else color.darkened(0.1)
	return style

func _create_button_style(color: Color, state: String) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	match state:
		"normal": style.bg_color = color.darkened(0.1) if not use_light_mode else color.darkened(0.05)
		"hover": style.bg_color = color.lightened(0.1) if not use_light_mode else color.darkened(0.15)
		"pressed": style.bg_color = color.darkened(0.3) if not use_light_mode else color.darkened(0.25)
	style.set_corner_radius_all(8 if use_curves else 0)
	style.border_width_bottom = 4
	style.border_color = color.darkened(0.4) if not use_light_mode else color.darkened(0.3)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style
