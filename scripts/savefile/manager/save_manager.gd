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
		
		# --- EXPANDED SETTINGS ---
		"settings": {
			"quiz_allow_stopwatch": true,
			"music_volume": 1.0,
			"sfx_volume": 1.0,
			"active_set": 1,
			"ui_color": 0, # Main fallback just in case
			"aesthetic_sets": {} # This will hold 6 dictionaries
		}
	}

	# --- GENERATE THE 6 PROFILES (SAVE SLOTS) ---
	for i in range(1, 7):
		data["settings"]["aesthetic_sets"][str(i)] = {
			"ui_color": 0, # 0 = Classic, using INT ID as intended
			"invert_ui_color": false,
			"curved_borders": false,
			"ui_shadow": false,
			"bg_color": "4d4d4d",
			"wp_color": "ffffff",
			"wp_opacity": 1.0,
			"wp_id": 0,
			"wp_motion_x": 0.0, 
			"wp_motion_y": 0.0,
			"wp_scale": 1.0,
			"wp_warp": 0.0
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
	# 1. Sync the active live variables in GVar into the active set profile before saving!
	var active_id = str(GVar.active_set)
	
	# Fallback if GVar doesn't have the dictionary yet
	if not GVar.get("aesthetic_sets"):
		GVar.aesthetic_sets = _get_default_data()["settings"]["aesthetic_sets"]
		
	# Overwrite the active set slot with whatever is currently on screen
	GVar.aesthetic_sets[active_id] = {
		"ui_color": GVar.ui_color,
		"invert_ui_color": GVar.invert_ui_color,
		"curved_borders": GVar.curved_borders,
		"ui_shadow": GVar.ui_shadow,
		"bg_color": GVar.current_bg_color.to_html(false),
		"wp_color": GVar.current_wp_color.to_html(false),
		"wp_opacity": GVar.current_opacity,
		"wp_id": GVar.current_wp_id,
		"wp_motion_x": GVar.current_velocity.x,
		"wp_motion_y": GVar.current_velocity.y,
		"wp_scale": GVar.current_scale,
		"wp_warp": GVar.current_warp
	}
	
	# 2. Compile the JSON data
	var current_data = {
		"current_points": GVar.current_points,
		"unlocked_achievements": GVar.unlocked_achievements,
		"shop_unlocks": GVar.shop_unlocks,
		"player_statistics": GVar.player_statistics,
		"course_stats": GVar.course_stats,
		
		"settings": {
			"quiz_allow_stopwatch": GVar.quiz_allow_stopwatch,
			"music_volume": GVar.music_volume,
			"sfx_volume": GVar.sfx_volume,
			"active_set": GVar.active_set,
			"aesthetic_sets": GVar.aesthetic_sets # Save all 6 profiles!
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

	if data.has("settings"):
		var s = data["settings"]
		if s.has("quiz_allow_stopwatch"): GVar.quiz_allow_stopwatch = s["quiz_allow_stopwatch"]
		if s.has("music_volume"): GVar.music_volume = s["music_volume"]
		if s.has("sfx_volume"): GVar.sfx_volume = s["sfx_volume"]
		if s.has("active_set"): GVar.active_set = s["active_set"]
		
		# --- UNPACK AESTHETICS ---
		if s.has("aesthetic_sets"):
			GVar.aesthetic_sets = s["aesthetic_sets"]
			
			# Pull the settings of the ACTIVE SET directly into GVar's live variables
			var active_id = str(GVar.active_set)
			if GVar.aesthetic_sets.has(active_id):
				var config = GVar.aesthetic_sets[active_id]
				
				GVar.ui_color = config.get("ui_color", 0) # <--- Default is 0 (Classic)
				GVar.invert_ui_color = config.get("invert_ui_color", false)
				GVar.curved_borders = config.get("curved_borders", false)
				GVar.ui_shadow = config.get("ui_shadow", false)
				
				GVar.current_bg_color = Color(config.get("bg_color", "4d4d4d"))
				GVar.current_wp_color = Color(config.get("wp_color", "ffffff"))
				GVar.current_opacity = config.get("wp_opacity", 1.0)
				GVar.current_wp_id = config.get("wp_id", 0)
				
				GVar.current_velocity = Vector2(config.get("wp_motion_x", 0.0), config.get("wp_motion_y", 0.0))
				GVar.current_scale = config.get("wp_scale", 1.0)
				GVar.current_warp = config.get("wp_warp", 0.0)
