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
	
	# Hide elements for the dramatic reveal
	lbl_best_time.modulate.a = 0.0
	lbl_grade.hide()
	lbl_comment.hide()
	question_list.hide()
	btn_retry.hide()
	btn_menu.hide()
	
	lbl_score.text = "0.00%"
	lbl_right_wrong.text = "Right: 0 | Wrong: 0"
	
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
		
	# --- THE INTEGRITY CHECK ---
	var answered_count = 0
	for entry in GVar.quiz_history:
		if entry["user_ans_text"] != "No Answer":
			answered_count += 1
			
	var is_fully_completed = (answered_count == total)
	# --------------------------------
	
	# 2. Setup Time Label
	var mins = int(time_val) / 60
	var secs = int(time_val) % 60
	if GVar.quiz_allow_stopwatch:
		lbl_best_time.text = "Time: %02d:%02d" % [mins, secs]
	else:
		lbl_best_time.text = "Time: --:--"
	
	# 3. Dynamic Grading Scale (Pre-calculate, do NOT show yet!)
	var avg_time = 999.0
	if total > 0: avg_time = time_val / float(total)
	
	var grade = "E"
	var comment = ""
	var multiplier = 1.0
	
	# Variables to hold the visual/audio juice for the reveal
	var target_color = Color.WHITE
	var target_sfx = ""
	
	if score_pct >= 100.0:
		if avg_time <= 3.0 and GVar.quiz_allow_stopwatch:
			grade = "S"; multiplier = 2.5; comment = "PERFECT & FAST! Godlike!"
			target_color = Color.GOLD
			target_sfx = "res://audio/sfx/congratulations.wav"
		else:
			grade = "A+"; multiplier = 2.0; comment = "Perfect score! Outstanding!"
			target_color = Color.CYAN
			target_sfx = "res://audio/sfx/win.wav"
	elif score_pct >= 90.0:
		grade = "A"; multiplier = 1.7; comment = "Excellent work!"
		target_color = Color.GREEN
		target_sfx = "res://audio/sfx/win.wav"
	elif score_pct >= 80.0:
		grade = "A-"; multiplier = 1.5; comment = "Great job!"
		target_color = Color.GREEN
		target_sfx = "res://audio/sfx/win.wav"
	elif score_pct >= 75.0:
		grade = "B+"; multiplier = 1.3; comment = "Very good!"
		target_color = Color.YELLOW
		target_sfx = "res://audio/sfx/win.wav"
	elif score_pct >= 70.0:
		grade = "B"; multiplier = 1.1; comment = "Good job, keep studying."
		target_color = Color.YELLOW
		target_sfx = "res://audio/sfx/win.wav"
	elif score_pct >= 65.0:
		grade = "B-"; multiplier = 1.0; comment = "Not bad, but room to grow."
		target_color = Color.YELLOW
		target_sfx = "res://audio/sfx/fail.wav"
	elif score_pct >= 50.0:
		grade = "C"; multiplier = 0.8; comment = "You passed, but barely."
		target_color = Color.ORANGE
		target_sfx = "res://audio/sfx/fail.wav"
	elif score_pct >= 20.0:
		grade = "D"; multiplier = 0.5; comment = "Below average. Study more."
		target_color = Color.RED
		target_sfx = "res://audio/sfx/fail.wav"
	elif score_pct > 0.0:
		grade = "E"; multiplier = 0.2; comment = "Failed. Try again."
		target_color = Color.RED
		target_sfx = "res://audio/sfx/fail.wav"
	else:
		# THE ZERO PERCENT ZONE
		if is_fully_completed:
			grade = "Ɐ"; multiplier = 6.7; comment = "Absolute Inverse Perfection!"
			target_color = Color.PURPLE
			target_sfx = "res://audio/sfx/congratulations_reverse.wav"
		else:
			grade = "F"; multiplier = 0.0; comment = "Incomplete. No points awarded."
			target_color = Color.RED
			target_sfx = "res://audio/sfx/fail.wav"
		
	# 4. Save Progress (Do this instantly in the background)
	var payout = int(200 * multiplier)
	_save_progress(score_pct, time_val, payout)

	# 5. START THE DRAMATIC REVEAL ANIMATION
	_animate_reveal(correct, wrong, score_pct, grade, comment, target_color, target_sfx)

# --- THE DRAMATIC REVEAL LOGIC ---

