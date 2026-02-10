extends Node

# --- Configuration ---
const LOADING_SCREEN_PATH = "res://scenes/loading/loadingscreen.tscn"

# --- State ---
var _loading_screen_instance: Control = null
var _target_scene_path: String = ""
var _resources_to_load: Array = []
var _loaded_resource_cache: Dictionary = {} 
var _is_loading: bool = false

func _process(_delta: float) -> void:
	if not _is_loading:
		return
	
	var total_progress: float = 0.0
	var all_finished: bool = true
	
	for path in _resources_to_load:
		var progress_array = []
		var status = ResourceLoader.load_threaded_get_status(path, progress_array)
		
		match status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				if progress_array.size() > 0:
					total_progress += progress_array[0]
				_update_ui_subtext(path)
				all_finished = false
			ResourceLoader.THREAD_LOAD_LOADED:
				total_progress += 1.0
			ResourceLoader.THREAD_LOAD_FAILED:
				push_error("Failed to load resource: " + path)
				total_progress += 1.0
			ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				total_progress += 1.0

	var final_percentage = total_progress / max(1, _resources_to_load.size()) # Added max(1) safety
	_update_ui_progress(final_percentage)
	
	if all_finished:
		_complete_loading()

# --- Public API ---

func load_res(resources: Array, target_scene: String = "") -> void:
	if _is_loading:
		push_warning("Loader is already busy!")
		return
		
	_is_loading = true
	_resources_to_load = resources
	_target_scene_path = target_scene
	_loaded_resource_cache.clear()
	
	# --- NEW: HIDE CURRENT SCENE INSTANTLY ---
	# This makes the Main Menu disappear immediately. 
	# The Background Autoload will be visible until the loading screen pops in.
	var current_scene = get_tree().current_scene
	if current_scene:
		current_scene.visible = false
	
	# 1. Spawn Loading Screen
	_spawn_loading_screen()
	
	# 2. Start Threaded Loading Request for each file
	for path in resources:
		ResourceLoader.load_threaded_request(path)

# --- Internals ---

func _spawn_loading_screen() -> void:
	var scene = load(LOADING_SCREEN_PATH)
	if scene:
		_loading_screen_instance = scene.instantiate()
		get_tree().root.call_deferred("add_child", _loading_screen_instance)
		_update_ui_subtext("Initializing...")
		_update_ui_progress(0.0)

func _update_ui_progress(value: float) -> void:
	# Added validity check to prevent errors if scene is deleted mid-load
	if is_instance_valid(_loading_screen_instance):
		var bar = _loading_screen_instance.get_node_or_null("LoadProgress")
		if bar:
			bar.value = value * 100 

func _update_ui_subtext(full_path: String) -> void:
	if is_instance_valid(_loading_screen_instance):
		var label = _loading_screen_instance.get_node_or_null("LoadSub")
		if label:
			var filename = full_path.get_file()
			label.text = "LOAD: " + filename

func _complete_loading() -> void:
	_is_loading = false
	
	for path in _resources_to_load:
		var res = ResourceLoader.load_threaded_get(path)
		_loaded_resource_cache[path] = res

	await get_tree().create_timer(0.2).timeout
	
	if _target_scene_path != "":
		if _loaded_resource_cache.has(_target_scene_path):
			get_tree().change_scene_to_packed(_loaded_resource_cache[_target_scene_path])
		else:
			get_tree().change_scene_to_file(_target_scene_path)
	
	if _loading_screen_instance:
		_loading_screen_instance.queue_free()
		_loading_screen_instance = null
