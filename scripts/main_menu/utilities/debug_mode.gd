extends Button

func _ready() -> void:
	_check_debug_unlock()

func _check_debug_unlock() -> void:
	# 1. Calculate current credits
	var total_credits = _calculate_current_credits()
	
	# 2. Magistra Rank threshold is 2818
	if total_credits < 2818:
		self.hide() # Only the best of the best see the debug menu
	else:
		self.show()

func _on_pressed() -> void:
	Load.load_res(["res://scenes/main/debug_menu/debug_menu.tscn"], "res://scenes/main/debug_menu/debug_menu.tscn")

# Replicating the calculation logic
func _calculate_current_credits() -> int:
	var total_cr = 0
	var path = "res://resources/csv/menu/achievement.csv"
	
	if not FileAccess.file_exists(path):
		return 0
		
	var file = FileAccess.open(path, FileAccess.READ)
	file.get_csv_line() # Skip header
	
	while not file.eof_reached():
		var line = file.get_csv_line()
		if line.size() >= 2:
			var title = line[0].strip_edges()
			var desc = line[1]
			
			# Check if title exists in GVar's unlocked list
			if GVar.unlocked_achievements.has(title):
				var split_desc = desc.split("(")
				if split_desc.size() > 1:
					var cr_val = split_desc[split_desc.size() - 1].to_int()
					total_cr += cr_val
	file.close()
	
	return total_cr
