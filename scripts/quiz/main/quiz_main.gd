extends Control

# --- UI References ---
@onready var question_label: RichTextLabel = $Question
@onready var page_label: Label = $Page
@onready var timer_label: Label = $TimerLabel
@onready var stopwatch_label: Label = $StopwatchLabel
@onready var right_wrong_label: Label = $RightWrong

# --- COMPONENTS ---
@onready var answer_controller: Control = $Answers
@onready var function_controller: Control = $Function
@onready var utilities_controller: Control = $Utilities

# Popups
@onready var session_settings: Control = $SessionSettings
@onready var jump_menu: GridContainer = $JumpMenu

# --- Data Structure ---
var _question_deck: Array = []
var _current_index: int = 0

# --- State ---
var _quiz_mode: int = 0 
var _timer_val: float = 0.0
var _stopwatch_val: float = 0.0
var _is_quiz_active: bool = false
var _quizizz_answered: bool = false 

var _score_right: int = 0
var _score_wrong: int = 0

func _ready() -> void:
	# 1. Init
	_quiz_mode = GVar.current_quiz_mode
	_load_quiz_data()
	
	# 2. Connect Components
	answer_controller.answer_selected.connect(_on_answer_pressed)
	
	function_controller.next_pressed.connect(_on_nav_pressed.bind(1))
	function_controller.prev_pressed.connect(_on_nav_pressed.bind(-1))
	function_controller.flag_pressed.connect(_on_flag_pressed)
	function_controller.mark_pressed.connect(_on_mark_pressed)
	
	# --- UTILITY CONNECTIONS ---
	utilities_controller.finish_pressed.connect(_on_finish_pressed)
	utilities_controller.restart_pressed.connect(_on_restart_pressed)
	utilities_controller.settings_pressed.connect(_on_session_settings_pressed)
	utilities_controller.jump_pressed.connect(_on_jump_button_pressed)
	
	# 3. Setup UI 
	_setup_ui_mode()
	
	# 4. Start
	if _question_deck.size() > 0:
		_is_quiz_active = true
		_init_timers()
		_load_question_ui(0)
	else:
		question_label.text = "Error: No questions loaded."

func _process(delta: float) -> void:
	if not _is_quiz_active: return
	
	if GVar.quiz_allow_stopwatch:
		_stopwatch_val += delta
		_update_stopwatch_label()
	
	if GVar.current_quiz_timer > 0:
		if _quiz_mode == 0 and _quizizz_answered: return
		
		_timer_val -= delta
		if _timer_val <= 0:
			_timer_val = 0
			_on_timer_finished()
		_update_timer_label()

# --- LOGIC DELEGATION ---

func _load_question_ui(idx: int) -> void:
	_current_index = idx
	var data = _question_deck[idx]
	
	# --- 1. Text Processing (Stable Randomization) ---
	var final_q_text = ""
	
	# Check if we already processed this question in this session
	if data.has("processed_q_text"):
		final_q_text = data["processed_q_text"]
	else:
		# If not, process it now and SAVE it to the dictionary
		var raw_text = data["q_text"].to_lower()
		final_q_text = TextUtils.process_text(raw_text, true)
		data["processed_q_text"] = final_q_text
	
	question_label.text = final_q_text if not GVar.quiz_hide_questions else "???"
	page_label.text = "Q%d / Q%d" % [idx + 1, _question_deck.size()]
	
	if not GVar.quiz_score_count: right_wrong_label.text = "" 
	
	# --- 2. Update Components ---
	# We need to do the same caching for Answers!
	# Since answer_controller handles logic internally, we need to pass the data object
	# and let IT handle the caching, or we pre-process answers here.
	
	# Let's pre-process answers here to keep state management in Main
	if not data.has("processed_options"):
		_preprocess_answers(data)
		
	# Now we pass the DATA object which contains the 'processed_options'
	# We need to update answer_controller.load_buttons to look for this new key
	answer_controller.load_buttons(data, _quiz_mode, GVar.quiz_hide_answers)
	
	function_controller.update_visuals(data["flagged"], data["marked"])
	function_controller.update_nav_state(_current_index, _question_deck.size(), _quiz_mode)
	
	# 3. Timer Logic
	if _quiz_mode == 0 and not data["is_locked"] and GVar.current_quiz_timer > 0:
		_timer_val = float(GVar.current_quiz_timer)
		_quizizz_answered = false

# --- NEW HELPER FUNCTION ---
func _preprocess_answers(data: Dictionary) -> void:
	# Create a duplicate of options to store processed text
	# We don't want to overwrite the original "text" field in case we need it later
	var processed_opts = []
	for opt in data["options"]:
		var new_opt = opt.duplicate()
		var raw = new_opt["text"]
		# Process Spintax only (false for synonyms)
		new_opt["processed_text"] = TextUtils.process_text(raw, false)
		processed_opts.append(new_opt)
	
	data["processed_options"] = processed_opts

func _setup_ui_mode() -> void:
	stopwatch_label.visible = GVar.quiz_allow_stopwatch
	page_label.visible = GVar.quiz_show_question_number
	timer_label.visible = (GVar.current_quiz_timer > 0)
	right_wrong_label.visible = GVar.quiz_score_count
	_update_score_label()
	
	# DELEGATE UTILITY VISIBILITY
	utilities_controller.setup_visibility(GVar.quiz_session_mode, _quiz_mode)

