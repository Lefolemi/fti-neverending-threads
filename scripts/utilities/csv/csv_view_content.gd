extends VBoxContainer

@onready var search_bar: LineEdit = $SearchBar
@onready var sort_by_opt: OptionButton = $Sort/SortBy
@onready var sort_order_opt: OptionButton = $Sort/SortOrder
@onready var table: Tree = $Table

# --- Data ---
var _master_rows: Array = [] 
var _column_count: int = 0

# --- Optimization Tools ---
var _search_timer: Timer = null
var _current_render_job_id: int = 0 # To cancel old jobs if you type fast

func _ready() -> void:
	# 1. Setup the Debounce Timer dynamically
	_search_timer = Timer.new()
	_search_timer.wait_time = 0.5 # Wait 0.5s after typing stops
	_search_timer.one_shot = true
	add_child(_search_timer)
	_search_timer.timeout.connect(_on_debounce_timer_timeout)

	# 2. Wait for parent to fill table, then scrape it
	_init_data_from_tree.call_deferred()

	# 3. Connect Signals
	search_bar.text_changed.connect(_on_search_text_changed)
	sort_by_opt.item_selected.connect(_on_ui_changed)
	sort_order_opt.item_selected.connect(_on_ui_changed)

func _init_data_from_tree() -> void:
	# (This part stays the same: Scraping the initial data)
	_column_count = table.columns
	
	# Setup Sort Options
	sort_by_opt.clear()
	sort_by_opt.add_item("None", -1)
	for i in range(_column_count):
		var title = table.get_column_title(i)
		sort_by_opt.add_item(title, i)

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
	# STOP everything. Don't search yet.
	# Cancel any currently running render job
	_current_render_job_id += 1 
	
	# Show "Searching..." feedback immediately
	table.clear()
	var root = table.create_item()
	var feedback = table.create_item(root)
	feedback.set_text(0, "Searching...")
	
	# Restart the timer. The search will only happen if this timer hits 0.
	_search_timer.start()

func _on_ui_changed(_index: int) -> void:
	# For sorting, we can just update immediately (or debounce too if you want)
	_update_table_async()

func _on_debounce_timer_timeout() -> void:
	# The user finally stopped typing! Now we work.
	_update_table_async()

# --- The Async Worker ---

func _update_table_async() -> void:
	# Generate a new Job ID. If this ID changes mid-loop, we stop.
	_current_render_job_id += 1
	var my_job_id = _current_render_job_id
	
	# 1. Prepare Data (Filter & Sort)
	# This part is fast enough to do synchronously usually
	var filtered_rows = _filter_and_sort_data()
	
	# 2. Clear Table
	table.clear()
	var root = table.create_item() # Hidden root
	
	if filtered_rows.is_empty():
		var item = table.create_item(root)
		item.set_text(0, "No results found.")
		return

	# 3. CHUNKED RENDERING (The Anti-Lag Magic)
	var chunk_size = 20 # How many rows to draw per frame
	var count = 0
	
	for row_data in filtered_rows:
		# CHECK: Did the user type something new while we were drawing?
		if my_job_id != _current_render_job_id:
			return # ABORT! A new job started.
			
		var item = table.create_item(root)
		for i in range(row_data.size()):
			item.set_text(i, row_data[i])
			item.set_text_alignment(i, HORIZONTAL_ALIGNMENT_LEFT)
		
		# If we drew 'chunk_size' items, take a break!
		count += 1
		if count >= chunk_size:
			count = 0
			await get_tree().process_frame # Wait for next frame (keeps UI responsive)

# --- Helper Logic ---
func _filter_and_sort_data() -> Array:
	var result = []
	var query = search_bar.text.to_lower().strip_edges()
	
	# Filter
	if query == "":
		result = _master_rows.duplicate()
	else:
		for row in _master_rows:
			for cell in row:
				if query in cell.to_lower():
					result.append(row)
					break

	# Sort
	var col_idx = sort_by_opt.get_selected_id()
	var order_idx = sort_order_opt.selected
	
	if col_idx != -1 and order_idx != 0:
		result.sort_custom(func(a, b):
			if order_idx == 1: 
				return a[col_idx].naturalnocasecmp_to(b[col_idx]) < 0
			else: 
				return a[col_idx].naturalnocasecmp_to(b[col_idx]) > 0
		)
	
	return result
