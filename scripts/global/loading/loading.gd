extends Node

# --- Configuration ---
const LOADING_SCREEN_PATH = "res://scenes/loading/loadingscreen.tscn"

# --- State ---
var _loading_screen_instance: Control = null
var _target_scene_path: String = ""
var _resources_to_load: Array = []
var _loaded_resource_cache: Dictionary = {} # To keep references so they don't unload
var _is_loading: bool = false

func _process(_delta: float) -> void:
	if not _is_loading:
		return
	
	var total_progress: float = 0.0
	var all_finished: bool = true
	
	# Loop through all requested resources to check status
	for path in _resources_to_load:
		# Check status
		var progress_array = []
		var status = ResourceLoader.load_threaded_get_status(path, progress_array)
		
		match status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				# Add the partial progress (e.g. 0.5)
				if progress_array.size() > 0:
					total_progress += progress_array[0]
				_update_ui_subtext(path)
				all_finished = false
				
			ResourceLoader.THREAD_LOAD_LOADED:
				# It is done, so it contributes 1.0 (100%)
				total_progress += 1.0
				
			ResourceLoader.THREAD_LOAD_FAILED:
				push_error("Failed to load resource: " + path)
				# Consider it 'done' to prevent infinite loading loop
				total_progress += 1.0
				
			ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				# Maybe it's already loaded?
				total_progress += 1.0

	# Calculate average progress across ALL items
	# If we have 3 items, and 1 is done, 1 is half done, 1 is empty:
	# (1.0 + 0.5 + 0.0) / 3 = 0.5 (50% total)
	var final_percentage = total_progress / _resources_to_load.size()
	_update_ui_progress(final_percentage)
	
	if all_finished:
		_complete_loading()

# --- Public API ---

# Usage: Load.load_res(["res://player.tscn", "res://enemy.tscn"], "res://levels/level1.tscn")
func load_res(resources: Array, target_scene: String = "") -> void:
	if _is_loading:
		push_warning("Loader is already busy!")
		return
		
	_is_loading = true
	_resources_to_load = resources
	_target_scene_path = target_scene
	_loaded_resource_cache.clear()
	
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
		
		# --- THE FIX ---
		# Instead of adding it immediately, we queue it for the end of the frame.
		get_tree().root.call_deferred("add_child", _loading_screen_instance)
		
		# Note: The code below still works safely because _loading_screen_instance 
		# exists in memory, even if it hasn't visually appeared in the tree yet.
		_update_ui_subtext("Initializing...")
		_update_ui_progress(0.0)

func _update_ui_progress(value: float) -> void:
	if _loading_screen_instance:
		# Assuming your ProgressBar is named "LoadProgress"
		var bar = _loading_screen_instance.get_node_or_null("LoadProgress")
		if bar:
			bar.value = value * 100 # Convert 0-1 to 0-100

func _update_ui_subtext(full_path: String) -> void:
	if _loading_screen_instance:
		# Assuming your Label is named "LoadSub"
		var label = _loading_screen_instance.get_node_or_null("LoadSub")
		if label:
			# Only show filename, not full path (cleaner)
			var filename = full_path.get_file()
			label.text = "LOAD: " + filename

func _complete_loading() -> void:
	_is_loading = false
	
	# Retrieve loaded resources to keep them in memory
	# If we don't do this, they might be unloaded immediately if not used!
	for path in _resources_to_load:
		var res = ResourceLoader.load_threaded_get(path)
		_loaded_resource_cache[path] = res

	# Wait a tiny bit so the user sees the 100% bar (Optional)
	await get_tree().create_timer(0.2).timeout
	
	# Transition
	if _target_scene_path != "":
		# If the target scene itself was in the list, use the cached version!
		# This is instant because it's already in memory.
		if _loaded_resource_cache.has(_target_scene_path):
			get_tree().change_scene_to_packed(_loaded_resource_cache[_target_scene_path])
		else:
			# Fallback if target wasn't preloaded (will cause a small stutter)
			get_tree().change_scene_to_file(_target_scene_path)
	
	# Cleanup
	if _loading_screen_instance:
		_loading_screen_instance.queue_free()
		_loading_screen_instance = null
