extends Control

# --- Setup ---
enum MenuState { MATKUL, MODE, COURSE }
var current_state: int = MenuState.MATKUL

# CACHE: This will store the Course Names like this:
# _course_names_cache[0] = ["Pengantar...", "Manajemen Tata Kelola...", ... ] (14 items)
var _course_names_cache: Array = [] 

# NOTE: These nodes are just Containers now
@onready var matkul_container: ScrollContainer = $MatkulContainer
@onready var mode_container: ScrollContainer = $ModeContainer
@onready var course_container: ScrollContainer = $CourseContainer

@onready var mode_vbox: VBoxContainer = $ModeContainer/VBox
@onready var course_vbox: VBoxContainer = $CourseContainer/VBox

@onready var back_button: Button = $Back

# --- Overlay & Popup References ---
@onready var bg_menu: ColorRect = $BGMenu 
@onready var init_session_menu: Control = $InitSessionMenu
@onready var practice_mode_menu: Control = $PracticeModeMenu

# --- DATA MAPPING ---
const MATKUL_NAMES = [
	"Manajemen Proyek Perangkat Lunak",
	"Jaringan Komputer",
	"Keamanan Siber",
	"Pemrograman Web 1",
	"Mobile Programming",
	"Metodologi Riset",
	"Computer Vision",
	"Pengolahan Citra Digital"
]

func _ready() -> void:
	# 0. Load the CSV Data immediately when game starts
	_load_course_names()
	
	# 1. Connect Button Signals manually
	_connect_container_buttons(matkul_container.get_node("VBox"), _on_matkul_selected)
	_connect_container_buttons(mode_vbox, _on_mode_selected)
	_connect_container_buttons(course_vbox, _on_course_selected)

	# 2. Connect Back button
	back_button.pressed.connect(_on_back_pressed)

	# Listen for the popup closing itself to hide the dark background
	init_session_menu.closed.connect(_on_popup_closed)
	practice_mode_menu.closed.connect(_on_popup_closed)

	# 3. Initialize State (Visuals only)
	_initialize_visuals()
	
	# --- FAILSAFE ACHIEVEMENT CHECK ---
	AchievementManager.evaluate_all()

# --- Helper to connect all buttons in a VBox ---
func _connect_container_buttons(vbox: VBoxContainer, callback: Callable) -> void:
	for child in vbox.get_children():
		if child is Button:
			# FORCE UNLOCK: Just in case they are disabled in the Inspector
			child.disabled = false
			child.modulate = Color.WHITE
			
			# Store original text
			child.set_meta("original_text", child.text)
			
			child.pressed.connect(func(): 
				var idx = _get_index_from_name(child)
				callback.call(idx, child.name)
			)

# --- BULLETPROOF INDEX MATCHER ---
func _get_index_from_name(btn: Button) -> int:
	var text = str(btn.get_meta("original_text")).to_lower()
	
	if "quiz" in text or "normal" in text: return 0
	if "elearn" in text or "practice" in text: return 1
	if "midtest" in text: return 2
	if "final" in text: return 3
	if "all" in text: return 4
	
	var regex = RegEx.new()
	regex.compile("\\d+")
	var result = regex.search(text)
	if result: return int(result.get_string()) - 1
		
	return btn.get_index()

# --- CSV Logic ---

func _load_course_names() -> void:
	var path = "res://resources/csv/matkul/setnamelist.csv"
	if not FileAccess.file_exists(path):
		push_error("CSV file not found: " + path)
		return

	var file = FileAccess.open(path, FileAccess.READ)
	var headers = file.get_csv_line()
	var col_count = headers.size()
	
	_course_names_cache.resize(col_count)
	for i in range(col_count): _course_names_cache[i] = []

	while not file.eof_reached():
		var line = file.get_csv_line()
		if line.size() != col_count: continue
		for i in range(col_count):
			_course_names_cache[i].append(line[i])

func _update_course_buttons(matkul_index: int) -> void:
	if matkul_index < 0 or matkul_index >= _course_names_cache.size(): return
		
	var courses_for_matkul = _course_names_cache[matkul_index]
	
	for i in range(courses_for_matkul.size()):
		var btn_name = "Course" + str(i + 1)
		var btn = course_vbox.get_node_or_null(btn_name)
		
		if btn:
			btn.text = courses_for_matkul[i]
			btn.set_meta("original_text", courses_for_matkul[i])
			# Ensure it stays unlocked when text changes
			btn.disabled = false
			btn.modulate = Color.WHITE

