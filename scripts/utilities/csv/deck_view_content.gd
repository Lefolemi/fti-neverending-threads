extends VBoxContainer

# Signal to let the Root script know a question was marked/unmarked
signal mark_toggled(question_text: String, is_marked: bool)

@onready var search_bar: LineEdit = $SearchBar
@onready var sort_by_opt: OptionButton = $Sort/SortBy
@onready var sort_order_opt: OptionButton = $Sort/SortOrder
@onready var table: Tree = $Table

# --- Data ---
var _master_rows: Array = [] 
var _column_count: int = 0
var _marked_col_idx: int = -1 # We will find this dynamically

# --- Optimization Tools ---
var _search_timer: Timer = null
var _current_render_job_id: int = 0

func _ready() -> void:
	# 1. Setup the Debounce Timer dynamically
	_search_timer = Timer.new()
	_search_timer.wait_time = 0.3 # Slightly faster response
	_search_timer.one_shot = true
	add_child(_search_timer)
	_search_timer.timeout.connect(_on_debounce_timer_timeout)

	# 2. Connect Signals
	search_bar.text_changed.connect(_on_search_text_changed)
	sort_by_opt.item_selected.connect(_on_ui_changed)
	sort_order_opt.item_selected.connect(_on_ui_changed)
	
	# Connect tree item editing so we can detect checkbox clicks
	table.item_edited.connect(_on_table_item_edited)

# Called by the Root script after it loads the CSV into the Tree
func _init_data_from_tree() -> void:
	_column_count = table.columns
	
	# Setup Sort Options and find the "marked" column
	sort_by_opt.clear()
	sort_by_opt.add_item("None", -1)
	
	_marked_col_idx = -1
	for i in range(_column_count):
		var title = table.get_column_title(i)
		sort_by_opt.add_item(title, i)
		if title.to_lower() == "marked":
			_marked_col_idx = i

	# Scrape Rows
	_master_rows.clear()
	var root = table.get_root()
	if root:
		var child = root.get_first_child()
		while child:
			var row_data = []
			for i in range(_column_count):
				row_data.append(child.get_text(i))
			_master_rows.append(row_data)
			child = child.get_next()

# --- The Signal Receivers ---

func _on_search_text_changed(_new_text: String) -> void:
	_current_render_job_id += 1 
	
	table.clear()
	var root = table.create_item()
	var feedback = table.create_item(root)
	feedback.set_text(0, "Searching...")
	
	_search_timer.start()

func _on_ui_changed(_index: int) -> void:
	_update_table_async()

func _on_debounce_timer_timeout() -> void:
	_update_table_async()

# --- The Async Worker ---

func _update_table_async() -> void:
	_current_render_job_id += 1
	var my_job_id = _current_render_job_id
	
	var filtered_rows = _filter_and_sort_data()
	
	table.clear()
	var root = table.create_item() # Hidden root
	
	if filtered_rows.is_empty():
		var item = table.create_item(root)
		item.set_text(0, "No results found.")
		return

	var chunk_size = 20 
	var count = 0
	
	for row_data in filtered_rows:
		if my_job_id != _current_render_job_id:
			return # ABORT! A new job started.
			
		var item = table.create_item(root)
		for i in range(row_data.size()):
			# Special handling for the "marked" column -> Make it a Checkbox!
			if i == _marked_col_idx:
				item.set_cell_mode(i, TreeItem.CELL_MODE_CHECK)
				item.set_checked(i, row_data[i] == "1")
				item.set_text(i, "") # Clear text, we just want the box
				item.set_editable(i, true)
			else:
				item.set_text(i, str(row_data[i]))
				item.set_text_alignment(i, HORIZONTAL_ALIGNMENT_LEFT)
		
		count += 1
		if count >= chunk_size:
			count = 0
			await get_tree().process_frame

# --- Interaction Logic ---
func _on_table_item_edited() -> void:
	var item = table.get_edited()
	var col = table.get_edited_column()
	
	# If the user clicked the checkbox in the "marked" column
	if col == _marked_col_idx:
		var is_marked = item.is_checked(col)
		# Assume column 0 is the "question" text (used as unique ID)
		var question_text = item.get_text(0) 
		
		# Update our master array so it remembers the state during searches/sorts
		for row in _master_rows:
			if row[0] == question_text:
				row[col] = "1" if is_marked else "0"
				break
				
		# Tell the Root script to update the actual CSV file
		emit_signal("mark_toggled", question_text, is_marked)

# --- Helper Logic ---
func _filter_and_sort_data() -> Array:
	var result = []
	var query = search_bar.text.to_lower().strip_edges()
	
	# Filter
	if query == "":
		result = _master_rows.duplicate()
	else:
		for row in _master_rows:
			var match_found = false
			for cell in row:
				if query in str(cell).to_lower():
					match_found = true
					break
			if match_found:
				result.append(row)

	# Sort
	var col_idx = sort_by_opt.get_selected_id()
	var order_idx = sort_order_opt.selected
	
	if col_idx != -1 and order_idx != 0:
		result.sort_custom(func(a, b):
			var val_a = str(a[col_idx])
			var val_b = str(b[col_idx])
			if order_idx == 1: 
				return val_a.naturalnocasecmp_to(val_b) < 0
			else: 
				return val_a.naturalnocasecmp_to(val_b) > 0
		)
	
	return result
