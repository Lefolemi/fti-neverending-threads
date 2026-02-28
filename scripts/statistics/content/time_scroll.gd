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
	# Clear existing rows (but keep the "Option" dropdown container safe!)
	for child in vbox.get_children():
		if child.name != "Option":
			child.queue_free()
			
	# Give Godot a frame to safely delete the old nodes
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
	header.text = "--- " + mode_str.to_upper() + " STATS ---"
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
			
			# Since this is the Time script, we only care about time formatting
			if str(raw_grade) == "Locked": 
				val_str = "Locked"
			elif str(raw_grade) == "Unplayed": 
				val_str = "--"
			else: 
				val_str = _format_time_short(raw_time)
				
		vbox.add_child(_create_stat_row(key, val_str))

# --- Formatting Helpers (Isolated to this script) ---

func _format_time_short(time_sec: float) -> String:
	if time_sec <= 0.0: return "--"
	var mins = int(time_sec) / 60
	var secs = int(time_sec) % 60
	return "%dm %02ds" % [mins, secs]

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
	if value.ends_with("s") or value.ends_with("m"): 
		base_color = Color.YELLOW
	elif value == "Locked":
		base_color = Color.DIM_GRAY
		
	# Apply dynamic harmony
	lbl_value.add_theme_color_override("font_color", GConst.get_dynamic_text_color(base_color))
		
	hbox.add_child(lbl_value)
	return hbox
