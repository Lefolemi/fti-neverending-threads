extends Node

const CSV_PATH = "res://resources/csv/menu/achievement.csv"

var parsed_achievements: Array = []

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
	_load_csv_data()

# --- Public Evaluation Engine ---

func evaluate_all() -> void:
	var old_rank = get_current_rank()
	var triggered_new_save = false
	var played_ach_sfx = false # Prevents deafening the player if multiple pop at once
	
	for i in range(parsed_achievements.size()):
		var ach = parsed_achievements[i]
		
		# If we don't already have it, check if we just earned it!
		if not GVar.unlocked_achievements.has(ach["title"]):
			if _calculate_unlock_condition(i):
				# 1. Add to Array
				GVar.unlocked_achievements.append(ach["title"])
				# 2. Add Credits
				GVar.current_points += ach["cr"]
				
				# 3. Fire Notification & SFX
				Notify.notify_achievement(ach["title"], ach["desc"])
				
				# Ensure the sound only plays once per frame even if 5 achievements unlock at the same time
				if not played_ach_sfx:
					Audio.play_sfx("res://audio/sfx/notification.wav")
					played_ach_sfx = true
					
				triggered_new_save = true
				
	# If we got any new achievements, check if those new points leveled us up!
	if triggered_new_save:
		var new_rank = get_current_rank()
		if new_rank != old_rank:
			Notify.notify_rank_up(new_rank)
			# Fire Rank Up SFX
			Audio.play_sfx("res://audio/sfx/rankup.wav")
		
		# Auto-save the new points and unlocked arrays
		SaveManager.save_game()

func get_current_rank() -> String:
	var current_rank = "None"
	for i in range(RANK_THRESHOLDS.size()):
		if GVar.current_points >= RANK_THRESHOLDS[i]["req"]:
			current_rank = RANK_THRESHOLDS[i]["name"]
		else:
			break
	return current_rank

# --- Data Loading ---

func _load_csv_data() -> void:
	if not FileAccess.file_exists(CSV_PATH): return
	var file = FileAccess.open(CSV_PATH, FileAccess.READ)
	file.get_csv_line() # Skip header
	while not file.eof_reached():
		var line = file.get_csv_line()
		if line.size() >= 2 and line[0].strip_edges() != "":
			var title = line[0]
			var desc = line[1]
			var credits = 0
			var split_desc = desc.split("(")
			if split_desc.size() > 1:
				credits = split_desc[split_desc.size() - 1].to_int()
			parsed_achievements.append({"title": title, "desc": desc, "cr": credits})
	file.close()

# --- The Logic & Math (Moved from Achievement.gd) ---

func _calculate_unlock_condition(index: int) -> bool:
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
			
	elif index < 62:
		var play_time_seconds = GVar.player_statistics["total_playtime"]
		match index:
			56: return play_time_seconds >= 1200
			57: return play_time_seconds >= 7200
			58: return play_time_seconds >= 18000
			59: return play_time_seconds >= 43200
			60: return play_time_seconds >= 86400
			61: return play_time_seconds >= 129600
	else:
		match index:
			62: return _count_passed_aio() >= 1
			63: return _count_passed_aio() >= 8
			64: return _is_100_percent_complete()
	return false

# --- Float/Variant Evaluators ---

func _is_passed(grade: Variant) -> bool:
	var g_str = str(grade)
	if g_str == "Locked" or g_str == "Unplayed": return false
	var g_float = float(grade)
	return g_float >= 50.0 or g_float == -1.0

func _is_grade_90_plus(grade: Variant) -> bool:
	var g_str = str(grade)
	if g_str == "Locked" or g_str == "Unplayed": return false
	return float(grade) >= 90.0

func _is_grade_100(grade: Variant) -> bool:
	var g_str = str(grade)
	if g_str == "Locked" or g_str == "Unplayed": return false
	return float(grade) >= 100.0

func _has_started_any_set(course_stats: Dictionary) -> bool:
	for mode in ["Quizizz", "Elearning"]:
		for i in range(1, 15):
			var g = course_stats[mode]["Set " + str(i)]["grade"]
			if str(g) != "Locked" and str(g) != "Unplayed": return true
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