# --- PROGRESSION LOCK LOGIC ---

func _update_course_locks(course_name: String) -> void:
	# Default: Set 1 (index 0) is ALWAYS unlocked.
	var highest_unlocked_index = 0
	
	if GVar.course_stats.has(course_name):
		var q_stats = GVar.course_stats[course_name].get("Quizizz", {})
		var e_stats = GVar.course_stats[course_name].get("Elearning", {})
		
		# Check Sets 1 to 14 to see how far they've passed
		for i in range(1, 15):
			var set_name = "Set " + str(i)
			var q_grade = q_stats.get(set_name, {}).get("grade", "Locked")
			var e_grade = e_stats.get(set_name, {}).get("grade", "Locked")
			
			# If they passed Set `i` in EITHER mode, they unlock Set `i + 1`
			if _is_passed(q_grade) or _is_passed(e_grade):
				highest_unlocked_index = i # i is 1-based, so this maps directly to the next array index!
			else:
				# Stop checking the moment we hit a set they haven't passed
				break
				
	# Apply the locks visually to the Course buttons
	for child in course_vbox.get_children():
		if child is Button:
			var idx = _get_index_from_name(child)
			
			# If the button's index is less than or equal to the highest unlocked index, it's playable
			var is_unlocked = (idx <= highest_unlocked_index)
			
			var original_text = str(child.get_meta("original_text"))
			var locked_text = original_text + " (Locked)"
			
			_apply_lock(child, is_unlocked, locked_text)

func _update_mode_locks(course_name: String) -> void:
	var passed_sets = 0
	var highest_midtest_score = 0.0
	var highest_final_score = 0.0
	
	if GVar.course_stats.has(course_name):
		var q_stats = GVar.course_stats[course_name].get("Quizizz", {})
		var e_stats = GVar.course_stats[course_name].get("Elearning", {})
		
		# 1. Count passed standard sets (1-14)
		for i in range(1, 15):
			var set_name = "Set " + str(i)
			var q_grade = q_stats.get(set_name, {}).get("grade", "Locked")
			var e_grade = e_stats.get(set_name, {}).get("grade", "Locked")
			if _is_passed(q_grade) or _is_passed(e_grade):
				passed_sets += 1
				
		# 2. Check Midtest Scores
		var mid_q = q_stats.get("Midtest", {}).get("grade", "Locked")
		var mid_e = e_stats.get("Midtest", {}).get("grade", "Locked")
		highest_midtest_score = max(_get_numeric_grade(mid_q), _get_numeric_grade(mid_e))
		
		# 3. Check Final Test Scores
		var fin_q = q_stats.get("Final Test", {}).get("grade", "Locked")
		var fin_e = e_stats.get("Final Test", {}).get("grade", "Locked")
		highest_final_score = max(_get_numeric_grade(fin_q), _get_numeric_grade(fin_e))

	# Apply the locks visually to the Mode buttons
	for child in mode_vbox.get_children():
		if child is Button:
			var text = str(child.get_meta("original_text")).to_lower()
			
			if "midtest" in text:
				_apply_lock(child, passed_sets >= 7, "Midtest (Req: 7 Sets Passed)")
			elif "final" in text:
				_apply_lock(child, highest_midtest_score >= 70.0, "Final Test (Req: Midtest 70%)")
			elif "all" in text:
				# --- REWARD LOCK: Requires Final Test 85% AND Novice Rank ---
				var has_novice = GVar.unlocked_achievements.has("Amateur") or \
								 GVar.unlocked_achievements.has("Novice") or \
								 GVar.unlocked_achievements.has("Intermediate") or \
								 GVar.unlocked_achievements.has("Expert") or \
								 GVar.unlocked_achievements.has("Master") or \
								 GVar.unlocked_achievements.has("Magistra")
				
				var requirements_met = (highest_final_score >= 85.0) and has_novice
				
				_apply_lock(child, requirements_met, "All in One (Req: Final 85% & Novice Rank)")
			else:
				# Normal & Practice modes are ALWAYS unlocked
				_apply_lock(child, true, "")

