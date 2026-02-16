extends Control

# --- UI References ---
@onready var question_label: RichTextLabel = $Question
@onready var page_label: Label = $Page
@onready var timer_label: Label = $TimerLabel
@onready var stopwatch_label: Label = $StopwatchLabel
@onready var right_wrong_label: Label = $RightWrong

# Answer Buttons
@onready var answer_container: VBoxContainer = $Answers/VBox
@onready var btn_answers: Array[Button] = [
	$Answers/VBox/Answer1,
	$Answers/VBox/Answer2,
	$Answers/VBox/Answer3,
	$Answers/VBox/Answer4
]

# Navigation & Utilities
@onready var btn_finish: Button = $Utilities/Finish
@onready var btn_reset: Button = $Utilities/Reset
@onready var btn_jump: Button = $Utilities/JumpQuestion 

# Function Buttons
@onready var btn_flag: Button = $Function/Flag
@onready var btn_mark: Button = $Function/Mark
@onready var btn_next: Button = $Function/Next
@onready var btn_prev: Button = $Function/Previous

# Jump Menu
@onready var jump_menu: GridContainer = $JumpMenu

# --- Data Structure ---
var _question_deck: Array = []
var _current_index: int = 0

# --- State ---
var _quiz_mode: int = 0 # 0=Quizizz, 1=Elearning
var _timer_val: float = 0.0
var _stopwatch_val: float = 0.0
var _is_quiz_active: bool = false
var _quizizz_answered: bool = false # Special flag for Mode 0

# Score Tracking
var _score_right: int = 0
var _score_wrong: int = 0

func _ready() -> void:
	# 1. Initialize System
	_quiz_mode = GVar.current_quiz_mode
	_load_quiz_data()
	
	# 2. Setup UI based on Mode
	_setup_ui_mode()
	
	# 3. Connect Buttons
	for i in range(btn_answers.size()):
		btn_answers[i].pressed.connect(_on_answer_pressed.bind(i))
	
	btn_next.pressed.connect(_on_nav_pressed.bind(1))
	btn_prev.pressed.connect(_on_nav_pressed.bind(-1))
	btn_flag.pressed.connect(_on_flag_pressed)
	btn_mark.pressed.connect(_on_mark_pressed)
	btn_finish.pressed.connect(_on_finish_pressed)
	btn_jump.pressed.connect(_on_jump_button_pressed) 
	
	# 4. Start
	if _question_deck.size() > 0:
		_is_quiz_active = true
		_init_timers()
		_load_question_ui(0)
	else:
		question_label.text = "Error: No questions loaded from CSV."

func _process(delta: float) -> void:
	if not _is_quiz_active: return
	
	# Stopwatch (Global)
	if GVar.quiz_allow_stopwatch:
		_stopwatch_val += delta
		_update_stopwatch_label()
	
	# Quiz Timer (Countdown)
	if GVar.current_quiz_timer > 0:
		if _quiz_mode == 0 and _quizizz_answered:
			pass
		else:
			_timer_val -= delta
			if _timer_val <= 0:
				_timer_val = 0
				_on_timer_finished()
			_update_timer_label()

func _on_jump_button_pressed() -> void:
	if jump_menu:
		jump_menu.open_menu()

# --- CORE 1: Data Loading ---
func _load_quiz_data() -> void:
	var path = "res://resources/csv/" + GVar.current_csv
	if not FileAccess.file_exists(path):
		push_error("CSV not found: " + path)
		return

	var file = FileAccess.open(path, FileAccess.READ)
	var valid_questions = [] # Stores all valid questions in range
	var marked_questions = [] # Stores only marked ones
	
	var header = file.get_csv_line() # Skip Header
	var file_line_idx = 1 
	
	while not file.eof_reached():
		var line = file.get_csv_line()
		if line.size() < 6: 
			file_line_idx += 1
			continue 
		
		# Check Range
		var logical_index = file_line_idx - 1
		if logical_index >= GVar.set_range_from and logical_index <= GVar.set_range_to:
			
			var is_marked = (line[5].strip_edges() == "1")
			
			var q_obj = {
				"csv_line_index": file_line_idx, # SAVE THIS ID!
				"q_text": line[0],
				"options": [],
				"marked": is_marked,
				"user_answer": -1,
				"flagged": false,
				"is_locked": false
			}
			
			# Create Options
			var raw_opts = [
				{"text": line[1], "is_correct": true},
				{"text": line[2], "is_correct": false},
				{"text": line[3], "is_correct": false},
				{"text": line[4], "is_correct": false}
			]
			raw_opts.shuffle()
			q_obj["options"] = raw_opts
			
			valid_questions.append(q_obj)
			if is_marked:
				marked_questions.append(q_obj)
		
		file_line_idx += 1
	
	# --- SELECTION LOGIC ---
	var target_pool = []
	
	if GVar.quiz_only_show_marked:
		if marked_questions.size() > 0:
			target_pool = marked_questions
		else:
			print("Display Info: 'Only Marked' was checked, but no questions were marked. Fallback to ALL.")
			target_pool = valid_questions
	else:
		target_pool = valid_questions
		
	# Handle Subset / Shuffle
	if GVar.quiz_subset_qty > 0 and GVar.quiz_subset_qty < target_pool.size():
		target_pool.shuffle()
		_question_deck = target_pool.slice(0, GVar.quiz_subset_qty)
	elif GVar.quiz_randomize_set:
		target_pool.shuffle()
		_question_deck = target_pool
	else:
		_question_deck = target_pool

