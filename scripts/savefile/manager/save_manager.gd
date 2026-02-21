extends Node

const SAVE_DIR = "user://saves/"

# Cache the loaded resources so we don't hit the disk constantly
var _profile_cache: ResProfile = null
var _general_settings_cache: Resource = null

func _ready():
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_absolute(SAVE_DIR)
	
	# Load global profile immediately on start
	load_global_profile()

# --- GENERIC SAVE/LOAD ENGINE ---

func _save_resource(res: Resource, filename: String) -> void:
	var path = SAVE_DIR + filename + ".res"
	# FLAG_BUNDLE_RESOURCES ensures sub-resources are packed into the binary file
	var err = ResourceSaver.save(res, path, ResourceSaver.FLAG_BUNDLE_RESOURCES)
	if err != OK:
		push_error("Failed to save: " + filename)

func _load_resource(filename: String, type_hint: String) -> Resource:
	var path = SAVE_DIR + filename + ".res"
	if FileAccess.file_exists(path):
		return ResourceLoader.load(path)
	
	# Factory Pattern: Return new instances if file missing
	match type_hint:
		"Course": return ResCourse.new()
		"Slot": return ResSlot.new()
		"Profile": return ResProfile.new()
		"Session": return ResSession.new()
		# "Settings" line REMOVED because it is handled separately below
	return null

# --- 1. COURSE SYSTEM ---

func save_course_progress(course_id: int, data: ResCourse):
	_save_resource(data, "coursedata_sv" + str(course_id))

func load_course_progress(course_id: int) -> ResCourse:
	return _load_resource("coursedata_sv" + str(course_id), "Course") as ResCourse

# --- 2. SLOT SYSTEM (COSMETICS) ---

func save_slot(slot_id: int, data: ResSlot):
	_save_resource(data, "gamesettings_sl" + str(slot_id))

func load_slot(slot_id: int) -> ResSlot:
	return _load_resource("gamesettings_sl" + str(slot_id), "Slot") as ResSlot

# --- 3. GLOBAL STATS & CURRENCY ---

func save_global_profile():
	if _profile_cache:
		_save_resource(_profile_cache, "user_profile") # Combines stats/currency/achieve

func load_global_profile() -> ResProfile:
	if _profile_cache: return _profile_cache
	
	# We use one file "user_profile" to hold currency, achievements, and stats
	# separating them into 3 files is possible but adds unnecessary IO overhead.
	# If you strictly want separate files, we can split this function.
	_profile_cache = _load_resource("user_profile", "Profile") as ResProfile
	return _profile_cache

# --- 4. ALL-IN-ONE (MID-RUN SAVE) ---

func save_all_in_one_session(data: ResSession):
	_save_resource(data, "allinone_data")

func load_all_in_one_session() -> ResSession:
	# Check if file exists first to know if "Continue" button should be active
	if FileAccess.file_exists(SAVE_DIR + "allinone_data.res"):
		return _load_resource("allinone_data", "Session") as ResSession
	return null

func delete_all_in_one_session():
	# Call this when they finish or die, so they can't resume a finished game
	var dir = DirAccess.open(SAVE_DIR)
	if dir: dir.remove("allinone_data.res")

# --- 5. GENERAL SETTINGS (Audio, etc) ---

# For general settings, Godot's ConfigFile is actually better than Resource
# because it handles versioning of settings easier, but we can wrap it.
func save_general_settings(config: Dictionary):
	var file = FileAccess.open(SAVE_DIR + "generalsettings.res", FileAccess.WRITE)
	file.store_var(config) # Stores binary dictionary

func load_general_settings() -> Dictionary:
	var path = SAVE_DIR + "generalsettings.res"
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		return file.get_var()
	return { "master_vol": 1.0, "music_vol": 1.0, "sfx_vol": 1.0 }
