extends Control

@onready var table: Tree = $Content/Table
@onready var path_label: Label = $Content/Info/FilePathLabel
@onready var back_btn: Button = $Content/Info/BackButton

func _ready() -> void:
	# 1. Connect Back Button
	back_btn.pressed.connect(_on_back_pressed)

	# 2. Load the CSV
	if GVar.current_csv != "":
		load_csv_into_table(GVar.current_csv)
	else:
		path_label.text = "Error: No CSV file specified in GVar."

func _on_back_pressed() -> void:
	if GVar.last_scene != "":
		# Use standard change_scene or your custom Load.load_res
		Load.load_res([GVar.last_scene], GVar.last_scene)
	else:
		push_warning("GVar.last_scene is empty! Nowhere to go back to.")
		# Optional: Go to Main Menu as fallback
		# get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func load_csv_into_table(path: String) -> void:
	path_label.text = "Viewing: " + path.get_file()
	
	if not FileAccess.file_exists(path):
		path_label.text = "Error: File not found!"
		return

	var file = FileAccess.open(path, FileAccess.READ)
	
	# --- STEP 1: Setup Columns (Header) ---
	# Read the first line to get column names
	var headers = file.get_csv_line() 
	
	table.clear()
	table.columns = headers.size()
	table.set_column_titles_visible(true)
	
	for i in range(headers.size()):
		table.set_column_title(i, headers[i])
		# Optional: Set minimum width so it's readable
		table.set_column_expand(i, true)
		table.set_column_custom_minimum_width(i, 100)

	# --- STEP 2: Fill Rows ---
	# Create a "root" item (required for Tree node, even if hidden)
	var root = table.create_item()

	while not file.eof_reached():
		var line_data = file.get_csv_line()
		
		# Skip empty lines (often happen at end of file)
		if line_data.size() < headers.size():
			continue
			
		# Create a row item
		var row = table.create_item(root)
		
		# Fill cells
		for i in range(min(line_data.size(), headers.size())):
			row.set_text(i, line_data[i])
			# alignment center usually looks better
			row.set_text_alignment(i, HORIZONTAL_ALIGNMENT_LEFT)
