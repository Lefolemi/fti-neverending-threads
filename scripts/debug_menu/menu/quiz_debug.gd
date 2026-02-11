extends GridContainer

# --- UI References (Inputs) ---
# 1. Main Data
@onready var file_path_line: LineEdit = $Content/Margin/VBox/FilePath/FilePathLine
@onready var from_spin: SpinBox = $Content/Margin/VBox/SetRange/FromSpin
@onready var to_spin: SpinBox = $Content/Margin/VBox/SetRange/ToSpin
@onready var quiz_mode_opt: OptionButton = $Content/Margin/VBox/QuizMode
@onready var timer_spin: SpinBox = $Content/Margin/VBox/SetTimerSpin
@onready var result_mode_opt: OptionButton = $Content/Margin/VBox/ResultMode

# 2. Checkbox Options
@onready var ck_random_set: CheckBox = $Content/Margin/VBox/OptionsGrid/RandomizeSet
@onready var ck_random_words: CheckBox = $Content/Margin/VBox/OptionsGrid/RandomizeWords
@onready var ck_only_marked: CheckBox = $Content/Margin/VBox/OptionsGrid/OnlyShowMarked
@onready var ck_stopwatch: CheckBox = $Content/Margin/VBox/OptionsGrid/AllowStopwatch
@onready var ck_hide_q: CheckBox = $Content/Margin/VBox/OptionsGrid/HideQuestions
@onready var ck_hide_a: CheckBox = $Content/Margin/VBox/OptionsGrid/HideAnswers
@onready var ck_show_num: CheckBox = $Content/Margin/VBox/OptionsGrid/ShowQuestionNumber
@onready var ck_score_count: CheckBox = $Content/Margin/VBox/OptionsGrid/ShowScoreCount

# 3. Buttons
@onready var start_button: Button = $Confirm/Start
@onready var save_button: Button = $Confirm/Save
@onready var cancel_button: Button = $Confirm/Cancel
@onready var file_path_button: Button = $Content/Margin/VBox/FilePath/FilePathButton

func _ready() -> void:
	# Connect Signals
	start_button.pressed.connect(_on_start_pressed)
	save_button.pressed.connect(_on_save_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	file_path_button.pressed.connect(_on_file_path_button_pressed)

# --- Navigation Logic ---
func show_menu(node: String):
	hide()
	var target_menu = owner.get_node(node)
	if target_menu:
		target_menu.show()

func _on_cancel_pressed() -> void:
	show_menu("MenuVBox")

func _on_file_path_button_pressed() -> void:
	show_menu("SelectFile")

func save_info() -> void:
		# 1. Save Basic Info
	GVar.current_csv = file_path_line.text
	GVar.set_range_from = int(from_spin.value)
	GVar.set_range_to = int(to_spin.value)
	GVar.current_quiz_mode = quiz_mode_opt.selected
	GVar.current_quiz_timer = int(timer_spin.value)
	
	# For Result Mode: OptionButton returns an Index (0, 1, 2).
	# Since GVar.quiz_result_mode is a BOOL, we check if it's not the first option.
	# (Assuming Index 0 = Normal/False, Index 1 = Immediate/True)
	GVar.quiz_result_mode = bool(result_mode_opt.selected)

	# 2. Save Boolean Options (Checkboxes)
	GVar.quiz_randomize_set = ck_random_set.button_pressed
	GVar.quiz_randomize_words = ck_random_words.button_pressed
	GVar.quiz_only_show_marked = ck_only_marked.button_pressed
	GVar.quiz_allow_stopwatch = ck_stopwatch.button_pressed
	GVar.quiz_hide_questions = ck_hide_q.button_pressed
	GVar.quiz_hide_answers = ck_hide_a.button_pressed
	GVar.quiz_show_question_number = ck_show_num.button_pressed
	GVar.quiz_score_count = ck_score_count.button_pressed

# --- MAIN LOGIC: Save to GVar ---
func _on_save_pressed() -> void:
	print("Saving Quiz Configuration to GVar...")

	save_info();

	print("Ready to launch Quiz Scene.")

func _on_start_pressed() -> void:
	save_info();

	# 3. Transition (Uncomment when you are ready)
	# Load.load_res(["res://scenes/QuizScene.tscn"], "res://scenes/QuizScene.tscn")
