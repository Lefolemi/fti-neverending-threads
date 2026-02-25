class_name MenuPage extends ScrollContainer

# Define a custom signal. 
# The MainMenu only listens for this. It doesn't care about the buttons inside.
signal item_selected(index: int, button_name: String)

@onready var vbox: VBoxContainer = $VBox

func _ready() -> void:
	# This script handles its own children. MainMenu doesn't need to know.
	for child in vbox.get_children():
		if child is Button:
			child.pressed.connect(_on_button_pressed.bind(child))
			# Store original text so we can easily restore it when unlocked
			child.set_meta("original_text", child.text)

func _on_button_pressed(button: Button) -> void:
	var idx = _get_index_from_name(button.name)
	# Bubble the signal up to the parent (MainMenu)
	item_selected.emit(idx, button.name)

# This logic is now isolated here. 
# If you change how buttons are named, you only fix it here.
func _get_index_from_name(btn_name: String) -> int:
	var regex = RegEx.new()
	regex.compile("\\d+")
	var result = regex.search(btn_name)
	if result:
		return int(result.get_string()) - 1
	return -1

# ==========================================
# --- MODULAR PROGRESSION LOCK LOGIC ---
# ==========================================

# 1. Call this ONLY for the ModeContainer (Quizizz, Elearning, Midtest, Final, All-in-One)
func update_mode_locks(course_name: String) -> void:
	var passed_sets = 0
	var is_final_passed = false
	
	if GVar.course_stats.has(course_name) and GVar.course_stats[course_name].has("Quizizz"):
		var stats = GVar.course_stats[course_name]["Quizizz"]
		
		# Count passed standard sets (1-14)
		for i in range(1, 15):
			var set_name = "Set " + str(i)
			if stats.has(set_name) and _is_passed(stats[set_name]["grade"]):
				passed_sets += 1
				
		# Check Final Test status
		if stats.has("Final Test"):
			is_final_passed = _is_passed(stats["Final Test"]["grade"])

	var has_amateur = GVar.unlocked_achievements.has("Amateur")

	for child in vbox.get_children():
		if child is Button:
			var idx = _get_index_from_name(child.name)
			
			# Assuming index 2=Midtest, 3=Final Test, 4=All in One
			if idx == 2:
				_apply_lock(child, passed_sets >= 7, "Midtest (Requires 7 Sets Passed)")
			elif idx == 3:
				_apply_lock(child, passed_sets >= 14, "Final Test (Requires 14 Sets Passed)")
			elif idx == 4:
				_apply_lock(child, is_final_passed and has_amateur, "All in One (Req: Final & Amateur Rank)")


# 2. Call this ONLY for the CourseContainer (Sets 1 - 14)
func update_course_locks(course_name: String, session_mode: int) -> void:
	var mode_str = "Quizizz" if session_mode == 0 else "Elearning"
	
	if not GVar.course_stats.has(course_name) or not GVar.course_stats[course_name].has(mode_str):
		return
		
	var stats = GVar.course_stats[course_name][mode_str]
	
	for child in vbox.get_children():
		if child is Button:
			var idx = _get_index_from_name(child.name) # 0 to 13
			var set_num = idx + 1
			var set_name = "Set " + str(set_num)
			
			if stats.has(set_name):
				# If the grade is anything other than "Locked", the button is playable
				var is_unlocked = (str(stats[set_name]["grade"]) != "Locked")
				
				# Fetch the CSV name we just saved in main_menu.gd
				var csv_name = str(child.get_meta("original_text"))
				var locked_text = csv_name + " (Locked)"
				
				_apply_lock(child, is_unlocked, locked_text)

# --- HELPERS ---

func _apply_lock(btn: Button, is_unlocked: bool, locked_text: String) -> void:
	if is_unlocked:
		btn.disabled = false
		btn.text = btn.get_meta("original_text")
		btn.modulate = Color.WHITE
	else:
		btn.disabled = true
		btn.text = locked_text
		btn.modulate = Color(0.4, 0.4, 0.4) 

func _is_passed(grade: Variant) -> bool:
	var g_str = str(grade)
	if g_str == "Locked" or g_str == "Unplayed":
		return false
	var g_float = float(grade)
	# Returns true if 50%+ OR if they got the Ɐ Grade (-1.0)
	return g_float >= 50.0 or g_float == -1.0
