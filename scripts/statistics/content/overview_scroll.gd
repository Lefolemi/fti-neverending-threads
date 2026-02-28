extends ScrollContainer

@onready var vbox: VBoxContainer = $VBox

func _ready() -> void:
	_generate_overview_list()

func _generate_overview_list() -> void:
	var p_stats = GVar.player_statistics
	var correct = p_stats["total_correct_answers"]
	var wrong = p_stats["total_wrong_answers"]
	var total_q = correct + wrong
	var playtime = p_stats["total_playtime"]
	
	# Tap directly into the "Single Source of Truth" for the true 285-task progression!
	var progression_pct = AchievementManager.get_total_completion_percentage()
	
	var real_overview = {
		"Game Progression": "%.1f%%" % progression_pct,
		"Total Playtime": _format_time_long(playtime),
		"Total Games Played": str(p_stats["total_game_played"]),
		"Total Questions Answered": str(total_q),
		"Current Rank": _get_rank_title(GVar.current_points),
		"Total Points Earned": str(GVar.current_points) + " Pts"
	}
	
	_populate_simple_vbox(real_overview)

func _populate_simple_vbox(data: Dictionary) -> void:
	# Clear placeholder UI just in case
	for child in vbox.get_children():
		child.queue_free()
		
	# Build the rows dynamically
	for key in data.keys():
		vbox.add_child(_create_stat_row(key, data[key]))
		var separator = HSeparator.new()
		separator.add_theme_constant_override("separation", 10)
		vbox.add_child(separator)

# --- Formatting Helpers ---

func _format_time_long(time_sec: float) -> String:
	var hrs = int(time_sec) / 3600
	var mins = (int(time_sec) % 3600) / 60
	if hrs > 0: return "%dh %dm" % [hrs, mins]
	return "%dm" % mins

func _get_rank_title(points: int) -> String:
	if points >= 2818: return "Magistra"
	if points >= 2600: return "Master"
	if points >= 2000: return "Expert"
	if points >= 1200: return "Intermediate"
	if points >= 500: return "Novice"
	if points >= 150: return "Amateur"
	return "Unranked"

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
	if value.begins_with("Ɐ"):
		base_color = Color.PURPLE
	elif value.ends_with("s") or value.ends_with("m"): 
		base_color = Color.YELLOW
	elif "%" in value:
		# Automatically color the progression percentage!
		var val_pct = value.to_float()
		if val_pct >= 80.0: base_color = Color.GREEN
		elif val_pct >= 30.0: base_color = Color.YELLOW
		else: base_color = Color.RED
		
	# Apply dynamic harmony
	lbl_value.add_theme_color_override("font_color", GConst.get_dynamic_text_color(base_color))

	hbox.add_child(lbl_value)
	return hbox
