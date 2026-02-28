extends GridContainer

# --- UI References ---
@onready var timer_label: Label = $TimerLabel
@onready var search_bar: LineEdit = $Content/Margin/VBox/SearchQuestion
@onready var search_status: Label = $Content/Margin/VBox/SearchStatus # Feedback label
@onready var grid_container: GridContainer = $Content/Margin/VBox/Questions/Grid
@onready var cancel_btn: Button = $Confirm/Cancel

# Checkboxes
@onready var chk_flagged: CheckBox = $Content/Margin/VBox/ShowHide/ShowFlagged
@onready var chk_marked: CheckBox = $Content/Margin/VBox/ShowHide/ShowMarked
@onready var chk_done: CheckBox = $Content/Margin/VBox/ShowHide/ShowDone
@onready var chk_not_done: CheckBox = $Content/Margin/VBox/ShowHide/ShowNotDone

@onready var bg_overlay: ColorRect = $"../BGMenu" 

# --- Optimization Tools ---
var _search_timer: Timer = null
var _current_job_id: int = 0 # To cancel old rendering jobs

# --- State ---
var _parent_quiz: Control = null
var _deck_ref: Array = []

func _ready() -> void:
	# 1. Setup Debounce Timer
	_search_timer = Timer.new()
	_search_timer.wait_time = 0.3 # 300ms delay after typing stops
	_search_timer.one_shot = true
	add_child(_search_timer)
	_search_timer.timeout.connect(_on_debounce_timer_timeout)

	# 2. Connect UI Signals
	search_bar.text_changed.connect(_on_search_text_changed)
	
	# Checkboxes trigger update immediately (or you can debounce them too)
	chk_flagged.pressed.connect(_on_filter_ui_changed)
	chk_marked.pressed.connect(_on_filter_ui_changed)
	chk_done.pressed.connect(_on_filter_ui_changed)
	chk_not_done.pressed.connect(_on_filter_ui_changed)
	
	cancel_btn.pressed.connect(close_menu)
	
	# 3. Defaults
	chk_flagged.button_pressed = true
	chk_marked.button_pressed = true
	chk_done.button_pressed = true
	chk_not_done.button_pressed = true
	
	if owner and owner.name == "Quiz":
		_parent_quiz = owner
	
	if bg_overlay:
		bg_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		bg_overlay.hide()
	
	hide()

func _process(_delta: float) -> void:
	if visible and _parent_quiz:
		if _parent_quiz.timer_label:
			timer_label.text = "Time: " + _parent_quiz.timer_label.text

# --- Public API ---

func open_menu() -> void:
	if not _parent_quiz: return
	_deck_ref = _parent_quiz._question_deck
	if bg_overlay: bg_overlay.show()
	show()
	_start_refresh_job()

func close_menu() -> void:
	_current_job_id += 1 # Cancel any active drawing
	hide()
	if bg_overlay: bg_overlay.hide()

# --- Search & Debounce Logic ---

func _on_search_text_changed(_new_text: String) -> void:
	_current_job_id += 1 # Stop current drawing immediately
	search_status.text = "Typing..."
	_search_timer.start()

func _on_filter_ui_changed() -> void:
	_start_refresh_job()

func _on_debounce_timer_timeout() -> void:
	_start_refresh_job()

# --- The Async Engine ---

func _start_refresh_job() -> void:
	_current_job_id += 1
	_render_grid_async(_current_job_id)

func _render_grid_async(job_id: int) -> void:
	# 1. Clear Grid
	for child in grid_container.get_children():
		child.queue_free()
	
	search_status.text = "Searching..."
	
	# 2. Preparation (Filtering)
	var query = search_bar.text.to_lower().strip_edges()
	var buttons_to_create = []
	
	for i in range(_deck_ref.size()):
		var q_data = _deck_ref[i]
		
		# --- Filter Logic ---
		var passes = false
		if chk_flagged.button_pressed and q_data["flagged"]: passes = true
		elif chk_marked.button_pressed and q_data["marked"]: passes = true
		elif chk_done.button_pressed and q_data["user_answer"] != -1: passes = true
		elif chk_not_done.button_pressed and q_data["user_answer"] == -1: passes = true
		
		if passes and query != "":
			var q_num_str = "q" + str(i + 1)
			if not (query in q_data["q_text"].to_lower() or query in q_num_str):
				passes = false
		
		if passes:
			buttons_to_create.append({"idx": i, "data": q_data})

	if buttons_to_create.is_empty():
		search_status.text = "No results found."
		return

	# 3. Chunked Rendering
	var chunk_size = 15 # Buttons per frame
	var processed_count = 0
	
	for item in buttons_to_create:
		# Safety Check: If job_id changed, user typed something else. ABORT!
		if job_id != _current_job_id:
			return
			
		_create_button(item.idx, item.data)
		processed_count += 1
		
		if processed_count >= chunk_size:
			processed_count = 0
			search_status.text = "Loading... (%d/%d)" % [grid_container.get_child_count(), buttons_to_create.size()]
			await get_tree().process_frame

	search_status.text = "Found %d questions." % buttons_to_create.size()

func _create_button(index: int, data: Dictionary) -> void:
	var btn = Button.new()
	btn.mouse_filter = Control.MOUSE_FILTER_PASS
	var snippet = data["q_text"].left(25) + ("..." if data["q_text"].length() > 25 else "")
	btn.text = "Q%d\n%s" % [index + 1, snippet]

	btn.custom_minimum_size = Vector2(100, 60)
	btn.clip_text = true
	
	# Color Coding
	var is_flagged = data["flagged"]
	var is_answered = (data["user_answer"] != -1)
	
	if is_flagged and is_answered:
		btn.modulate = Color(0.6, 0.2, 0.8) # Purple
	elif is_answered:
		btn.modulate = Color(0.2, 0.6, 1.0) # Blue
	elif is_flagged:
		btn.modulate = Color(1.0, 0.3, 0.3) # Red
	
	btn.pressed.connect(_on_jump_pressed.bind(index))
	grid_container.add_child(btn)

func _on_jump_pressed(index: int) -> void:
	if _parent_quiz:
		_parent_quiz._load_question_ui(index)
	close_menu()
