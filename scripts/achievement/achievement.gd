extends GridContainer

# --- Node References ---
@onready var lbl_current_rank: Label = $Content/VBox/CurrentRank
@onready var vbox_achievements: VBoxContainer = $Content/VBox/AchievementList/VBox
@onready var lbl_to_go: Label = $Confirm/AchievementToGo
@onready var btn_close: Button = $Confirm/Close

const CSV_PATH = "res://resources/csv/menu/achievement.csv"

var parsed_achievements: Array = []
var unlocked_status: Array = [] # Stores the true/false state of each achievement based on live stats

var category_names = [
	"Manajemen Proyek Perangkat Lunak", "Jaringan Komputer", 
	"Keamanan Siber", "Pemrograman Web 1", "Mobile Programming", 
	"Metodologi Riset", "Computer Vision", "Pengolahan Citra Digital", 
	"Time Related", "Challenge Related"
]

const RANK_THRESHOLDS = [
	{"name": "None", "req": 0},
	{"name": "Amateur", "req": 150},
	{"name": "Novice", "req": 500},
	{"name": "Intermediate", "req": 1200},
	{"name": "Expert", "req": 2000},
	{"name": "Master", "req": 2600},
	{"name": "Magistra", "req": 2818}
]

func _ready() -> void:
	btn_close.pressed.connect(_on_close_pressed)
	_load_csv_data()
	_evaluate_all_achievements() # <--- THE NEW BRAIN
	_update_overall_progress()
	_generate_achievements()

# --- Data Handling & Live Evaluation ---

func _load_csv_data() -> void:
	if not FileAccess.file_exists(CSV_PATH):
		push_error("CSV file not found at: ", CSV_PATH)
		return
		
	var file = FileAccess.open(CSV_PATH, FileAccess.READ)
	file.get_csv_line()
	
	while not file.eof_reached():
		var line = file.get_csv_line()
		if line.size() >= 2 and line[0].strip_edges() != "":
			var title = line[0]
			var desc = line[1]
			var credits = 0
			var split_desc = desc.split("(")
			if split_desc.size() > 1:
				credits = split_desc[split_desc.size() - 1].to_int()
			
			parsed_achievements.append({
				"title": title,
				"desc": desc,
				"cr": credits
			})
	file.close()

func _evaluate_all_achievements() -> void:
	unlocked_status.clear()
	
	for i in range(parsed_achievements.size()):
		var is_unlocked = _calculate_unlock_condition(i)
		unlocked_status.append(is_unlocked)
		
		# Sync it to GVar so the rest of the game knows it's unlocked 
		# without having to do the math again.
		var title = parsed_achievements[i]["title"]
		if is_unlocked and not GVar.unlocked_achievements.has(title):
			GVar.unlocked_achievements.append(title)

# --- THE LOGIC ENGINE ---

func _calculate_unlock_condition(index: int) -> bool:
	# 1. Course Achievements (Index 0 to 55)
	if index < 56:
		var course_idx = index / 7
		var ach_type = index % 7
		var course_name = category_names[course_idx]
		var stats = GVar.course_stats[course_name]
		
		var sets_passed = _count_passed_sets(stats)
		
		match ach_type:
			0: return _has_started_any_set(stats)
			1: return sets_passed >= 7
			2: return sets_passed >= 14
			3: return _is_grade_90_plus(stats["Quizizz"]["Midtest"]["grade"]) or _is_grade_90_plus(stats["Elearning"]["Midtest"]["grade"])
			4: return sets_passed >= 21
			5: return sets_passed >= 28
			6: return _is_grade_100(stats["Quizizz"]["Final Test"]["grade"]) or _is_grade_100(stats["Elearning"]["Final Test"]["grade"])
			
	# 2. Time Related (Index 56 to 61)
	elif index < 62:
		var play_time_seconds = GVar.player_statistics["total_playtime"]
		match index:
			56: return play_time_seconds >= 1200    # 20 mins
			57: return play_time_seconds >= 7200    # 2 hours
			58: return play_time_seconds >= 18000   # 5 hours
			59: return play_time_seconds >= 43200   # 12 hours
			60: return play_time_seconds >= 86400   # 24 hours
			61: return play_time_seconds >= 129600  # 36 hours
			
	# 3. Challenge Related (Index 62 to 64)
	else:
		match index:
			62: return _count_passed_aio() >= 1
			63: return _count_passed_aio() >= 8
			64: return _is_100_percent_complete()
			
	return false

# --- HELPER MATH FUNCTIONS ---

func _is_passed(grade: String) -> bool:
	return grade in ["S", "A+", "A", "A-", "B+", "B", "B-", "C"]

func _is_grade_90_plus(grade: String) -> bool:
	return grade in ["S", "A+", "A"]

func _is_grade_100(grade: String) -> bool:
	return grade in ["S", "A+"]