# Helper to safely compare grades (treats -1.0 as 100% so Inverse Perfection unlocks the next tier)
func _get_numeric_grade(grade: Variant) -> float:
	var g_str = str(grade)
	if g_str == "Locked" or g_str == "Unplayed": return 0.0
	var g_float = float(grade)
	if g_float == -1.0: return 100.0 # Treat Ɐ grade as a perfect score for progression
	return g_float

func _apply_lock(btn: Button, is_unlocked: bool, locked_text: String) -> void:
	if is_unlocked:
		btn.disabled = false
		btn.text = btn.get_meta("original_text")
		btn.modulate = Color.WHITE
	else:
		btn.disabled = true
		btn.text = locked_text
		btn.modulate = Color(0.4, 0.4, 0.4) 

func _is_passed(grade: Variant) -> bool:
	var g_str = str(grade)
	if g_str == "Locked" or g_str == "Unplayed": return false
	var g_float = float(grade)
	return g_float >= 50.0 or g_float == -1.0

# --- Signal Receivers (Business Logic) ---

func _on_matkul_selected(index: int, _name: String) -> void:
	GVar.current_matkul = index
	_update_course_buttons(index)
	
	var course_name = MATKUL_NAMES[index]
	
	# --- UPDATE BOTH LOCKS IMMEDIATELY ---
	_update_course_locks(course_name)
	_update_mode_locks(course_name)
	
	_change_menu(matkul_container, mode_container, MenuState.MODE)

func _on_mode_selected(index: int, _name: String) -> void:
	GVar.current_mode = index
	_change_menu(mode_container, course_container, MenuState.COURSE)

func _on_course_selected(index: int, _name: String) -> void:
	GVar.current_course = index
	bg_menu.show()

	if GVar.current_mode == 1:
		practice_mode_menu.show()
	else:
		init_session_menu.setup(index, _course_names_cache)
		init_session_menu.show()

func _on_popup_closed() -> void:
	bg_menu.hide()

func _on_back_pressed() -> void:
	match current_state:
		MenuState.COURSE: _change_menu(course_container, mode_container, MenuState.MODE)
		MenuState.MODE: _change_menu(mode_container, matkul_container, MenuState.MATKUL)

# --- Animation & Transition System ---

func _change_menu(outgoing: Control, incoming: Control, new_state: int) -> void:
	_set_gui_input_disabled(true)
	var tween = create_tween()
	
	tween.set_parallel(true)
	tween.tween_property(outgoing, "modulate:a", 0.0, 0.3)
	if new_state == MenuState.MATKUL: tween.tween_property(back_button, "modulate:a", 0.0, 0.3)
	
	tween.set_parallel(false)
	tween.tween_callback(outgoing.hide)
	if new_state == MenuState.MATKUL: tween.tween_callback(back_button.hide)
	tween.tween_callback(incoming.show)
	
	incoming.modulate.a = 0.0 
	if current_state == MenuState.MATKUL and new_state == MenuState.MODE:
		back_button.show()
		back_button.modulate.a = 0.0

	tween.set_parallel(true)
	tween.tween_property(incoming, "modulate:a", 1.0, 0.3)
	if current_state == MenuState.MATKUL and new_state == MenuState.MODE:
		tween.tween_property(back_button, "modulate:a", 1.0, 0.3)
	
	tween.set_parallel(false)
	tween.tween_callback(func():
		_set_gui_input_disabled(false)
		current_state = new_state
	)

func _initialize_visuals():
	matkul_container.modulate.a = 1.0
	mode_container.modulate.a = 0.0
	course_container.modulate.a = 0.0
	back_button.modulate.a = 0.0

	matkul_container.visible = true
	mode_container.visible = false
	course_container.visible = false
	back_button.visible = false

	bg_menu.hide()
	init_session_menu.hide()
	practice_mode_menu.hide()

func _set_gui_input_disabled(disabled: bool):
	back_button.disabled = disabled
	matkul_container.mouse_filter = Control.MOUSE_FILTER_IGNORE if disabled else Control.MOUSE_FILTER_STOP
	mode_container.mouse_filter = Control.MOUSE_FILTER_IGNORE if disabled else Control.MOUSE_FILTER_STOP
	course_container.mouse_filter = Control.MOUSE_FILTER_IGNORE if disabled else Control.MOUSE_FILTER_STOP