# --- CORE 2: UI Setup ---
func _setup_ui_mode() -> void:
	# Hide/Show things based on GVar options
	stopwatch_label.visible = GVar.quiz_allow_stopwatch
	page_label.visible = GVar.quiz_show_question_number
	timer_label.visible = (GVar.current_quiz_timer > 0)
	
	# Score Count Visibility
	right_wrong_label.visible = GVar.quiz_score_count
	_update_score_label()
	
	if _quiz_mode == 0: # QUIZIZZ MODE
		btn_prev.visible = false
		btn_flag.visible = false
		btn_jump.visible = false
		btn_next.visible = false 
		
	elif _quiz_mode == 1: # E-LEARNING MODE
		btn_prev.visible = true
		btn_flag.visible = true
		btn_jump.visible = true
		btn_next.visible = true

func _init_timers() -> void:
	if GVar.current_quiz_timer > 0:
		if _quiz_mode == 0:
			_timer_val = float(GVar.current_quiz_timer)
		else:
			_timer_val = float(GVar.current_quiz_timer) * 60.0

# --- CORE 3: Question Loader ---
func _load_question_ui(idx: int) -> void:
	_current_index = idx
	var data = _question_deck[idx]
	
	# 1. Text & Info
	question_label.text = data["q_text"] if not GVar.quiz_hide_questions else "???"
	page_label.text = "Q%d / Q%d" % [idx + 1, _question_deck.size()]
	
	if not GVar.quiz_score_count:
		right_wrong_label.text = "" 
	
	# 2. Options Buttons
	for i in range(4):
		var btn = btn_answers[i]
		# Safety check for range
		if i < data["options"].size():
			var opt_data = data["options"][i]
			
			btn.text = opt_data["text"] if not GVar.quiz_hide_answers else "???"
			btn.disabled = false
			btn.modulate = Color.WHITE
			btn.show()
			
			# VISUAL STATE RESTORATION
			if _quiz_mode == 1: # Elearning
				if data["user_answer"] == i:
					btn.modulate = Color(1, 1, 0)
			
			elif _quiz_mode == 0: # Quizizz
				if data["is_locked"]:
					btn.disabled = true
					if opt_data["is_correct"]:
						btn.modulate = Color.GREEN
					elif data["user_answer"] == i:
						btn.modulate = Color.RED
					
					if data["user_answer"] == -1 and opt_data["is_correct"]:
						btn.modulate = Color.GREEN
		else:
			btn.hide()

	# 3. Nav Buttons State
	_update_nav_buttons()
	
	# 4. Timer Reset (Quizizz Only)
	if _quiz_mode == 0 and not data["is_locked"] and GVar.current_quiz_timer > 0:
		_timer_val = float(GVar.current_quiz_timer)
		_quizizz_answered = false

# --- INTERACTION ---

func _on_answer_pressed(btn_idx: int) -> void:
	var data = _question_deck[_current_index]
	
	if _quiz_mode == 0: # QUIZIZZ logic
		if data["is_locked"]: return
		
		data["user_answer"] = btn_idx
		data["is_locked"] = true
		_quizizz_answered = true
		
		var is_correct = data["options"][btn_idx]["is_correct"]
		
		# Update Score variables
		if is_correct:
			_score_right += 1
		else:
			_score_wrong += 1
		_update_score_label()
		
		# Feedback Text
		right_wrong_label.text = "CORRECT!" if is_correct else "WRONG!"
		right_wrong_label.modulate = Color.GREEN if is_correct else Color.RED
		
		# Update Colors
		_load_question_ui(_current_index)
		
		# Auto-Next Logic
		await get_tree().create_timer(2.0).timeout
		_try_go_next()
		
	elif _quiz_mode == 1: # ELEARNING logic
		data["user_answer"] = btn_idx
		_load_question_ui(_current_index)

func _try_go_next() -> void:
	if _current_index < _question_deck.size() - 1:
		_load_question_ui(_current_index + 1)
	else:
		_on_finish_pressed()

