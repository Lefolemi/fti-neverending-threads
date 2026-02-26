extends Control

@onready var back_btn: Button = $Content/Info/BackButton
@onready var course_opt: OptionButton = $Content/Info/Course
@onready var unmark_all_btn: Button = $Content/Utilities/UnmarkAll
@onready var table: Tree = $Content/Table

# Assuming your search/sort script from earlier is attached to this VBoxContainer
@onready var content_container: VBoxContainer = $Content 

var current_course_id: int = 0

func _ready() -> void:
	# 1. Connect Buttons
	back_btn.pressed.connect(_on_back_pressed)
	unmark_all_btn.pressed.connect(_on_unmark_all_pressed)
	
	# Connect to the VBoxContainer's custom signal we made earlier
	if content_container.has_signal("mark_toggled"):
		content_container.mark_toggled.connect(_on_mark_toggled)
	
	# 2. Setup Course OptionButton
	course_opt.item_selected.connect(_on_course_selected)

	# 3. Load the initial CSV (Defaults to index 0 / Course 0)
	var initial_index = course_opt.selected if course_opt.selected != -1 else 0
	_load_course_csv(initial_index)

func _on_back_pressed() -> void:
	if GVar.last_scene != "":
		Load.load_res([GVar.last_scene], GVar.last_scene)
	else:
		push_warning("GVar.last_scene is empty! Nowhere to go back to.")

func _on_course_selected(index: int) -> void:
	var course_id = course_opt.get_item_id(index)
	_load_course_csv(course_id)

func _load_course_csv(course_id: int) -> void:
	current_course_id = course_id
	var path = "res://resources/csv/matkul/course%d.csv" % course_id

	if not FileAccess.file_exists(path):
		push_error("Error: File not found! " + path)
		return

	var file = FileAccess.open(path, FileAccess.READ)
	
	# --- STEP 1: Setup Columns (Header) ---
	var headers = file.get_csv_line() 
	
	# Find the "seen" column index dynamically
	var seen_idx = headers.find("seen")
	
	table.clear()
	# The UI table will have 1 less column if "seen" exists
	var display_col_count = headers.size() - (1 if seen_idx != -1 else 0)
	table.columns = display_col_count
	table.set_column_titles_visible(true)
	
	var ui_col_idx = 0
	for i in range(headers.size()):
		if i == seen_idx:
			continue # SKIP adding "seen" to the UI
			
		table.set_column_title(ui_col_idx, headers[i])
		table.set_column_expand(ui_col_idx, true)
		table.set_column_custom_minimum_width(ui_col_idx, 100)
		ui_col_idx += 1

	# --- STEP 2: Fill Rows (Filtered by 'seen' == 1) ---
	var root = table.create_item()

	while not file.eof_reached():
		var line_data = file.get_csv_line()
		
		# Skip empty lines at the end of file
		if line_data.size() < headers.size():
			continue
			
		# CRITICAL: If the question hasn't been seen, do NOT load it.
		if seen_idx != -1 and line_data[seen_idx] != "1":
			continue
			
		var row = table.create_item(root)
		
		# Fill cells, carefully mapping CSV index to UI index
		var cell_ui_idx = 0
		for i in range(min(line_data.size(), headers.size())):
			if i == seen_idx:
				continue # SKIP putting "seen" data into the table
				
			row.set_text(cell_ui_idx, line_data[i])
			row.set_text_alignment(cell_ui_idx, HORIZONTAL_ALIGNMENT_LEFT)
			cell_ui_idx += 1

	# --- STEP 3: Notify the Search/Sort Script ---
	if content_container.has_method("_init_data_from_tree"):
		content_container._init_data_from_tree()
		if content_container.has_method("_update_table_async"):
			content_container._update_table_async()

# --- CSV FILE WRITING LOGIC ---

# Triggered whenever the player clicks a checkbox in the UI
func _on_mark_toggled(question_text: String, is_marked: bool) -> void:
	_update_csv_marked_state(question_text, false, is_marked)

# Triggered when "Unmark All" button is pressed (NOW WITH DOUBLE CONFIRMATION)
func _on_unmark_all_pressed() -> void:
	# 1st Confirmation
	var is_sure = await ConfirmManager.ask("Are you sure you want to unmark ALL questions in this course?")
	
	if is_sure:
		# 2nd Confirmation (The big warning)
		var is_absolutely_sure = await ConfirmManager.ask("WARNING: This will permanently wipe all your bookmarks for this course and cannot be undone!\n\nAre you ABSOLUTELY sure?")
		
		if is_absolutely_sure:
			print("Double confirmation passed! Wiping marks for course: ", current_course_id)
			_update_csv_marked_state("", true, false)
			# Reload the UI so all checkboxes disappear visually
			_load_course_csv(current_course_id)
		else:
			print("Player cancelled at the final warning.")
	else:
		print("Player cancelled the unmark all action.")

# Helper function to read, modify, and rewrite the CSV file
func _update_csv_marked_state(target_question: String, unmark_all: bool, is_marked: bool) -> void:
	var path = "res://resources/csv/matkul/course%d.csv" % current_course_id
	if not FileAccess.file_exists(path):
		return
		
	# 1. Read all rows from the CSV into memory
	var file = FileAccess.open(path, FileAccess.READ)
	var all_rows = []
	while not file.eof_reached():
		var line = file.get_csv_line()
		# Make sure we don't grab an empty trailing row
		if line.size() > 1 or (line.size() == 1 and line[0] != ""):
			all_rows.append(line)
	file.close()
	
	if all_rows.is_empty():
		return
		
	# 2. Find the "marked" column
	var headers = Array(all_rows[0])
	var marked_idx = headers.find("marked")
	
	if marked_idx == -1:
		push_warning("No 'marked' column found in CSV!")
		return
		
	# 3. Modify the data in memory
	for i in range(1, all_rows.size()):
		var row = all_rows[i]
		if unmark_all:
			# If unmarking all, set everything to 0
			row[marked_idx] = "0"
		elif row[0] == target_question:
			# We found the specific question the user clicked!
			row[marked_idx] = "1" if is_marked else "0"
			break # Stop searching, we found it
			
	# 4. Write everything back to the CSV
	file = FileAccess.open(path, FileAccess.WRITE)
	for row in all_rows:
		file.store_csv_line(row)
	file.close()
