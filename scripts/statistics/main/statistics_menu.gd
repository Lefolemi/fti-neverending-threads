extends GridContainer

signal tab_changed(tab_name: String)

@onready var btn_overview: Button = $Overview
@onready var btn_performance: Button = $Performance
@onready var btn_time: Button = $Time
@onready var btn_courses: Button = $Courses

func _ready() -> void:
	# 1. Connect the buttons
	btn_overview.pressed.connect(_on_tab_pressed.bind("overview"))
	btn_performance.pressed.connect(_on_tab_pressed.bind("performance"))
	btn_time.pressed.connect(_on_tab_pressed.bind("time"))
	btn_courses.pressed.connect(_on_tab_pressed.bind("courses"))
	
	# 2. Set default visual state
	_update_button_colors("overview")

func _on_tab_pressed(tab_name: String) -> void:
	_update_button_colors(tab_name)
	# Shout out to the rest of the scene that a tab was clicked
	tab_changed.emit(tab_name)

func _update_button_colors(active_tab: String) -> void:
	# Dim all buttons first
	btn_overview.modulate = Color(0.5, 0.5, 0.5)
	btn_performance.modulate = Color(0.5, 0.5, 0.5)
	btn_time.modulate = Color(0.5, 0.5, 0.5)
	btn_courses.modulate = Color(0.5, 0.5, 0.5)
	
	# Light up the active one
	match active_tab:
		"overview":
			btn_overview.modulate = Color.WHITE
		"performance":
			btn_performance.modulate = Color.WHITE
		"time":
			btn_time.modulate = Color.WHITE
		"courses":
			btn_courses.modulate = Color.WHITE
