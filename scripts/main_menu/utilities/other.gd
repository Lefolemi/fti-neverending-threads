extends GridContainer

@onready var decks_button: Button = $Decks # Make sure the node name matches

func _ready() -> void:
	_check_unlock_status()

func _check_unlock_status() -> void:
	# 1. Calculate current credits based on achievements
	var total_credits = _calculate_current_credits()

	# 2. Expert Rank threshold is 2000
	if total_credits < 2000:
		# Option A: Hide the button entirely
		decks_button.hide()

		# Option B: Keep it visible but disabled with a tooltip (Better UX)
		# decks_button.disabled = true
		# decks_button.tooltip_text = "Unlocks at Expert Rank (2000 Credits). Current: %d" % total_credits
	else:
		decks_button.show()
		# decks_button.disabled = false

func _on_decks_pressed() -> void:
	GVar.last_scene = "res://scenes/main/main_menu/main_menu.tscn"
	Load.load_res(["res://scenes/utilities/csv/deck_view.tscn"], "res://scenes/utilities/csv/deck_view.tscn")

# This logic replicates the credit calculation from your Achievement script
func _calculate_current_credits() -> int:
	var total_cr = 0
	
	# We need the achievement data to know how much each is worth
	# If GVar doesn't already store total credits, we calculate it via the titles
	# saved in GVar.unlocked_achievements
	
	# Note: Since your Achievement script already syncs unlocked titles to 
	# GVar.unlocked_achievements, we just need to map those titles to their credit values.
	
	# To avoid re-parsing the CSV every time, you could alternatively 
	# have your Achievement script save 'GVar.total_credits' directly.
	# But for now, we'll parse it to be safe:
	
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
			
			# If this specific achievement title is in our unlocked list
			if GVar.unlocked_achievements.has(title):
				# Extract credit from "Description (50)"
				var split_desc = desc.split("(")
				if split_desc.size() > 1:
					var cr_val = split_desc[split_desc.size() - 1].to_int()
					total_cr += cr_val
	file.close()
	
	return total_cr
