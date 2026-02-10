extends PanelContainer

func show_menu(node: String):
	# 1. Hide this container (MenuVBox)
	hide()

	# 2. Access the 'QuizDebug' node via the scene root (owner)
	# This is the "root.QuizDebug" equivalent you wanted.
	var quiz_debug = owner.get_node(node)
	quiz_debug.show()

func _on_cancel_button_pressed() -> void:
	show_menu("QuizDebug")

# --- Configuration ---
const SCAN_DIR: String = "res://resources/csv/"
const VIEW_SCENE_PATH: String = "res://scenes/utilities/csv/csv_view.tscn"

# --- References ---
# This matches the path you described: $Margin/VBox/FileList/VBox
@onready var item_container: VBoxContainer = $Margin/VBox/FileList/VBox

func _ready() -> void:
	# Clean up any placeholder/dummy buttons from the editor
	for child in item_container.get_children():
		child.queue_free()
	
	# Start the scan
	refresh_file_list()

func refresh_file_list() -> void:
	var all_csvs: Array[String] = []
	_scan_recursive(SCAN_DIR, all_csvs)
	
	if all_csvs.is_empty():
		print("Debug: No CSV files found in ", SCAN_DIR)
		return

	for file_path in all_csvs:
		_create_ui_row(file_path)

# --- 1. The Recursive Crawler (The Engine) ---
func _scan_recursive(path: String, result_list: Array[String]) -> void:
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if dir.current_is_dir():
				# Recursion: If it's a folder, dig deeper!
				# We skip hidden folders usually starting with "."
				if not file_name.begins_with("."): 
					_scan_recursive(path.path_join(file_name), result_list)
			else:
				# It's a file. Is it a CSV?
				if file_name.ends_with(".csv"):
					result_list.append(path.path_join(file_name))
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
	else:
		push_error("Failed to open directory: " + path)

# --- 2. The UI Builder (The Visuals) ---
func _create_ui_row(full_path: String) -> void:
	# A. Create the Container
	var hbox = HBoxContainer.new()
	
	# B. Create the File Button (The Name)
	var btn_file = Button.new()
	# Show relative path so it's readable (e.g. "debug/test.csv" instead of full res://...)
	btn_file.text = full_path.replace(SCAN_DIR, "") 
	btn_file.size_flags_horizontal = Control.SIZE_EXPAND_FILL # Dynamic Expansion
	btn_file.alignment = HORIZONTAL_ALIGNMENT_LEFT # Align text to left looks better in lists
	
	# C. Create the Explore Button (The Action)
	var btn_explore = Button.new()
	btn_explore.text = "Explore"
	# Connect the signal using .bind() to pass the specific path
	btn_explore.pressed.connect(_on_explore_pressed.bind(full_path))
	
	# D. Assemble
	hbox.add_child(btn_file)
	hbox.add_child(btn_explore)
	item_container.add_child(hbox)

# --- 3. The Action ---
func _on_explore_pressed(csv_path: String) -> void:
	print("Opening CSV: ", csv_path)
	
	# Update Global Variables
	GVar.current_csv = csv_path
	
	# Save the CURRENT scene path so we know where to come back to
	# 'owner' refers to the root of the debug_mode.tscn
	if owner:
		GVar.last_scene = owner.scene_file_path
	else:
		# Fallback if this node is tested in isolation
		GVar.last_scene = self.scene_file_path

	# Go to the CSV View
	Load.load_res([VIEW_SCENE_PATH], VIEW_SCENE_PATH)
