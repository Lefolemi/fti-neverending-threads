extends Control

# --- UI References ---
@onready var lbl_right_wrong: Label = $RightWrong
@onready var lbl_score: Label = $Score
@onready var lbl_best_time: Label = $BestTime
@onready var lbl_grade: Label = $Grade
@onready var lbl_comment: Label = $Comment

@onready var question_list: ScrollContainer = $QuestionList
@onready var btn_retry: Button = $Retry
@onready var btn_menu: Button = $BackToMenu

func _ready() -> void:
	btn_retry.pressed.connect(_on_retry_pressed)
	btn_menu.pressed.connect(_on_menu_pressed)
	
	_calculate_results()

func _calculate_results() -> void:
	# 1. Basic Stats (Directly from GVar)
	var total = GVar.quiz_total_questions
	var correct = GVar.quiz_correct_count
	var wrong = total - correct
	var score_pct = 0.0
	
	if total > 0:
		score_pct = (float(correct) / float(total)) * 100.0
	
	# 2. Display Labels
	lbl_right_wrong.text = "Right: %d | Wrong: %d" % [correct, wrong]
	lbl_score.text = "%.2f%%" % score_pct
	
	# Time Display
	var time_val = GVar.quiz_time_taken
	var mins = int(time_val) / 60
	var secs = int(time_val) % 60
	lbl_best_time.text = "Time: %02d:%02d" % [mins, secs]
	
	# 3. Grading Logic
	var grade = "F"
	var comment = ""
	var mode = GVar.quiz_session_mode # 0=Normal, 2=Exam
	
	if mode == 2: # EXAM MODE
		# Hide the Review List!
		question_list.visible = false
		
		# Exam Pass Logic (Strict 85%)
		if score_pct >= 85.0:
			grade = "PASS"
			lbl_grade.modulate = Color.GREEN
			comment = "Congratulations! You have passed the exam."
		else:
			grade = "FAIL"
			lbl_grade.modulate = Color.RED
			comment = "You failed. You need 85% to pass."
			
	else: # NORMAL / QUIZIZZ / ELEARNING
		question_list.visible = true
		
		if score_pct >= 100.0:
			# Check for S Rank (Fast Time)
			# Placeholder: < 5 seconds per question avg
			var avg_time = 999.0
			if total > 0: avg_time = time_val / float(total)
			
			if avg_time < 5.0: # 5 seconds per question threshold
				grade = "S"
				lbl_grade.modulate = Color.GOLD
				comment = "PERFECT & FAST! Godlike!"
			else:
				grade = "A+"
				lbl_grade.modulate = Color.CYAN
				comment = "Perfect score! Outstanding!"
				
		elif score_pct >= 85.0:
			grade = "A"
			lbl_grade.modulate = Color.GREEN
			comment = "Excellent work!"
		elif score_pct >= 70.0:
			grade = "B"
			lbl_grade.modulate = Color.YELLOW
			comment = "Good job, keep studying."
		elif score_pct >= 50.0:
			grade = "C"
			lbl_grade.modulate = Color.ORANGE
			comment = "You passed, but barely."
		else:
			grade = "F"
			lbl_grade.modulate = Color.RED
			comment = "Study more and try again."
	
	lbl_grade.text = grade
	lbl_comment.text = comment
	
	# 4. Populate Review List (Only if visible)
	if question_list.visible:
		# The list script handles the population using GVar.quiz_history
		question_list.populate_list(GVar.quiz_history)

func _on_retry_pressed() -> void:
	# Reload the Quiz Scene
	# The GVar settings are still the same, so it restarts the same setup
	Load.load_res(["res://scenes/quiz/quiz_main.tscn"], "res://scenes/quiz/quiz_main.tscn")

func _on_menu_pressed() -> void:
	if GVar.last_scene != "":
		Load.load_res([GVar.last_scene], GVar.last_scene)
	else:
		# Fallback to Debug Menu if lost
		Load.load_res(["res://scenes/main/main_menu/main_menu.tscn"], "res://scenes/main/main_menu/main_menu.tscn")
