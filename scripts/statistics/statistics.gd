extends GridContainer # (Or whatever node type your root is)

# --- Content Panels ---
@onready var scroll_overview: ScrollContainer = $Content/OverviewScroll
@onready var scroll_performance: ScrollContainer = $Content/PerformanceScroll
@onready var scroll_time: ScrollContainer = $Content/TimeScroll
@onready var scroll_courses: ScrollContainer = $Content/CoursesScroll

# --- Menu Node ---
@onready var menu_bar = $Menu

func _ready() -> void:
	# 1. Listen to the menu's custom signal
	menu_bar.tab_changed.connect(_on_menu_tab_changed)
	
	# 2. FORCE the UI to start on the Overview tab right as the scene boots
	_on_menu_tab_changed("overview")

func _on_menu_tab_changed(tab_name: String) -> void:
	# This brilliant little trick evaluates to true/false.
	# It shows the one that matches, and hides all the others instantly!
	scroll_overview.visible = (tab_name == "overview")
	scroll_performance.visible = (tab_name == "performance")
	scroll_time.visible = (tab_name == "time")
	scroll_courses.visible = (tab_name == "courses")
