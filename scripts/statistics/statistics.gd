extends GridContainer

# --- Node References ---
@onready var btn_overview: Button = $Menu/Overview
@onready var btn_performance: Button = $Menu/Performance
@onready var btn_time: Button = $Menu/Time
@onready var btn_courses: Button = $Menu/Courses

@onready var scroll_overview: ScrollContainer = $Content/OverviewScroll
@onready var scroll_performance: ScrollContainer = $Content/PerformanceScroll
@onready var scroll_time: ScrollContainer = $Content/TimeScroll
@onready var scroll_courses: ScrollContainer = $Content/CoursesScroll

@onready var vbox_overview: VBoxContainer = $Content/OverviewScroll/VBox
@onready var vbox_performance: VBoxContainer = $Content/PerformanceScroll/VBox
@onready var vbox_time: VBoxContainer = $Content/TimeScroll/VBox
@onready var vbox_courses: VBoxContainer = $Content/CoursesScroll/VBox

# OptionButton References inside the "Option" container
@onready var opt_time_course: OptionButton = $Content/TimeScroll/VBox/Option/Course
@onready var opt_time_mode: OptionButton = $Content/TimeScroll/VBox/Option/SessionMode
@onready var opt_courses_course: OptionButton = $Content/CoursesScroll/VBox/Option/Course
@onready var opt_courses_mode: OptionButton = $Content/CoursesScroll/VBox/Option/SessionMode

@onready var btn_close: Button = $Confirm/Close

# --- Data Arrays ---
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
	# 1. Connect Tab Buttons
	btn_overview.pressed.connect(_on_tab_pressed.bind("overview"))
	btn_performance.pressed.connect(_on_tab_pressed.bind("performance"))
	btn_time.pressed.connect(_on_tab_pressed.bind("time"))
	btn_courses.pressed.connect(_on_tab_pressed.bind("courses"))
	
	btn_close.pressed.connect(_on_close_pressed)
	
	# 2. Setup the OptionButtons dynamically
	_setup_dropdowns()
	
	# 3. Generate the actual UI lists from GVar
	_generate_all_lists()
	
	# 4. Open default tab
	_on_tab_pressed("overview")

# --- Tab Navigation Logic ---
func _on_tab_pressed(tab_name: String) -> void:
	scroll_overview.hide()
	scroll_performance.hide()
	scroll_time.hide()
	scroll_courses.hide()
	
	btn_overview.modulate = Color(0.5, 0.5, 0.5)
	btn_performance.modulate = Color(0.5, 0.5, 0.5)
	btn_time.modulate = Color(0.5, 0.5, 0.5)
	btn_courses.modulate = Color(0.5, 0.5, 0.5)
	
	match tab_name:
		"overview":
			scroll_overview.show()
			btn_overview.modulate = Color.WHITE
		"performance":
			scroll_performance.show()
			btn_performance.modulate = Color.WHITE
		"time":
			scroll_time.show()
			btn_time.modulate = Color.WHITE
		"courses":
			scroll_courses.show()
			btn_courses.modulate = Color.WHITE

# --- Dropdown Setup & Signals ---
func _setup_dropdowns() -> void:
	opt_time_course.clear()
	opt_courses_course.clear()
	opt_time_mode.clear()
	opt_courses_mode.clear()
	
	for course_name in COURSE_LIST:
		opt_time_course.add_item(course_name)
		opt_courses_course.add_item(course_name)
		
	var modes = ["Quizizz Mode", "Elearning Mode"]
	for m in modes:
		opt_time_mode.add_item(m)
		opt_courses_mode.add_item(m)
		
	opt_time_course.item_selected.connect(_on_time_filter_changed)
	opt_time_mode.item_selected.connect(_on_time_filter_changed)
	opt_courses_course.item_selected.connect(_on_courses_filter_changed)
	opt_courses_mode.item_selected.connect(_on_courses_filter_changed)

func _on_time_filter_changed(_ignore_index: int) -> void:
	_populate_single_course(vbox_time, opt_time_course.selected, opt_time_mode.selected, true)

func _on_courses_filter_changed(_ignore_index: int) -> void:
	_populate_single_course(vbox_courses, opt_courses_course.selected, opt_courses_mode.selected, false)

# --- TRUE DATA GENERATION ---

