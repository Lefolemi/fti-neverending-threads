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
	line_edit_style.set_border_width_all(2) # Slightly thinner border for input boxes
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
	
	# --- SCROLLBARS (Fixed Visibility & Thickness) ---
	# Vertical Track (Needs Left/Right thickness)
	var v_scroll_bg = StyleBoxFlat.new()
	v_scroll_bg.bg_color = Color(0, 0, 0, 0.2)
	v_scroll_bg.set_corner_radius_all(10 if use_curves else 0)
	v_scroll_bg.content_margin_left = 8
	v_scroll_bg.content_margin_right = 8
	v_scroll_bg.set_border_width_all(1)
	v_scroll_bg.border_color = actual_color.darkened(0.6)
	
	# Horizontal Track (Needs Top/Bottom thickness)
	var h_scroll_bg = StyleBoxFlat.new()
	h_scroll_bg.bg_color = Color(0, 0, 0, 0.2)
	h_scroll_bg.set_corner_radius_all(10 if use_curves else 0)
	h_scroll_bg.content_margin_top = 8
	h_scroll_bg.content_margin_bottom = 8
	h_scroll_bg.set_border_width_all(1)
	h_scroll_bg.border_color = actual_color.darkened(0.6)
	
	# The Handle (Grabber)
	var scroll_grabber = StyleBoxFlat.new()
	scroll_grabber.bg_color = actual_color.darkened(0.2) if not use_light_mode else actual_color.darkened(0.1)
	scroll_grabber.set_corner_radius_all(10 if use_curves else 0)
	scroll_grabber.set_border_width_all(1)
	scroll_grabber.border_color = actual_color.darkened(0.8)

	active_theme.set_stylebox("scroll", "VScrollBar", v_scroll_bg)
	active_theme.set_stylebox("grabber", "VScrollBar", scroll_grabber)
	active_theme.set_stylebox("grabber_highlight", "VScrollBar", scroll_grabber)
	active_theme.set_stylebox("grabber_pressed", "VScrollBar", scroll_grabber)
	
	active_theme.set_stylebox("scroll", "HScrollBar", h_scroll_bg)
	active_theme.set_stylebox("grabber", "HScrollBar", scroll_grabber)
	active_theme.set_stylebox("grabber_highlight", "HScrollBar", scroll_grabber)
	active_theme.set_stylebox("grabber_pressed", "HScrollBar", scroll_grabber)
	
	# --- PROGRESS BAR ---
	var pb_bg = _create_panel_style(actual_color.darkened(0.2))
	pb_bg.set_border_width_all(2) # Keep progress bar border clean
	var pb_fill = _create_button_style(actual_color, "hover")
	active_theme.set_stylebox("background", "ProgressBar", pb_bg)
	active_theme.set_stylebox("fill", "ProgressBar", pb_fill)
	
	# --- TREE (TABLES) ---
	var tree_bg = _create_panel_style(actual_color.darkened(0.1) if not use_light_mode else actual_color.lightened(0.05))
	active_theme.set_stylebox("panel", "Tree", tree_bg)
	active_theme.set_stylebox("selected", "Tree", btn_pressed)
	active_theme.set_stylebox("selected_focus", "Tree", btn_pressed)
	active_theme.set_stylebox("cursor", "Tree", btn_hover)
	
	# --- SLIDERS (Fixed Fill Area & H/V Thickness) ---
	# Base track (empty part)
	var slider_bg = StyleBoxFlat.new()
	slider_bg.bg_color = actual_color.darkened(0.4)
	slider_bg.set_corner_radius_all(10 if use_curves else 0)
	slider_bg.set_border_width_all(1)
	slider_bg.border_color = actual_color.darkened(0.7)
	
	# Filled track (the part behind the handle)
	var slider_fill = StyleBoxFlat.new()
	slider_fill.bg_color = actual_color.lightened(0.2) if not use_light_mode else actual_color.darkened(0.2)
	slider_fill.set_corner_radius_all(10 if use_curves else 0)
	
	# Duplicate for H and V so we can set proper margins
	var h_slider_bg = slider_bg.duplicate()
	h_slider_bg.content_margin_top = 6
	h_slider_bg.content_margin_bottom = 6
	var h_slider_fill = slider_fill.duplicate()
	h_slider_fill.content_margin_top = 6
	h_slider_fill.content_margin_bottom = 6
	
	var v_slider_bg = slider_bg.duplicate()
	v_slider_bg.content_margin_left = 6
	v_slider_bg.content_margin_right = 6
	var v_slider_fill = slider_fill.duplicate()
	v_slider_fill.content_margin_left = 6
	v_slider_fill.content_margin_right = 6
	
	# Apply to HSlider
	active_theme.set_stylebox("slider", "HSlider", h_slider_bg)
	active_theme.set_stylebox("grabber_area", "HSlider", h_slider_fill)
	active_theme.set_stylebox("grabber_area_highlight", "HSlider", h_slider_fill)

	# Apply to VSlider
	active_theme.set_stylebox("slider", "VSlider", v_slider_bg)
	active_theme.set_stylebox("grabber_area", "VSlider", v_slider_fill)
	active_theme.set_stylebox("grabber_area_highlight", "VSlider", v_slider_fill)
	
	# --- 2. FONT COLORS & OUTLINES ---
	var font_color = Color("1a1a1a") if use_light_mode else Color.WHITE
	# The outline will be a very dark version of the theme color (or light for invert mode)
	var outline_color = actual_color.lightened(0.5) if use_light_mode else actual_color.darkened(0.8)
	var outline_size = 4
	
	active_theme.set_color("font_color", "Label", font_color)
	active_theme.set_color("font_color", "LineEdit", font_color)
	active_theme.set_color("font_color", "Tree", font_color)
	active_theme.set_color("title_button_color", "Tree", font_color)
	active_theme.set_color("default_color", "RichTextLabel", font_color)
	
	# Apply Font Outlines so standalone text never blends into the wallpaper
	var text_nodes = ["Label", "RichTextLabel", "LineEdit", "Tree"]
	for node in text_nodes:
		active_theme.set_color("font_outline_color", node, outline_color)
		active_theme.set_constant("outline_size", node, outline_size)
	
	for type in btn_types:
		for state in ["font_color", "font_hover_color", "font_pressed_color"]:
			active_theme.set_color(state, type, font_color)
		# Buttons get outlines too!
		active_theme.set_color("font_outline_color", type, outline_color)
		active_theme.set_constant("outline_size", type, outline_size)
	
	get_tree().root.theme = active_theme

# --- STYLEBOX BUILDERS ---

func _create_panel_style(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(20 if use_curves else 0)
	
	if use_shadows:
		style.shadow_color = Color(0, 0, 0, 0.4) if not use_light_mode else Color(0, 0, 0, 0.1)
		style.shadow_size = 12
		style.shadow_offset = Vector2(4, 4)
		
	# Thick, dark borders for main containers
	style.set_border_width_all(4)
	style.border_color = color.darkened(0.6) if not use_light_mode else color.darkened(0.3)
	
	return style

func _create_button_style(color: Color, state: String) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	match state:
		"normal": style.bg_color = color.darkened(0.1) if not use_light_mode else color.darkened(0.05)
		"hover": style.bg_color = color.lightened(0.1) if not use_light_mode else color.darkened(0.15)
		"pressed": style.bg_color = color.darkened(0.3) if not use_light_mode else color.darkened(0.25)
		
	style.set_corner_radius_all(8 if use_curves else 0)
	
	# Thin 2px borders on the top and sides, but keep the chunky 4px bottom for that 3D tactile button feel!
	style.set_border_width_all(2)
	style.border_width_bottom = 4
	style.border_color = color.darkened(0.6) if not use_light_mode else color.darkened(0.4)
	
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style
