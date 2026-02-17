extends GridContainer

# --- UI References ---
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
@onready var btn_restart: Button = $Confirm/Restart
@onready var btn_cancel: Button = $Confirm/Cancel

# Background Overlay (Optional, consistent with JumpMenu)
@onready var bg_overlay: ColorRect = $"../BGMenu"

func _ready() -> void:
	# 1. Setup Quiz Mode Options
	opt_quiz_mode.clear()
	opt_quiz_mode.add_item("Quizizz Mode", 0)
	opt_quiz_mode.add_item("E-Learning Mode", 1)
	
	# 2. Connect Signals
	btn_restart.pressed.connect(_on_restart_pressed)
	btn_cancel.pressed.connect(close_menu)
	
	# 3. Initialize UI with current GVar values
	_sync_ui_from_gvar()
	
	hide()

func open_menu() -> void:
	_sync_ui_from_gvar()
	if bg_overlay: 
		bg_overlay.show()
		bg_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	show()

func close_menu() -> void:
	if bg_overlay: bg_overlay.hide()
	hide()

# --- Logic ---

func _sync_ui_from_gvar() -> void:
	# Mode
	opt_quiz_mode.selected = GVar.current_quiz_mode
	
	# Timer
	spin_timer.value = GVar.current_quiz_timer
	
	# Booleans
	chk_randomize.button_pressed = GVar.quiz_randomize_set
	chk_marked_only.button_pressed = GVar.quiz_only_show_marked
	chk_hide_q.button_pressed = GVar.quiz_hide_questions
	chk_hide_a.button_pressed = GVar.quiz_hide_answers
	chk_show_num.button_pressed = GVar.quiz_show_question_number
	chk_show_score.button_pressed = GVar.quiz_score_count

func _on_restart_pressed() -> void:
	# 1. Apply UI values to GVar
	GVar.current_quiz_mode = opt_quiz_mode.selected
	GVar.current_quiz_timer = int(spin_timer.value)
	
	GVar.quiz_randomize_set = chk_randomize.button_pressed
	GVar.quiz_only_show_marked = chk_marked_only.button_pressed
	GVar.quiz_hide_questions = chk_hide_q.button_pressed
	GVar.quiz_hide_answers = chk_hide_a.button_pressed
	GVar.quiz_show_question_number = chk_show_num.button_pressed
	GVar.quiz_score_count = chk_show_score.button_pressed
	
	# 2. Reload the Scene
	print("Settings Applied. Restarting Session...")
	
	# Using standard Godot reload. 
	# If you use a custom Load manager, replace this line:
	get_tree().reload_current_scene()