func _generate_all_lists() -> void:
	var p_stats = GVar.player_statistics
	var correct = p_stats["total_correct_answers"]
	var wrong = p_stats["total_wrong_answers"]
	var total_q = correct + wrong
	var playtime = p_stats["total_playtime"]
	
	# Calculate Dynamic Accuracies and Averages
	var accuracy = 0.0
	if total_q > 0: accuracy = (float(correct) / float(total_q)) * 100.0
	
	var avg_time = 0.0
	if total_q > 0: avg_time = playtime / float(total_q)
	
	var real_overview = {
		"Total Playtime": _format_time_long(playtime),
		"Total Games Played": str(p_stats["total_game_played"]),
		"Total Questions Answered": str(total_q),
		"Current Rank": _get_rank_title(GVar.current_points),
		"Total Points Earned": str(GVar.current_points) + " Pts"
	}

	var real_performance = {
		"Total Correct": str(correct),
		"Total Wrong": str(wrong),
		"Overall Accuracy": "%.1f%%" % accuracy,
		"Longest Win Streak": str(p_stats["longest_correct_streak"]),
		"Avg Time Per Question": "%.1fs" % avg_time
	}
	
	_populate_simple_vbox(vbox_overview, real_overview)
	_populate_simple_vbox(vbox_performance, real_performance)
	
	_populate_single_course(vbox_time, 0, 0, true)
	_populate_single_course(vbox_courses, 0, 0, false)

func _populate_simple_vbox(vbox: VBoxContainer, data: Dictionary) -> void:
	for child in vbox.get_children():
		child.queue_free()
		
	for key in data.keys():
		vbox.add_child(_create_stat_row(key, data[key]))
		var separator = HSeparator.new()
		separator.add_theme_constant_override("separation", 10)
		vbox.add_child(separator)

func _populate_single_course(vbox: VBoxContainer, course_index: int, mode_index: int, is_time_format: bool) -> void:
	for child in vbox.get_children():
		if child.name != "Option":
			child.queue_free()
			
	await get_tree().process_frame 
	
	# Fetch Real Data Segment
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
			
			var q_count = 15
			if key == "Midtest": q_count = 50
			elif key == "Final Test": q_count = 60
			elif key == "All in One": q_count = 100
			
			if is_time_format:
				if str(raw_grade) == "Locked": val_str = "Locked"
				elif str(raw_grade) == "Unplayed": val_str = "--"
				else: val_str = _format_time_short(raw_time)
			else:
				val_str = _get_real_grade(raw_grade, q_count, raw_time)
				
		vbox.add_child(_create_stat_row(key, val_str))

# --- Formatting Helpers ---

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

func _get_rank_title(points: int) -> String:
	if points >= 2818: return "Magistra"
	if points >= 2600: return "Master"
	if points >= 2000: return "Expert"
	if points >= 1200: return "Intermediate"
	if points >= 500: return "Novice"
	if points >= 150: return "Amateur"
	return "Unranked"

func _format_time_long(time_sec: float) -> String:
	var hrs = int(time_sec) / 3600
	var mins = (int(time_sec) % 3600) / 60
	if hrs > 0: return "%dh %dm" % [hrs, mins]
	return "%dm" % mins

func _format_time_short(time_sec: float) -> String:
	if time_sec <= 0.0: return "--"
	var mins = int(time_sec) / 60
	var secs = int(time_sec) % 60
	return "%dm %02ds" % [mins, secs]

# --- Colorization ---

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
	
	# Contextual Coloring
	if value.begins_with("S ") or value.begins_with("A"):
		lbl_value.add_theme_color_override("font_color", Color.GREEN)
	elif value.begins_with("C ") or value.begins_with("D "):
		lbl_value.add_theme_color_override("font_color", Color.ORANGE)
	elif value.begins_with("E ") or value.begins_with("F "):
		lbl_value.add_theme_color_override("font_color", Color.RED)
	elif value.begins_with("Ɐ"):
		lbl_value.add_theme_color_override("font_color", Color.PURPLE)
	elif value.ends_with("s") or value.ends_with("m"): 
		lbl_value.add_theme_color_override("font_color", Color.YELLOW)
	else:
		lbl_value.add_theme_color_override("font_color", Color.WHITE)
		
	hbox.add_child(lbl_value)
	return hbox

# --- Interactions ---
func _on_close_pressed() -> void:
	if GVar.last_scene != "":
		Load.load_res([GVar.last_scene], GVar.last_scene)
	else:
		Load.load_res(["res://scenes/main/main_menu/main_menu.tscn"], "res://scenes/main/main_menu/main_menu.tscn")
