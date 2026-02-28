extends ScrollContainer

@onready var vbox: VBoxContainer = $VBox

func _ready() -> void:
	_generate_performance_list()

func _generate_performance_list() -> void:
	var p_stats = GVar.player_statistics
	var correct = p_stats["total_correct_answers"]
	var wrong = p_stats["total_wrong_answers"]
	var total_q = correct + wrong
	var playtime = p_stats["total_playtime"]
	
	# Calculate Dynamic Accuracies and Averages
	var accuracy = 0.0
	if total_q > 0: 
		accuracy = (float(correct) / float(total_q)) * 100.0
	
	var avg_time = 0.0
	if total_q > 0: 
		avg_time = playtime / float(total_q)
	
	var real_performance = {
		"Total Correct": str(correct),
		"Total Wrong": str(wrong),
		"Overall Accuracy": "%.1f%%" % accuracy,
		"Longest Win Streak": str(p_stats["longest_correct_streak"]),
		"Avg Time Per Question": "%.1fs" % avg_time
	}
	
	_populate_simple_vbox(real_performance)

func _populate_simple_vbox(data: Dictionary) -> void:
	# Clear placeholder UI
	for child in vbox.get_children():
		child.queue_free()
		
	# Build the rows dynamically
	for key in data.keys():
		vbox.add_child(_create_stat_row(key, data[key]))
		var separator = HSeparator.new()
		separator.add_theme_constant_override("separation", 10)
		vbox.add_child(separator)

# --- Formatting Helpers (Isolated to this script) ---

func _create_stat_row(title: String, value: String) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var lbl_title = Label.new()
	lbl_title.text = title
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	hbox.add_child(lbl_title)
	
	var lbl_value = Label.new()
	lbl_value.text = value
	lbl_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	# Determine raw base color
	var base_color = Color.WHITE
	if value.ends_with("s") or value.ends_with("m"): 
		base_color = Color.YELLOW
	elif "%" in value:
		var acc_val = value.to_float()
		if acc_val >= 80.0:
			base_color = Color.GREEN
		elif acc_val >= 50.0:
			base_color = Color.YELLOW
		else:
			base_color = Color.RED
			
	# Apply dynamic harmony
	lbl_value.add_theme_color_override("font_color", GConst.get_dynamic_text_color(base_color))
		
	hbox.add_child(lbl_value)
	return hbox
