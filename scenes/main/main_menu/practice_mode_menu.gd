extends GridContainer

signal closed # Emitted to tell MainMenu to hide BGMenu

# --- UI References ---
@onready var lbl_matkul: Label = $Content/Margin/VBox/MatkulTitle
@onready var lbl_course: Label = $Content/Margin/VBox/CourseSetTitle

@onready var opt_quiz_mode: OptionButton = $Content/Margin/VBox/QuizMode
@onready var spin_timer: SpinBox = $Content/Margin/VBox/SetTimerSpin

# Checkboxes
@onready var chk_randomize: CheckBox = $Content/Margin/VBox/OptionsGrid/RandomizeSet
@onready var chk_marked_only: CheckBox = $Content/Margin/VBox/OptionsGrid/OnlyShowMarked
@onready var chk_hide_q: CheckBox = $Content/Margin/VBox/OptionsGrid/HideQuestions
@onready var chk_hide_a: CheckBox = $Content/Margin/VBox/OptionsGrid/HideAnswers
@onready var chk_show_num: CheckBox = $Content/Margin/VBox/OptionsGrid/ShowQuestionNumber
@onready var chk_show_score: CheckBox = $Content/Margin/VBox/OptionsGrid/ShowScoreCount

# Buttons
@onready var btn_start: Button = $Confirm/Start
@onready var btn_cancel: Button = $Confirm/Cancel

func _ready() -> void:
	# 1. Setup Quiz Mode Options
	opt_quiz_mode.clear()
	opt_quiz_mode.add_item("Quizizz Mode", 0)
	opt_quiz_mode.add_item("E-Learning Mode", 1)
	
	# 2. Connect Signals
	btn_start.pressed.connect(_on_start_pressed)
	btn_cancel.pressed.connect(_on_cancel_pressed)
	
	hide()

# Called by MainMenu right before showing this popup
func setup(course_index: int, course_names_cache: Array) -> void:
	# 1. Set Titles
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
		lbl_matkul.text = matkul_names[GVar.current_matkul]
	
	if GVar.current_matkul >= 0 and GVar.current_matkul < course_names_cache.size():
		var names = course_names_cache[GVar.current_matkul]
		if course_index >= 0 and course_index < names.size():
			lbl_course.text = names[course_index]
	
	# 2. Sync UI with current Global Variables
	_sync_ui_from_gvar()

func _sync_ui_from_gvar() -> void:
	opt_quiz_mode.selected = GVar.current_quiz_mode
	spin_timer.value = GVar.current_quiz_timer
	
	chk_randomize.button_pressed = GVar.quiz_randomize_set
	chk_marked_only.button_pressed = GVar.quiz_only_show_marked
	chk_hide_q.button_pressed = GVar.quiz_hide_questions
	chk_hide_a.button_pressed = GVar.quiz_hide_answers
	chk_show_num.button_pressed = GVar.quiz_show_question_number
	chk_show_score.button_pressed = GVar.quiz_score_count

func _on_cancel_pressed() -> void:
	hide()
	closed.emit() # Tell MainMenu to hide the BGMenu

func _on_start_pressed() -> void:
	# 1. Apply UI values to GVar before switching scenes
	GVar.current_quiz_mode = opt_quiz_mode.selected
	GVar.current_quiz_timer = int(spin_timer.value)

	GVar.quiz_randomize_set = chk_randomize.button_pressed
	GVar.quiz_only_show_marked = chk_marked_only.button_pressed
	GVar.quiz_hide_questions = chk_hide_q.button_pressed
	GVar.quiz_hide_answers = chk_hide_a.button_pressed
	GVar.quiz_show_question_number = chk_show_num.button_pressed
	GVar.quiz_score_count = chk_show_score.button_pressed

	# 2. Launch
	print("Practice Settings Applied. Starting Session...")
	GVar.current_csv = "matkul/course" + str(GVar.current_matkul) + ".csv"
	Load.load_res(["res://scenes/quiz/quiz_main.tscn"], "res://scenes/quiz/quiz_main.tscn")