func _on_nav_pressed(direction: int) -> void:
	var new_idx = _current_index + direction
	
	if new_idx >= 0 and new_idx < _question_deck.size():
		_load_question_ui(new_idx)
	else:
		pass

func _on_flag_pressed() -> void:
	var data = _question_deck[_current_index]
	data["flagged"] = !data["flagged"]
	btn_flag.modulate = Color.RED if data["flagged"] else Color.WHITE

func _on_mark_pressed() -> void:
	var data = _question_deck[_current_index]
	data["marked"] = !data["marked"]
	btn_mark.modulate = Color.YELLOW if data["marked"] else Color.WHITE
	_update_csv_mark(data["csv_line_index"], data["marked"])

func _update_csv_mark(line_index: int, new_state: bool) -> void:
	var path = "res://resources/csv/" + GVar.current_csv
	var file_read = FileAccess.open(path, FileAccess.READ)
	if not file_read: return
		
	var lines = []
	while not file_read.eof_reached():
		var csv_row = file_read.get_csv_line()
		if csv_row.size() > 0: lines.append(csv_row)
	file_read.close()
	
	if line_index < lines.size():
		var target_row = lines[line_index]
		if target_row.size() >= 6:
			target_row[5] = "1" if new_state else "0"
			lines[line_index] = target_row
	
	var file_write = FileAccess.open(path, FileAccess.WRITE)
	for row in lines:
		file_write.store_csv_line(row)
	file_write.close()

# --- FINISH & RESULTS (UPDATED) ---

func _on_finish_pressed() -> void:
	_is_quiz_active = false
	print("Quiz Finished! Calculating Results...")
	
	# 1. Build History Data for GVar
	var history_data = []
	var final_correct_count = 0
	
	for q in _question_deck:
		var user_ans_text = "No Answer"
		if q["user_answer"] != -1:
			if q["user_answer"] < q["options"].size():
				user_ans_text = q["options"][q["user_answer"]]["text"]
			
		var correct_ans_text = ""
		var is_correct = false
		
		# Find correct option
		for opt in q["options"]:
			if opt["is_correct"]:
				correct_ans_text = opt["text"]
				if q["user_answer"] != -1:
					if q["options"][q["user_answer"]] == opt:
						is_correct = true
		
		if is_correct: final_correct_count += 1
		
		history_data.append({
			"q_text": q["q_text"],
			"user_ans_text": user_ans_text,
			"correct_ans_text": correct_ans_text,
			"is_correct": is_correct,
			"csv_line_index": q["csv_line_index"],
			"marked": q["marked"]
		})

	# 2. Populate GLOBAL VARIABLES
	GVar.quiz_total_questions = _question_deck.size()
	GVar.quiz_correct_count = final_correct_count
	GVar.quiz_history = history_data
	
	# Time Taken Logic
	if GVar.quiz_allow_stopwatch:
		GVar.quiz_time_taken = _stopwatch_val
	else:
		GVar.quiz_time_taken = _stopwatch_val # Simplified

	# 3. Transition to Result Screen
	Load.load_res(["res://scenes/quiz/result_screen.tscn"], "res://scenes/quiz/result_screen.tscn")

# --- TIMERS ---

func _on_timer_finished() -> void:
	if _quiz_mode == 0:
		if not _quizizz_answered:
			var data = _question_deck[_current_index]
			data["is_locked"] = true
			data["user_answer"] = -1 
			_quizizz_answered = true
			
			_score_wrong += 1
			_update_score_label()
			
			right_wrong_label.text = "TIME UP!"
			right_wrong_label.modulate = Color.RED
			
			_load_question_ui(_current_index)
			await get_tree().create_timer(2.0).timeout
			_try_go_next()
	else:
		_on_finish_pressed()

func _update_timer_label() -> void:
	var mins = int(_timer_val) / 60
	var secs = int(_timer_val) % 60
	timer_label.text = "%02d:%02d" % [mins, secs]

func _update_stopwatch_label() -> void:
	var total_sec = int(_stopwatch_val)
	var hrs = total_sec / 3600
	var mins = (total_sec % 3600) / 60
	var secs = total_sec % 60
	stopwatch_label.text = "Current time: %02d:%02d:%02d" % [hrs, mins, secs]

func _update_score_label() -> void:
	if GVar.quiz_score_count:
		right_wrong_label.text = "Right: %d || Wrong: %d" % [_score_right, _score_wrong]
	else:
		if _quiz_mode == 1: 
			right_wrong_label.text = ""

func _update_nav_buttons() -> void:
	var data = _question_deck[_current_index]
	btn_mark.modulate = Color.YELLOW if data["marked"] else Color.WHITE
	btn_flag.modulate = Color.RED if data["flagged"] else Color.WHITE

	if _quiz_mode == 1:
		btn_prev.disabled = (_current_index == 0)
		btn_next.disabled = (_current_index == _question_deck.size() - 1)
