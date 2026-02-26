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

# Master list for saving
const MATKUL_NAMES = [
	"Manajemen Proyek Perangkat Lunak", "Jaringan Komputer", 
	"Keamanan Siber", "Pemrograman Web 1", "Mobile Programming", 
	"Metodologi Riset", "Computer Vision", "Pengolahan Citra Digital"
]

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
	var time_val = GVar.quiz_time_taken
	
	if total > 0:
		score_pct = (float(correct) / float(total)) * 100.0
		
	# --- NEW: THE INTEGRITY CHECK ---
	var answered_count = 0
	for entry in GVar.quiz_history:
		if entry["user_ans_text"] != "No Answer":
			answered_count += 1
			
	var is_fully_completed = (answered_count == total)
	# --------------------------------
	
	# 2. Display Labels
	lbl_right_wrong.text = "Right: %d | Wrong: %d" % [correct, wrong]
	lbl_score.text = "%.2f%%" % score_pct
	
	var mins = int(time_val) / 60
	var secs = int(time_val) % 60
	
	# If stopwatch is disabled, show a dash or N/A to indicate time wasn't tracked
	if GVar.quiz_allow_stopwatch:
		lbl_best_time.text = "Time: %02d:%02d" % [mins, secs]
	else:
		lbl_best_time.text = "Time: --:--"
	
	# 3. Dynamic Grading Scale
	var avg_time = 999.0
	if total > 0: avg_time = time_val / float(total)
	
	var grade = "E"
	var comment = ""
	var multiplier = 1.0 # For calculating point payouts
	
	if score_pct >= 100.0:
		if avg_time <= 3.0 and GVar.quiz_allow_stopwatch: # S-Rank requires time tracking!
			grade = "S"; multiplier = 2.5; comment = "PERFECT & FAST! Godlike!"
			lbl_grade.modulate = Color.GOLD
			Audio.play_sfx("res://audio/sfx/congratulations.wav")
		else:
			grade = "A+"; multiplier = 2.0; comment = "Perfect score! Outstanding!"
			lbl_grade.modulate = Color.CYAN
			Audio.play_sfx("res://audio/sfx/win.wav")
	elif score_pct >= 90.0:
		grade = "A"; multiplier = 1.7; comment = "Excellent work!"
		lbl_grade.modulate = Color.GREEN
		Audio.play_sfx("res://audio/sfx/win.wav")
	elif score_pct >= 80.0:
		grade = "A-"; multiplier = 1.5; comment = "Great job!"
		lbl_grade.modulate = Color.GREEN
		Audio.play_sfx("res://audio/sfx/win.wav")
	elif score_pct >= 75.0:
		grade = "B+"; multiplier = 1.3; comment = "Very good!"
		lbl_grade.modulate = Color.YELLOW
		Audio.play_sfx("res://audio/sfx/win.wav")
	elif score_pct >= 70.0:
		grade = "B"; multiplier = 1.1; comment = "Good job, keep studying."
		lbl_grade.modulate = Color.YELLOW
		Audio.play_sfx("res://audio/sfx/win.wav")
	elif score_pct >= 65.0:
		grade = "B-"; multiplier = 1.0; comment = "Not bad, but room to grow."
		lbl_grade.modulate = Color.YELLOW
		Audio.play_sfx("res://audio/sfx/fail.wav")
	elif score_pct >= 50.0:
		grade = "C"; multiplier = 0.8; comment = "You passed, but barely."
		lbl_grade.modulate = Color.ORANGE
		Audio.play_sfx("res://audio/sfx/fail.wav")
	elif score_pct >= 20.0:
		grade = "D"; multiplier = 0.5; comment = "Below average. Study more."
		lbl_grade.modulate = Color.RED
		Audio.play_sfx("res://audio/sfx/fail.wav")
	elif score_pct > 0.0:
		grade = "E"; multiplier = 0.2; comment = "Failed. Try again."
		lbl_grade.modulate = Color.RED
		Audio.play_sfx("res://audio/sfx/fail.wav")
	else:
		# THE ZERO PERCENT ZONE
		if is_fully_completed:
			grade = "Ɐ"; multiplier = 6.7; comment = "Absolute Inverse Perfection!"
			lbl_grade.modulate = Color.PURPLE
			Audio.play_sfx("res://audio/sfx/congratulations_reverse.wav")
		else:
			grade = "F"; multiplier = 0.0; comment = "Incomplete. No points awarded."
			lbl_grade.modulate = Color.RED
			Audio.play_sfx("res://audio/sfx/fail.wav")
		
	lbl_grade.text = grade
	lbl_comment.text = comment
	
	# 4. Display Question List (If practice/normal mode)
	if question_list:
		question_list.populate_list(GVar.quiz_history)

	# 5. Calculate Points and Save to Disk
	var payout = int(200 * multiplier)
	_save_progress(score_pct, time_val, payout)