func _has_started_any_set(course_stats: Dictionary) -> bool:
	for mode in ["Quizizz", "Elearning"]:
		for i in range(1, 15):
			var g = course_stats[mode]["Set " + str(i)]["grade"]
			if g != "Locked" and g != "Unplayed": return true
	return false

func _count_passed_sets(course_stats: Dictionary) -> int:
	var count = 0
	for mode in ["Quizizz", "Elearning"]:
		for i in range(1, 15):
			if _is_passed(course_stats[mode]["Set " + str(i)]["grade"]): count += 1
	return count

func _count_passed_aio() -> int:
	var count = 0
	for i in range(8):
		var sub = category_names[i]
		if _is_passed(GVar.course_stats[sub]["Quizizz"]["All in One"]["grade"]) or _is_passed(GVar.course_stats[sub]["Elearning"]["All in One"]["grade"]):
			count += 1
	return count

func _is_100_percent_complete() -> bool:
	for i in range(8):
		var stats = GVar.course_stats[category_names[i]]
		if _count_passed_sets(stats) < 28: return false
		if not _is_passed(stats["Quizizz"]["Final Test"]["grade"]) and not _is_passed(stats["Elearning"]["Final Test"]["grade"]): return false
	return true

# --- Async Dynamic Generation (Chunked) ---

func _generate_achievements() -> void:
	for child in vbox_achievements.get_children():
		child.queue_free()
		
	await get_tree().process_frame 
		
	var current_cat_idx = -1
	
	for i in range(parsed_achievements.size()):
		var ach = parsed_achievements[i]
		
		var cat_idx = 0
		if i < 56:   cat_idx = i / 7 
		elif i < 62: cat_idx = 8     
		else:        cat_idx = 9     
		
		if cat_idx != current_cat_idx:
			current_cat_idx = cat_idx
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(0, 10)
			vbox_achievements.add_child(spacer)
			
			var header = Label.new()
			header.text = "--- " + category_names[current_cat_idx].to_upper() + " ---"
			header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			header.add_theme_color_override("font_color", Color.AQUA)
			header.add_theme_font_size_override("font_size", 16)
			vbox_achievements.add_child(header)
			
		# Pass the boolean we calculated earlier directly into the box!
		var ach_box = _create_achievement_box(ach["title"], ach["desc"], ach["cr"], unlocked_status[i])
		vbox_achievements.add_child(ach_box)
		
		if i % 4 == 0:
			await get_tree().process_frame

func _create_achievement_box(title: String, desc: String, credits: int, is_unlocked: bool) -> Control:
	var bg_panel = PanelContainer.new()
	bg_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var hbox = HBoxContainer.new()
	bg_panel.add_child(hbox)
	
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(64, 64)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = Color(0.3, 0.3, 0.3) 
	hbox.add_child(icon)
	
	var text_vbox = VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(text_vbox)
	
	var lbl_title = Label.new()
	lbl_title.text = title
	lbl_title.add_theme_font_size_override("font_size", 14)
	lbl_title.add_theme_color_override("font_color", Color.GOLD)
	text_vbox.add_child(lbl_title)
	
	var lbl_desc = Label.new()
	lbl_desc.text = desc
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_desc.add_theme_font_size_override("font_size", 12)
	lbl_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	text_vbox.add_child(lbl_desc)
	
	var lbl_percent = Label.new()
	lbl_percent.text = "100%" if is_unlocked else "0%"
	lbl_percent.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_percent.add_theme_color_override("font_color", Color.GREEN if is_unlocked else Color.DARK_GRAY)
	hbox.add_child(lbl_percent)
	
	return bg_panel

# --- Progress Logic ---

func _update_overall_progress() -> void:
	var total_achievements = parsed_achievements.size()
	var unlocked_count = 0 
	var current_credits = 0
	
	# Uses the dynamically calculated array instead of trusting the string list
	for i in range(total_achievements):
		if unlocked_status[i]:
			unlocked_count += 1
			current_credits += parsed_achievements[i]["cr"]
	
	var current_rank = "None"
	var credits_to_go = 0
	
	for i in range(RANK_THRESHOLDS.size()):
		if current_credits >= RANK_THRESHOLDS[i]["req"]:
			current_rank = RANK_THRESHOLDS[i]["name"]
			if i + 1 < RANK_THRESHOLDS.size():
				credits_to_go = RANK_THRESHOLDS[i + 1]["req"] - current_credits
			else:
				credits_to_go = 0
		else:
			break

	var rank_display = "Rank\n" + current_rank + "\n"
	if credits_to_go > 0:
		rank_display += str(credits_to_go) + " cr to go"
	else:
		rank_display += "MAX RANK REACHED!"

	lbl_current_rank.text = rank_display
	lbl_to_go.text = str(unlocked_count) + "/" + str(total_achievements) + " Unlocked!"

func _on_close_pressed() -> void:
	if GVar.last_scene != "":
		Load.load_res([GVar.last_scene], GVar.last_scene)
	else:
		push_warning("GVar.last_scene is empty!")
