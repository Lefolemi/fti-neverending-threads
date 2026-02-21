extends Node

@onready var music_player: AudioStreamPlayer = $Music
@onready var sfx_player: AudioStreamPlayer = $SFX

# Configuration
const MUSIC_PATH = "res://audio/music/"
var playlist: Array[String] = []
var is_muted: bool = false

func _ready() -> void:
	_scan_music_folder()
	# Start the first cycle
	_play_random_music()
	
	# Connect the signal so we know when a song finishes
	music_player.finished.connect(_on_music_finished)

# 1. Scan the folder for any .ogg or .mp3 files
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

# 2. The Play Logic
func _play_random_music():
	if playlist.is_empty(): return
	
	# Pick a random song
	var random_song = playlist[randi() % playlist.size()]
	var stream = load(random_song)
	
	music_player.stream = stream
	music_player.play()
	print("Now playing: ", random_song)

# 3. The Minecraft "Wait" Logic
func _on_music_finished():
	# Minecraft doesn't play the next song immediately.
	# We wait between 30 to 90 seconds.
	var wait_time = randf_range(30.0, 90.0)
	print("Music finished. Waiting ", wait_time, " seconds for next track...")
	
	await get_tree().create_timer(wait_time).timeout
	_play_random_music()

# --- THE MUTING TRICK ---

func toggle_mute(mute: bool):
	is_muted = mute
	# Instead of stopping the player, we mute the Audio Bus
	# 0 is the index of the "Master" bus
	AudioServer.set_bus_mute(0, is_muted)
