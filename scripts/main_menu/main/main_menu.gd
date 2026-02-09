extends Control

# --- Setup ---
enum MenuState { MATKUL, MODE, COURSE }
var current_state: int = MenuState.MATKUL

# NOTE: These nodes now have the "MenuPage" script attached!
@onready var matkul_container: MenuPage = $MatkulContainer
@onready var mode_container: MenuPage = $ModeContainer
@onready var course_container: MenuPage = $CourseContainer

@onready var back_button: Button = $Back

func _ready() -> void:
	# 1. Connect to the CONTAINER signal, not the buttons directly
	matkul_container.item_selected.connect(_on_matkul_selected)
	mode_container.item_selected.connect(_on_mode_selected)
	course_container.item_selected.connect(_on_course_selected)
	
	# 2. Connect Back button
	back_button.pressed.connect(_on_back_pressed)

	# 3. Initialize State (Visuals only)
	_initialize_visuals()

# --- Signal Receivers (Business Logic) ---

# The container did the heavy lifting. We just get the clean Index here.
func _on_matkul_selected(index: int, _name: String) -> void:
	print("Matkul Selected: ", index)
	GVar.current_matkul = index
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
