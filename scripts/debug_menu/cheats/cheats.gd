extends Node

const CHEAT_CODE = "AEZAKMI"
var input_buffer: String = ""

func _input(event: InputEvent) -> void:
	# Only listen for key presses (ignore holds/echoes)
	if event is InputEventKey and event.pressed and not event.echo:
		# Use unicode to get the actual character typed, and make it uppercase
		var typed_char = char(event.unicode).to_upper()
		
		# If it's a valid letter/character
		if typed_char != "":
			input_buffer += typed_char
			
			# Keep the buffer size manageable (only the last 7 characters)
			if input_buffer.length() > CHEAT_CODE.length():
				input_buffer = input_buffer.substr(input_buffer.length() - CHEAT_CODE.length())
			
			# Check if the buffer matches the cheat!
			if input_buffer == CHEAT_CODE:
				_activate_aezakmi()
				input_buffer = "" # Reset buffer after activation

func _activate_aezakmi() -> void:
	print("SYSTEM: CHEAT 'AEZAKMI' ACTIVATED!")
	
	# 1. Max Points
	GVar.current_points = 99999
	
	# 2. Max Playtime (Over 36 hours to guarantee time-related achievements)
	GVar.player_statistics["total_playtime"] = 130000.0 
	
	# 3. Unlock ALL course content (Set grades to 100.0 so they count as "Passed")
	for sub in GVar.course_stats.keys():
		for mode in ["Quizizz", "Elearning"]:
			for i in range(1, 15):
				GVar.course_stats[sub][mode]["Set " + str(i)]["grade"] = 100.0
			GVar.course_stats[sub][mode]["Midtest"]["grade"] = 100.0
			GVar.course_stats[sub][mode]["Final Test"]["grade"] = 100.0
			GVar.course_stats[sub][mode]["All in One"]["grade"] = 100.0
			
	# 4. Trigger the Achievement Evaluator
	# This will loop through everything, realize you meet all criteria, 
	# append them to GVar, update your rank to Magistra, and auto-save!
	if has_node("/root/AchievementManager"):
		get_node("/root/AchievementManager").evaluate_all()
	else:
		push_error("Cheats: Achievement AutoLoad not found!")

	# 5. Just in case, force SaveManager to save everything
	if has_node("/root/SaveManager"):
		get_node("/root/SaveManager").save_game()
		
	# (Optional) Fire a custom notification so the player knows it worked
	if has_node("/root/Notify"):
		get_node("/root/Notify").notify_achievement("CHEAT ACTIVATED", "HESOYAM... wait, wrong cheat. AEZAKMI!")
