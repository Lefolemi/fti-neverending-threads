extends GridContainer

signal closed # Emitted to tell MainMenu to hide BGMenu

# --- UI References ---
@onready var init_matkul_title: Label = $Content/Margin/VBox/MatkulTitle
@onready var init_course_title: Label = $Content/Margin/VBox/CourseSetTitle
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

var _current_course_name: String = ""
var _current_set_name: String = ""

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
	
	# 1. Determine the Master Course Name
	if GVar.current_matkul >= 0 and GVar.current_matkul < matkul_names.size():
		_current_course_name = matkul_names[GVar.current_matkul]
		init_matkul_title.text = _current_course_name
	else:
		_current_course_name = "Unknown Subject"
		init_matkul_title.text = _current_course_name
	
	if GVar.current_matkul >= 0 and GVar.current_matkul < matkul_names.size():
		lbl_matkul.text = matkul_names[GVar.current_matkul]
	
	if GVar.current_matkul >= 0 and GVar.current_matkul < course_names_cache.size():
		var names = course_names_cache[GVar.current_matkul]
		if course_index >= 0 and course_index < names.size():
			lbl_course.text = names[course_index]

	# 2. Sync UI with current Global Variables
	_sync_ui_from_gvar()
	
	# 3. Check Rank-Based Unlocks
	_check_rank_unlocks()

func _check_rank_unlocks() -> void:
	# Calculate actual lifetime achievement credits, NOT the spendable points!
	var total_credits = _calculate_current_credits()
	
	# Amateur Rank requires 150 credits.
	if total_credits >= 150:
		chk_hide_q.show()
		chk_hide_a.show()
	else:
		chk_hide_q.hide()
		chk_hide_a.hide()
		
		# FAILSAFE: Ensure they are turned off if hidden
		chk_hide_q.button_pressed = false
		chk_hide_a.button_pressed = false

# --- Add this helper to the bottom of the script ---

func _calculate_current_credits() -> int:
	var total_cr = 0
	var path = "res://resources/csv/menu/achievement.csv"
	
	if not FileAccess.file_exists(path):
		return 0
		
	var file = FileAccess.open(path, FileAccess.READ)
	file.get_csv_line() # Skip header
	
	while not file.eof_reached():
		var line = file.get_csv_line()
		if line.size() >= 2:
			var title = line[0].strip_edges()
			var desc = line[1]
			
			# Check if title exists in GVar's unlocked list
			if GVar.unlocked_achievements.has(title):
				var split_desc = desc.split("(")
				if split_desc.size() > 1:
					var cr_val = split_desc[split_desc.size() - 1].to_int()
					total_cr += cr_val
	file.close()
	
	return total_cr

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

	# --- 2. ITEM BANKING LOGIC FOR PRACTICE MODE ---
	
	if GVar.current_mode == 0:
		# NORMAL SETS: 30 questions per set pool
		GVar.set_range_from = GVar.current_course * 30
		GVar.set_range_to = GVar.set_range_from + 29
		
	elif GVar.current_mode == 2:
		# MIDTEST (UTS): Covers Sets 1 through 7
		GVar.set_range_from = 0
		GVar.set_range_to = (7 * 30) - 1 
		
	elif GVar.current_mode == 3:
		# FINAL TEST (UAS): Covers Sets 8 through 14
		GVar.set_range_from = 7 * 30 
		GVar.set_range_to = (14 * 30) - 1 
		
	elif GVar.current_mode == 4:
		# ALL IN ONE: The entire course pool!
		GVar.set_range_from = 0
		GVar.set_range_to = (14 * 30) - 1 
		
	# OVERRIDE: 0 means play EVERY question in the defined range
	GVar.quiz_subset_qty = 0

	# 3. Launch
	print("SYSTEM: Practice Settings Applied. Loading full set range...")
	GVar.current_csv = "matkul/course" + str(GVar.current_matkul) + ".csv"
	Load.load_res(["res://scenes/quiz/quiz_main.tscn"], "res://scenes/quiz/quiz_main.tscn")