func _animate_reveal(total_c: int, total_w: int, pct: float, grade: String, comment: String, color: Color, sfx: String) -> void:
	var tween = create_tween()
	
	# Step 1: Count up the Right/Wrong label over 1 second
	tween.tween_method(func(val: float):
		var cur_c = int(val * total_c)
		var cur_w = int(val * total_w)
		lbl_right_wrong.text = "Right: %d | Wrong: %d" % [cur_c, cur_w]
	, 0.0, 1.0, 1.0)
	
	# Step 2: Fade in the Best Time label
	tween.tween_property(lbl_best_time, "modulate:a", 1.0, 0.4)
	
	# Step 3: Fast-roll the Score Percentage with a smooth slowdown at the end
	tween.tween_method(func(val: float):
		lbl_score.text = "%.2f%%" % val
	, 0.0, pct, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# Step 4: THE SUSPENSE PAUSE
	tween.tween_interval(0.6)
	
	# Step 5: BOOM! Show the Grade & Play the Sound
	tween.tween_callback(_show_final_grade.bind(grade, comment, color, sfx))

func _show_final_grade(grade: String, comment: String, color: Color, sfx: String) -> void:
	lbl_grade.text = grade
	lbl_grade.modulate = color
	lbl_comment.text = comment
	
	lbl_grade.show()
	lbl_comment.show()
	
	# Only play the sound effect NOW
	if sfx != "":
		Audio.play_sfx(sfx)
	
	# Add a physical "pop" bounce to the grade label
	lbl_grade.scale = Vector2(1.5, 1.5)
	var bounce_tween = create_tween()
	bounce_tween.tween_property(lbl_grade, "scale", Vector2(1, 1), 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	# Finally, reveal the question list and the buttons so the player can proceed
	if question_list:
		question_list.populate_list(GVar.quiz_history)
		question_list.show()
	
	btn_retry.show()
	btn_menu.show()


# --- THE SAVE ENGINE ---

func _save_progress(score_pct: float, time_val: float, payout: int) -> void:
	# THE GAUNTLET: If matkul is -1, it's Debug Mode. DO NOT SAVE.
	if GVar.current_matkul == -1:
		print("SYSTEM: Debug Mode detected. Progress not saved.")
		return

	# 1. Update Global Player Statistics
	GVar.current_points += payout
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
	
	var answered_count = 0
	for entry in GVar.quiz_history:
		if entry["user_ans_text"] != "No Answer":
			answered_count += 1
	var is_fully_completed = (answered_count == GVar.quiz_total_questions)
	
	var is_inverse_mastery = (score_pct == 0.0 and is_fully_completed)
	var is_new_record = false
	
	if str(old_score_raw) == "Locked" or str(old_score_raw) == "Unplayed":
		is_new_record = true
	else:
		var old_numeric = float(old_score_raw)
		if is_inverse_mastery and old_numeric >= 0.0: 
			is_new_record = true
		elif score_pct > old_numeric:
			is_new_record = true
		elif score_pct == old_numeric and GVar.quiz_allow_stopwatch and time_val < old_time:
			is_new_record = true
			
	# 4. Overwrite and Unlock Next Level
	if is_new_record:
		stats["grade"] = -1.0 if is_inverse_mastery else score_pct
		if GVar.quiz_allow_stopwatch:
			stats["time"] = time_val
		
		if GVar.current_mode == 0 and score_pct >= 50.0:
			var next_set = "Set " + str(GVar.current_course + 2)
			if GVar.course_stats[course_name][session_str].has(next_set):
				if GVar.course_stats[course_name][session_str][next_set]["grade"] == "Locked":
					GVar.course_stats[course_name][session_str][next_set]["grade"] = "Unplayed"
					print("SYSTEM: Unlocked " + next_set)

	# 5. Force the physical save file to update immediately
	SaveManager.save_game()
	
	# 6. --- TRIGGER GLOBAL ACHIEVEMENT CHECK ---
	AchievementManager.evaluate_all()

# --- INTERACTIONS ---

func _on_retry_pressed() -> void:
	Load.load_res(["res://scenes/quiz/quiz_main.tscn"], "res://scenes/quiz/quiz_main.tscn")

func _on_menu_pressed() -> void:
	GVar.current_matkul = -1
	GVar.current_course = -1
	
	if GVar.last_scene != "":
		Load.load_res([GVar.last_scene], GVar.last_scene)
	else:
		Load.load_res(["res://scenes/main/main_menu/main_menu.tscn"], "res://scenes/main/main_menu/main_menu.tscn")