# --- INTERACTION ---

func _on_answer_pressed(btn_idx: int) -> void:
	var data = _question_deck[_current_index]
	
	if _quiz_mode == 0: # QUIZIZZ
		if data["is_locked"]: return
		
		data["user_answer"] = btn_idx
		data["is_locked"] = true
		_quizizz_answered = true
		
		var is_correct = data["options"][btn_idx]["is_correct"]
		if is_correct: _score_right += 1
		else: _score_wrong += 1
		
		_update_score_label()
		right_wrong_label.text = "CORRECT!" if is_correct else "WRONG!"
		right_wrong_label.modulate = Color.GREEN if is_correct else Color.RED
		
		_load_question_ui(_current_index)
		await get_tree().create_timer(2.0).timeout
		_try_go_next()
		
	elif _quiz_mode == 1: # ELEARNING
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

func _on_flag_pressed() -> void:
	var data = _question_deck[_current_index]
	data["flagged"] = !data["flagged"]
	function_controller.update_visuals(data["flagged"], data["marked"])

func _on_mark_pressed() -> void:
	var data = _question_deck[_current_index]
	data["marked"] = !data["marked"]
	function_controller.update_visuals(data["flagged"], data["marked"])
	_update_csv_mark(data["csv_line_index"], data["marked"])

# --- POPUP HANDLERS ---

func _on_restart_pressed() -> void:
	Load.load_res(["res://scenes/quiz/quiz_main.tscn"], "res://scenes/quiz/quiz_main.tscn")

func _on_session_settings_pressed() -> void:
	if session_settings: session_settings.open_menu()

func _on_jump_button_pressed() -> void:
	if jump_menu: jump_menu.open_menu()

# --- DATA & HELPERS ---

func _load_quiz_data() -> void:
	var path = "res://resources/csv/" + GVar.current_csv
	if not FileAccess.file_exists(path): return
	var file = FileAccess.open(path, FileAccess.READ)
	var valid_questions = []; var marked_questions = []
	var header = file.get_csv_line(); var file_line_idx = 1 
	while not file.eof_reached():
		var line = file.get_csv_line()
		if line.size() < 6: 
			file_line_idx += 1; continue 
		var logical_index = file_line_idx - 1
		if logical_index >= GVar.set_range_from and logical_index <= GVar.set_range_to:
			var is_marked = (line[5].strip_edges() == "1")
			var q_obj = { "csv_line_index": file_line_idx, "q_text": line[0], "options": [], "marked": is_marked, "user_answer": -1, "flagged": false, "is_locked": false }
			var raw_opts = [ {"text": line[1], "is_correct": true}, {"text": line[2], "is_correct": false}, {"text": line[3], "is_correct": false}, {"text": line[4], "is_correct": false} ]
			raw_opts.shuffle()
			q_obj["options"] = raw_opts
			valid_questions.append(q_obj)
			if is_marked: marked_questions.append(q_obj)
		file_line_idx += 1
	var target_pool = []
	if GVar.quiz_only_show_marked:
		if marked_questions.size() > 0: target_pool = marked_questions
		else: target_pool = valid_questions
	else: target_pool = valid_questions
	if GVar.quiz_subset_qty > 0 and GVar.quiz_subset_qty < target_pool.size():
		target_pool.shuffle(); _question_deck = target_pool.slice(0, GVar.quiz_subset_qty)
	elif GVar.quiz_randomize_set:
		target_pool.shuffle(); _question_deck = target_pool
	else: _question_deck = target_pool

func _update_csv_mark(line_index: int, new_state: bool) -> void:
	var path = "res://resources/csv/" + GVar.current_csv
	var file_read = FileAccess.open(path, FileAccess.READ)
	if not file_read: return
	var lines = []
	while not file_read.eof_reached():
		var row = file_read.get_csv_line()
		if row.size() > 0: lines.append(row)
	file_read.close()
	if line_index < lines.size() and lines[line_index].size() >= 6:
		lines[line_index][5] = "1" if new_state else "0"
	var file_write = FileAccess.open(path, FileAccess.WRITE)
	for row in lines: file_write.store_csv_line(row)
	file_write.close()

func _on_finish_pressed() -> void:
	_is_quiz_active = false
	var history_data = []
	var final_correct_count = 0
	for q in _question_deck:
		var user_ans_text = "No Answer"
		if q["user_answer"] != -1 and q["user_answer"] < q["options"].size():
			user_ans_text = q["options"][q["user_answer"]]["text"]
		var correct_ans_text = ""
		var is_correct = false
		for opt in q["options"]:
			if opt["is_correct"]:
				correct_ans_text = opt["text"]
				if q["user_answer"] != -1 and q["options"][q["user_answer"]] == opt:
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
	GVar.quiz_total_questions = _question_deck.size()
	GVar.quiz_correct_count = final_correct_count
	GVar.quiz_history = history_data
	GVar.quiz_time_taken = _stopwatch_val
	Load.load_res(["res://scenes/quiz/result_screen.tscn"], "res://scenes/quiz/result_screen.tscn")

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
		if _quiz_mode == 1: right_wrong_label.text = ""

func _init_timers() -> void:
	if GVar.current_quiz_timer > 0:
		if _quiz_mode == 0: _timer_val = float(GVar.current_quiz_timer)
		else: _timer_val = float(GVar.current_quiz_timer) * 60.0
