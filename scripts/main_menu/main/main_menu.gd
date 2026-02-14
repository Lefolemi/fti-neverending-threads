extends Control

# --- Setup ---
enum MenuState { MATKUL, MODE, COURSE }
var current_state: int = MenuState.MATKUL

# CACHE: This will store the Course Names like this:
# _course_names_cache[0] = ["Pengantar...", "Manajemen Tata Kelola...", ... ] (14 items)
# _course_names_cache[1] = ["Dasar Jaringan...", "Karakteristik...", ... ]
var _course_names_cache: Array = [] 

# NOTE: These nodes now have the "MenuPage" script attached!
@onready var matkul_container: MenuPage = $MatkulContainer
@onready var mode_container: MenuPage = $ModeContainer
@onready var course_container: MenuPage = $CourseContainer

@onready var back_button: Button = $Back

func _ready() -> void:
	# 0. Load the CSV Data immediately when game starts
	_load_course_names()

	# 1. Connect to the CONTAINER signal, not the buttons directly
	matkul_container.item_selected.connect(_on_matkul_selected)
	mode_container.item_selected.connect(_on_mode_selected)
	course_container.item_selected.connect(_on_course_selected)
	
	# 2. Connect Back button
	back_button.pressed.connect(_on_back_pressed)

	# 3. Initialize State (Visuals only)
	_initialize_visuals()

# --- CSV Logic ---

func _load_course_names() -> void:
	var path = "res://resources/csv/matkul/setnamelist.csv"
	if not FileAccess.file_exists(path):
		push_error("CSV file not found: " + path)
		return

	var file = FileAccess.open(path, FileAccess.READ)
	
	# A. Read Header (Skip it, but use it to count columns/matkuls)
	var headers = file.get_csv_line()
	var col_count = headers.size()
	
	# B. Initialize the cache array structure
	_course_names_cache.resize(col_count)
	for i in range(col_count):
		_course_names_cache[i] = []
	
	# C. Read Rows (The Course Names)
	while not file.eof_reached():
		var line = file.get_csv_line()
		
		# Validation: Skip empty lines or lines that don't match column count
		if line.size() != col_count:
			continue
			
		# Store data column by column
		# If Matkul is Column 0, we append Row X's Column 0 data to Cache[0]
		for i in range(col_count):
			_course_names_cache[i].append(line[i])

func _update_course_buttons(matkul_index: int) -> void:
	# Safety Check
	if matkul_index < 0 or matkul_index >= _course_names_cache.size():
		return
		
	var courses_for_matkul = _course_names_cache[matkul_index]
	var vbox = course_container.get_node("VBox")
	
	# Loop through the available strings (Should be 14)
	for i in range(courses_for_matkul.size()):
		# Button names are Course1, Course2... (1-based index)
		var btn_name = "Course" + str(i + 1)
		var btn = vbox.get_node_or_null(btn_name)
		
		if btn:
			btn.text = courses_for_matkul[i]

# --- Signal Receivers (Business Logic) ---

func _on_matkul_selected(index: int, _name: String) -> void:
	print("Matkul Selected: ", index)
	GVar.current_matkul = index
	
	# UPDATE: Change the text of Course1-14 based on the CSV data
	_update_course_buttons(index)
	
	_change_menu(matkul_container, mode_container, MenuState.MODE)

func _on_mode_selected(index: int, _name: String) -> void:
	print("Mode Selected: ", index)
	GVar.current_mode = index
	_change_menu(mode_container, course_container, MenuState.COURSE)

func _on_course_selected(index: int, _name: String) -> void:
	print("Course Selected: ", index)
	GVar.current_course = index
	# Start Game Logic Here

func _on_back_pressed() -> void:
	match current_state:
		MenuState.COURSE:
			_change_menu(course_container, mode_container, MenuState.MODE)
		MenuState.MODE:
			_change_menu(mode_container, matkul_container, MenuState.MATKUL)

# --- Animation & Transition System (Stays exactly the same) ---

func _change_menu(outgoing: Control, incoming: Control, new_state: int) -> void:
	_set_gui_input_disabled(true) # Lock UI
	
	var tween = create_tween()
	
	# Fade Out Outgoing
	tween.set_parallel(true)
	tween.tween_property(outgoing, "modulate:a", 0.0, 0.3)
	if new_state == MenuState.MATKUL:
		tween.tween_property(back_button, "modulate:a", 0.0, 0.3)
	
	# Switch Visibility
	tween.set_parallel(false)
	tween.tween_callback(outgoing.hide)
	if new_state == MenuState.MATKUL: tween.tween_callback(back_button.hide)
	tween.tween_callback(incoming.show)
	
	# Prepare Incoming
	incoming.modulate.a = 0.0 
	if current_state == MenuState.MATKUL and new_state == MenuState.MODE:
		back_button.show()
		back_button.modulate.a = 0.0

	# Fade In Incoming
	tween.set_parallel(true)
	tween.tween_property(incoming, "modulate:a", 1.0, 0.3)
	if current_state == MenuState.MATKUL and new_state == MenuState.MODE:
		tween.tween_property(back_button, "modulate:a", 1.0, 0.3)
	
	# Unlock UI
	tween.set_parallel(false)
	tween.tween_callback(func():
		_set_gui_input_disabled(false)
		current_state = new_state
	)

# --- Visual Helpers ---

func _initialize_visuals():
	matkul_container.modulate.a = 1.0
	mode_container.modulate.a = 0.0
	course_container.modulate.a = 0.0
	back_button.modulate.a = 0.0

	matkul_container.visible = true
	mode_container.visible = false
	course_container.visible = false
	back_button.visible = false

func _set_gui_input_disabled(disabled: bool):
	back_button.disabled = disabled
	# We can also disable the containers directly now!
	matkul_container.mouse_filter = Control.MOUSE_FILTER_IGNORE if disabled else Control.MOUSE_FILTER_STOP
	mode_container.mouse_filter = Control.MOUSE_FILTER_IGNORE if disabled else Control.MOUSE_FILTER_STOP
	course_container.mouse_filter = Control.MOUSE_FILTER_IGNORE if disabled else Control.MOUSE_FILTER_STOP
