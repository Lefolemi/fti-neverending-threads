extends GridContainer

signal closed # Emitted when Cancel is pressed

@onready var init_matkul_title: Label = $Content/Margin/VBox/MatkulTitle
@onready var init_course_title: Label = $Content/Margin/VBox/CourseSetTitle
@onready var init_grade: Label = $Content/Margin/VBox/Grade
@onready var init_score: Label = $Content/Margin/VBox/Score

@onready var chk_allow_stopwatch: CheckBox = $Content/Margin/VBox/InitContent/AllowStopwatch
@onready var btn_quizizz: Button = $Content/Margin/VBox/InitContent/Buttons/QuizizzMode
@onready var btn_elearning: Button = $Content/Margin/VBox/InitContent/Buttons/ElearningMode

@onready var btn_start: Button = $Confirm/Start
@onready var btn_cancel: Button = $Confirm/Cancel

var _selected_session_type: int = 0 

func _ready() -> void:
	btn_cancel.pressed.connect(_on_cancel_pressed)
	btn_start.pressed.connect(_on_start_pressed)
	btn_quizizz.pressed.connect(_on_session_type_selected.bind(0))
	btn_elearning.pressed.connect(_on_session_type_selected.bind(1))

# Called by MainMenu right before showing this popup
func setup(course_index: int, course_names_cache: Array) -> void:
	var matkul_names = [
		"Manajemen Proyek Perangkat Lunak", 
		"Jaringan Komputer", 
		"Keamanan Siber", 
		"Pemrograman Web 1", 
		"Mobile Programming", 
		"Metodologi Riset", 
		"Computer Vision", 
		"Pengolahan Citra Digital"
	]
	
	if GVar.current_matkul >= 0 and GVar.current_matkul < matkul_names.size():
		init_matkul_title.text = matkul_names[GVar.current_matkul]
	else:
		init_matkul_title.text = "Unknown Subject"

	if GVar.current_mode == 0:
		if GVar.current_matkul >= 0 and GVar.current_matkul < course_names_cache.size():
			var set_names = course_names_cache[GVar.current_matkul]
			if course_index >= 0 and course_index < set_names.size():
				init_course_title.text = set_names[course_index]
			else:
				init_course_title.text = "Set " + str(course_index + 1)
		else:
			init_course_title.text = "Set " + str(course_index + 1)
			
	elif GVar.current_mode == 2:
		init_course_title.text = "Midtest (UTS)"
	elif GVar.current_mode == 3:
		init_course_title.text = "Final Test (UAS)"
	elif GVar.current_mode == 4:
		init_course_title.text = "All in One"

	init_grade.text = "Best Grade: -"
	init_score.text = "Highest Score: 0/0"
	
	_on_session_type_selected(0) 
	if chk_allow_stopwatch: chk_allow_stopwatch.button_pressed = true

func _on_session_type_selected(type_index: int) -> void:
	_selected_session_type = type_index
	if type_index == 0:
		btn_quizizz.modulate = Color.WHITE
		btn_elearning.modulate = Color(0.5, 0.5, 0.5)
	else:
		btn_elearning.modulate = Color.WHITE
		btn_quizizz.modulate = Color(0.5, 0.5, 0.5)

func _on_cancel_pressed() -> void:
	hide()
	closed.emit() # Tell MainMenu to hide the BGMenu

func _on_start_pressed() -> void:
	if chk_allow_stopwatch:
		GVar.quiz_allow_stopwatch = chk_allow_stopwatch.button_pressed
	
	if GVar.current_mode >= 2:
		GVar.current_quiz_mode = 2 
	else:
		GVar.current_quiz_mode = _selected_session_type 

	Load.load_res(["res://scenes/quiz/quiz_main.tscn"], "res://scenes/quiz/quiz_main.tscn")
