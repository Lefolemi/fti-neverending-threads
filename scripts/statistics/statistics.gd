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

# New OptionButton References
@onready var opt_time_course: OptionButton = $Content/TimeScroll/VBox/Course
@onready var opt_courses_course: OptionButton = $Content/CoursesScroll/VBox/Course

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

var dummy_overview = {
	"Total Playtime": "42h 15m",
	"Total Games Played": "1,205",
	"Total Questions Answered": "15,400",
	"Current Rank": "Magistra",
	"Total Points Earned": "85,400 Pts"
}

var dummy_performance = {
	"Total Correct": "13,200",
	"Total Wrong": "2,200",
	"Overall Accuracy": "85.7%",
	"Longest Win Streak": "42",
	"Average Time Per Question": "4.2s"
}

func _ready() -> void:
	# 1. Connect Tab Buttons
	btn_overview.pressed.connect(_on_tab_pressed.bind("overview"))
	btn_performance.pressed.connect(_on_tab_pressed.bind("performance"))
	btn_time.pressed.connect(_on_tab_pressed.bind("time"))
	btn_courses.pressed.connect(_on_tab_pressed.bind("courses"))
	
	btn_close.pressed.connect(_on_close_pressed)
	
	# 2. Setup the OptionButtons dynamically
	_setup_course_dropdowns()
	
	# 3. Generate the initial UI lists
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
func _setup_course_dropdowns() -> void:
	opt_time_course.clear()
	opt_courses_course.clear()
	
	for course_name in COURSE_LIST:
		opt_time_course.add_item(course_name)
		opt_courses_course.add_item(course_name)
		
	opt_time_course.item_selected.connect(_on_time_course_selected)
	opt_courses_course.item_selected.connect(_on_grade_course_selected)

func _on_time_course_selected(index: int) -> void:
	_populate_single_course(vbox_time, index, true)

func _on_grade_course_selected(index: int) -> void:
	_populate_single_course(vbox_courses, index, false)

# --- UI Generation ---
func _generate_all_lists() -> void:
	_populate_simple_vbox(vbox_overview, dummy_overview)
	_populate_simple_vbox(vbox_performance, dummy_performance)
	
	# Generate the default selected course (Index 0)
	_populate_single_course(vbox_time, 0, true)
	_populate_single_course(vbox_courses, 0, false)

func _populate_simple_vbox(vbox: VBoxContainer, data: Dictionary) -> void:
	for child in vbox.get_children():
		child.queue_free()
		
	for key in data.keys():
		vbox.add_child(_create_stat_row(key, data[key]))
		var separator = HSeparator.new()
		separator.add_theme_constant_override("separation", 10)
		vbox.add_child(separator)

# Refactored: Only populates ONE course based on the dropdown index
func _populate_single_course(vbox: VBoxContainer, course_index: int, is_time_format: bool) -> void:
	# 1. Clear everything EXCEPT the "Course" OptionButton
	for child in vbox.get_children():
		if child.name != "Course":
			child.queue_free()
			
	# Optional: Give Godot a tiny moment to process the queue_free before adding new nodes
	await get_tree().process_frame 
	
	# 2. Add the 14 Sets for the selected course
	for i in range(1, 15):
		var title = "Set " + str(i)
		var val = _get_dummy_time() if is_time_format else _get_dummy_grade()
		vbox.add_child(_create_stat_row(title, val))
		
	# 3. Add Midtest and Final Test
	var separator = HSeparator.new()
	separator.add_theme_constant_override("separation", 15)
	vbox.add_child(separator)
	
	var mid_val = _get_dummy_time(true) if is_time_format else _get_dummy_grade()
	var fin_val = _get_dummy_time(true) if is_time_format else _get_dummy_grade()
	vbox.add_child(_create_stat_row("Midtest (UTS)", mid_val))
	vbox.add_child(_create_stat_row("Final Test (UAS)", fin_val))

# --- The Universal Stat Row Builder ---
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
	
	if value.begins_with("S ") or value.begins_with("A "):
		lbl_value.add_theme_color_override("font_color", Color.GREEN)
	elif value.begins_with("C ") or value.begins_with("D "):
		lbl_value.add_theme_color_override("font_color", Color.ORANGE)
	elif value.ends_with("s"): 
		lbl_value.add_theme_color_override("font_color", Color.YELLOW)
	else:
		lbl_value.add_theme_color_override("font_color", Color.WHITE)
		
	hbox.add_child(lbl_value)
	return hbox

# --- Dummy Data Helpers ---
func _get_dummy_grade() -> String:
	var grades = ["S (100/100)", "A (90/100)", "B (80/100)", "C (70/100)", "Locked"]
	return grades[randi() % grades.size()]

func _get_dummy_time(is_test: bool = false) -> String:
	if is_test:
		return str(randi_range(5, 15)) + "m " + str(randi_range(10, 59)) + "s"
	return str(randi_range(0, 2)) + "m " + str(randi_range(10, 59)) + "s"

# --- Interactions ---
func _on_close_pressed() -> void:
	if GVar.last_scene != "":
		Load.load_res([GVar.last_scene], GVar.last_scene)
	else:
		push_warning("GVar.last_scene is empty!")
