extends ScrollContainer

# --- Node References ---
@onready var vbox: VBoxContainer = $VBox
@onready var opt_course: OptionButton = $VBox/Option/Course
@onready var opt_mode: OptionButton = $VBox/Option/SessionMode

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
	_setup_dropdowns()
	_refresh_list()

func _setup_dropdowns() -> void:
	opt_course.clear()
	opt_mode.clear()
	
	for course_name in COURSE_LIST:
		opt_course.add_item(course_name)
		
	var modes = ["Quizizz Mode", "Elearning Mode"]
	for m in modes:
		opt_mode.add_item(m)
		
	opt_course.item_selected.connect(_on_filter_changed)
	opt_mode.item_selected.connect(_on_filter_changed)

func _on_filter_changed(_ignore_index: int) -> void:
	_refresh_list()

func _refresh_list() -> void:
	# Clear existing rows (keep the "Option" dropdown container safe!)
	for child in vbox.get_children():
		if child.name != "Option":
			child.queue_free()
			
	await get_tree().process_frame 
	
	var course_index = opt_course.selected
	var mode_index = opt_mode.selected
	
	var course_name = COURSE_LIST[course_index]
	var mode_str = "Quizizz" if mode_index == 0 else "Elearning"
	var course_data = {}
	
	if GVar.course_stats.has(course_name) and GVar.course_stats[course_name].has(mode_str):
		course_data = GVar.course_stats[course_name][mode_str]
	
	# Visual Header
	var header = Label.new()
	header.text = "--- " + mode_str.to_upper() + " GRADES ---"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_color_override("font_color", Color.AQUA)
	vbox.add_child(header)
	
	# Define Set Order
	var ordered_keys = []
	for i in range(1, 15): ordered_keys.append("Set " + str(i))
	ordered_keys.append("Midtest")
	ordered_keys.append("Final Test")
	ordered_keys.append("All in One")
	
	# Populate Rows
	for key in ordered_keys:
		if key == "Midtest":
			var separator = HSeparator.new()
			separator.add_theme_constant_override("separation", 15)
			vbox.add_child(separator)
			
		var val_str = "Locked"
		if course_data.has(key):
			var raw_grade = course_data[key]["grade"]
			var raw_time = course_data[key]["time"]
			
			var q_count = 15
			if key == "Midtest": q_count = 50
			elif key == "Final Test": q_count = 60
			elif key == "All in One": q_count = 100
			
			val_str = _get_real_grade(raw_grade, q_count, raw_time)
				
		vbox.add_child(_create_stat_row(key, val_str))

# --- Grade Calculation Logic ---

func _get_real_grade(grade_val: Variant, q_count: int, time_val: float) -> String:
	if str(grade_val) == "Locked": return "Locked"
	if str(grade_val) == "Unplayed": return "Unplayed"
	
	var val = float(grade_val)
	
	# Handle specific logic cases
	if val == -1.0: return "Ɐ (0.0%)"
	if val == 0.0: return "F (0.0%)"
	
	var letter = "E"
	if val >= 100.0:
		if time_val > 0 and time_val <= (float(q_count) * 3.0): letter = "S"
		else: letter = "A+"
	elif val >= 90.0: letter = "A"
	elif val >= 80.0: letter = "A-"
	elif val >= 75.0: letter = "B+"
	elif val >= 70.0: letter = "B"
	elif val >= 65.0: letter = "B-"
	elif val >= 50.0: letter = "C"
	elif val >= 20.0: letter = "D"
	
	return "%s (%.1f%%)" % [letter, val]

# --- Formatting Helpers ---

func _create_stat_row(title: String, value: String) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var lbl_title = Label.new()
	lbl_title.text = title
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	hbox.add_child(lbl_title)
	
	var lbl_value = Label.new()
	lbl_value.text = value
	lbl_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	# Determine raw base color
	var base_color = Color.WHITE
	if value.begins_with("S ") or value.begins_with("A"):
		base_color = Color.GREEN
	elif value.begins_with("C ") or value.begins_with("D "):
		base_color = Color.ORANGE
	elif value.begins_with("E ") or value.begins_with("F "):
		base_color = Color.RED
	elif value.begins_with("Ɐ"):
		base_color = Color.PURPLE
	elif value == "Locked":
		base_color = Color.DIM_GRAY
		
	# Apply dynamic harmony
	lbl_value.add_theme_color_override("font_color", GConst.get_dynamic_text_color(base_color))
		
	hbox.add_child(lbl_value)
	return hbox
