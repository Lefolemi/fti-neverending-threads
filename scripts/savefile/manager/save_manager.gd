extends Node

const SAVE_PATH = "user://player_save.json"

func _ready() -> void:
	load_game()

# --- THE DATA TEMPLATE ---

func _get_default_data() -> Dictionary:
	var data = {
		"current_points": 0,
		"unlocked_achievements": [],
		"shop_unlocks": ["Default Theme"],
		"player_statistics": {
			"total_playtime": 0.0,
			"total_game_played": 0,
			"total_correct_answers": 0,
			"total_wrong_answers": 0,
			"longest_correct_streak": 0,
		},
		"course_stats": {},
		
		# --- NEW: EXPANDED SETTINGS ---
		"settings": {
			"quiz_allow_stopwatch": true,
			
			# General Settings
			"music_volume": 1.0,
			"sfx_volume": 1.0,
			
			# Cosmetic Settings
			"active_set": 1,
			"ui_color": 0, # 0 = Classic
			"invert_ui_color": false,
			"curved_borders": false,
			"ui_shadow": false,
			
			"bg_color": "1e1e1e", # Hex string representation
			"wallpaper_color": "ffffff",
			"wallpaper_opacity": 1.0,
			"wallpaper_path": "",
			
			# Breaking down Vector2 for JSON safety
			"wallpaper_motion_x": 0.0, 
			"wallpaper_motion_y": 0.0,
			
			"wallpaper_scale": 1.0,
			"wallpaper_warp": 0.0
		}
	}

	var subjects = [
		"Manajemen Proyek Perangkat Lunak", "Jaringan Komputer", 
		"Keamanan Siber", "Pemrograman Web 1", "Mobile Programming", 
		"Metodologi Riset", "Computer Vision", "Pengolahan Citra Digital"
	]
	
	for sub in subjects:
		data["course_stats"][sub] = { "Quizizz": {}, "Elearning": {} }
		for mode in ["Quizizz", "Elearning"]:
			for i in range(1, 15):
				data["course_stats"][sub][mode]["Set " + str(i)] = {"grade": "Locked", "time": 0.0}
			data["course_stats"][sub][mode]["Midtest"] = {"grade": "Locked", "time": 0.0}
			data["course_stats"][sub][mode]["Final Test"] = {"grade": "Locked", "time": 0.0}
			data["course_stats"][sub][mode]["All in One"] = {"grade": "Locked", "time": 0.0}
			
			data["course_stats"][sub][mode]["Set 1"]["grade"] = "Unplayed"
			
	return data

# --- CORE LOGIC ---

func load_game() -> void:
	var complete_data = _get_default_data()
	
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			
			var parsed_data = JSON.parse_string(json_string)
			if typeof(parsed_data) == TYPE_DICTIONARY:
				_deep_merge(complete_data, parsed_data)
				print("SYSTEM: Save file loaded and reconciled.")
			else:
				push_error("SYSTEM: Save file corrupted. Starting fresh.")
	else:
		print("SYSTEM: No save found. Generating fresh file.")
		
	_apply_to_gvar(complete_data)
	save_game()

func save_game() -> void:
	var current_data = {
		"current_points": GVar.current_points,
		"unlocked_achievements": GVar.unlocked_achievements,
		"shop_unlocks": GVar.shop_unlocks,
		"player_statistics": GVar.player_statistics,
		"course_stats": GVar.course_stats,
		
		# --- NEW: PACKING SETTINGS FROM GVAR ---
		"settings": {
			"quiz_allow_stopwatch": GVar.quiz_allow_stopwatch,
			"music_volume": GVar.music_volume,
			"sfx_volume": GVar.sfx_volume,
			"active_set": GVar.active_set,
			"ui_color": GVar.ui_color,
			"invert_ui_color": GVar.invert_ui_color,
			"curved_borders": GVar.curved_borders,
			"ui_shadow": GVar.ui_shadow,
			"bg_color": GVar.bg_color,
			"wallpaper_color": GVar.wallpaper_color,
			"wallpaper_opacity": GVar.wallpaper_opacity,
			"wallpaper_path": GVar.wallpaper_path,
			"wallpaper_motion_x": GVar.wallpaper_motion.x, # Extracting X
			"wallpaper_motion_y": GVar.wallpaper_motion.y, # Extracting Y
			"wallpaper_scale": GVar.wallpaper_scale,
			"wallpaper_warp": GVar.wallpaper_warp
		}
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(current_data, "\t"))
		file.close()
	else:
		push_error("CRITICAL: Could not create player_save.json!")

# --- HELPERS ---

func _deep_merge(base: Dictionary, patch: Dictionary) -> void:
	for key in patch:
		if base.has(key) and typeof(base[key]) == TYPE_DICTIONARY and typeof(patch[key]) == TYPE_DICTIONARY:
			_deep_merge(base[key], patch[key])
		else:
			base[key] = patch[key]

func _apply_to_gvar(data: Dictionary) -> void:
	GVar.current_points = data["current_points"]
	GVar.unlocked_achievements = data["unlocked_achievements"]
	GVar.shop_unlocks = data["shop_unlocks"]
	GVar.player_statistics = data["player_statistics"]
	GVar.course_stats = data["course_stats"]

	# --- NEW: UNPACKING SETTINGS TO GVAR ---
	if data.has("settings"):
		var s = data["settings"]
		if s.has("quiz_allow_stopwatch"): GVar.quiz_allow_stopwatch = s["quiz_allow_stopwatch"]
		if s.has("music_volume"): GVar.music_volume = s["music_volume"]
		if s.has("sfx_volume"): GVar.sfx_volume = s["sfx_volume"]
		
		if s.has("active_set"): GVar.active_set = s["active_set"]
		if s.has("ui_color"): GVar.ui_color = s["ui_color"]
		if s.has("invert_ui_color"): GVar.invert_ui_color = s["invert_ui_color"]
		if s.has("curved_borders"): GVar.curved_borders = s["curved_borders"]
		if s.has("ui_shadow"): GVar.ui_shadow = s["ui_shadow"]
		
		if s.has("bg_color"): GVar.bg_color = s["bg_color"]
		if s.has("wallpaper_color"): GVar.wallpaper_color = s["wallpaper_color"]
		if s.has("wallpaper_opacity"): GVar.wallpaper_opacity = s["wallpaper_opacity"]
		if s.has("wallpaper_path"): GVar.wallpaper_path = s["wallpaper_path"]
		
		# Reconstructing Vector2
		if s.has("wallpaper_motion_x") and s.has("wallpaper_motion_y"):
			GVar.wallpaper_motion = Vector2(s["wallpaper_motion_x"], s["wallpaper_motion_y"])
			
		if s.has("wallpaper_scale"): GVar.wallpaper_scale = s["wallpaper_scale"]
		if s.has("wallpaper_warp"): GVar.wallpaper_warp = s["wallpaper_warp"]
