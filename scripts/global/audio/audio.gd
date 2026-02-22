extends Node

@onready var music_player: AudioStreamPlayer = $Music
@onready var sfx_player: AudioStreamPlayer = $SFX

# Configuration
const MUSIC_PATH = "res://audio/music/"
var playlist: Array[String] = []
var unplayed_music: Array[String] = [] # This is our "Bag"
var last_played: String = "" # Track this to prevent back-to-back repeats across bags
var is_muted: bool = false

func _ready() -> void:
	music_player.bus = "Music"
	sfx_player.bus = "SFX"
	
	_scan_music_folder()
	_play_next_music()
	
	music_player.finished.connect(_on_music_finished)

# 1. Scan the folder
func _scan_music_folder():
	var dir = DirAccess.open(MUSIC_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and (file_name.ends_with(".ogg") or file_name.ends_with(".mp3")):
				playlist.append(MUSIC_PATH + file_name)
			file_name = dir.get_next()
	
	if playlist.is_empty():
		push_warning("AudioEngine: No music found in " + MUSIC_PATH)

# 2. The "Merciful" Play Logic
func _play_next_music():
	if playlist.is_empty(): return
	
	# If the bag is empty, refill and shuffle it
	if unplayed_music.is_empty():
		unplayed_music = playlist.duplicate()
		unplayed_music.shuffle() # Built-in Fisher-Yates shuffle
		
		# Edge Case: Prevent the new bag from starting with the last song of the old bag
		# Since we use pop_back(), the "first" song to play is at the end of the array.
		if unplayed_music.size() > 1 and unplayed_music.back() == last_played:
			# Swap it with the first element in the array to separate them
			var temp = unplayed_music[0]
			unplayed_music[0] = unplayed_music[unplayed_music.size() - 1]
			unplayed_music[unplayed_music.size() - 1] = temp
	
	# Pop from the back (O(1) operation, faster than pop_front)
	var next_song = unplayed_music.pop_back()
	last_played = next_song
	
	music_player.stream = load(next_song)
	music_player.play()
	print("Now playing: ", next_song, " | Remaining in bag: ", unplayed_music.size())

# 3. The Minecraft "Wait" Logic
func _on_music_finished():
	var wait_time = randf_range(30.0, 90.0)
	print("Music finished. Waiting ", wait_time, " seconds for next track...")
	
	await get_tree().create_timer(wait_time).timeout
	_play_next_music()

# --- THE MUTING TRICK ---
func toggle_mute(mute: bool):
	is_muted = mute
	AudioServer.set_bus_mute(0, is_muted)

# --- NEW: SFX Function ---
func play_sfx(sfx_path: String) -> void:
	if ResourceLoader.exists(sfx_path):
		sfx_player.stream = load(sfx_path)
		sfx_player.play()
	else:
		push_error("AudioEngine: Could not find SFX at " + sfx_path)