# --- THE SAVE ENGINE ---

func _save_progress(score_pct: float, time_val: float, payout: int) -> void:
	# THE GAUNTLET: If matkul is -1, it's Debug Mode. DO NOT SAVE.
	if GVar.current_matkul == -1:
		print("SYSTEM: Debug Mode detected. Progress not saved.")
		return

	# 1. Update Global Player Statistics
	GVar.current_points += payout
	# Only add playtime if stopwatch is allowed to prevent skewing stats with untimed idling
	if GVar.quiz_allow_stopwatch:
		GVar.player_statistics["total_playtime"] += time_val
		
	GVar.player_statistics["total_game_played"] += 1
	GVar.player_statistics["total_correct_answers"] += GVar.quiz_correct_count
	GVar.player_statistics["total_wrong_answers"] += (GVar.quiz_total_questions - GVar.quiz_correct_count)
	
	# 2. Map the specific module path
	var course_name = MATKUL_NAMES[GVar.current_matkul]
	var session_str = "Elearning" if GVar.current_quiz_mode == 1 else "Quizizz"
	
	var set_name = "Set " + str(GVar.current_course + 1)
	if GVar.current_mode == 2: set_name = "Midtest"
	elif GVar.current_mode == 3: set_name = "Final Test"
	elif GVar.current_mode == 4: set_name = "All in One"
	
	# 3. High Score Checking
	var stats = GVar.course_stats[course_name][session_str][set_name]
	var old_score_raw = stats["grade"]
	var old_time = stats["time"]
	
	# --- INTEGRITY CHECK FOR SENTINEL VALUE ---
	var answered_count = 0
	for entry in GVar.quiz_history:
		if entry["user_ans_text"] != "No Answer":
			answered_count += 1
	var is_fully_completed = (answered_count == GVar.quiz_total_questions)
	
	# Determine if this session is an 'Official' Ɐ attempt
	var is_inverse_mastery = (score_pct == 0.0 and is_fully_completed)
	
	var is_new_record = false
	
	# If never played, it's automatically a new record
	if str(old_score_raw) == "Locked" or str(old_score_raw) == "Unplayed":
		is_new_record = true
	else:
		# Compare numeric scores. 
		# Note: We treat -1.0 as a 'special' score that beats a regular 0.0
		var old_numeric = float(old_score_raw)
		
		if is_inverse_mastery and old_numeric >= 0.0: 
			# Upgrading from a normal fail to an Inverse Perfection
			is_new_record = true
		elif score_pct > old_numeric:
			is_new_record = true
		# Tiebreaker ONLY counts if stopwatch is allowed
		elif score_pct == old_numeric and GVar.quiz_allow_stopwatch and time_val < old_time:
			is_new_record = true
			
	# 4. Overwrite and Unlock Next Level
	if is_new_record:
		# Save the magic number -1.0 if it's a Ɐ, otherwise save the float
		stats["grade"] = -1.0 if is_inverse_mastery else score_pct
		
		# Only overwrite the time record if the stopwatch was legally running
		if GVar.quiz_allow_stopwatch:
			stats["time"] = time_val
		
		# Auto-Unlock the next set if they passed (50%+)
		if GVar.current_mode == 0 and score_pct >= 50.0:
			var next_set = "Set " + str(GVar.current_course + 2)
			if GVar.course_stats[course_name][session_str].has(next_set):
				if GVar.course_stats[course_name][session_str][next_set]["grade"] == "Locked":
					GVar.course_stats[course_name][session_str][next_set]["grade"] = "Unplayed"
					print("SYSTEM: Unlocked " + next_set)

	# 5. Force the physical save file to update immediately
	SaveManager.save_game()
	print("SYSTEM: Progress successfully saved.")
	
	# 6. --- TRIGGER GLOBAL ACHIEVEMENT CHECK ---
	AchievementManager.evaluate_all()

# --- INTERACTIONS ---

func _on_retry_pressed() -> void:
	Load.load_res(["res://scenes/quiz/quiz_main.tscn"], "res://scenes/quiz/quiz_main.tscn")

func _on_menu_pressed() -> void:
	# Reset the variables to -1 to ensure we fall back into Debug Mode safely!
	GVar.current_matkul = -1
	GVar.current_course = -1
	
	if GVar.last_scene != "":
		Load.load_res([GVar.last_scene], GVar.last_scene)
	else:
		Load.load_res(["res://scenes/main/main_menu/main_menu.tscn"], "res://scenes/main/main_menu/main_menu.tscn")
