extends ScrollContainer

# --- UI References ---
# We assume the ScrollContainer has a direct VBox child named "VBox"
@onready var content_vbox: VBoxContainer = $VBox

func populate_list(history: Array) -> void:
	# 1. Exam Mode Check: Hide and abort if in Exam Mode
	if GVar.current_mode == 2:
		self.hide()
		return
	else:
		self.show()
		
	# 2. Clear any existing review items
	for child in content_vbox.get_children():
		child.queue_free()
	
	# 3. Create new items based on history data
	for i in range(history.size()):
		var data = history[i]
		_create_review_item(i, data)

func _create_review_item(index: int, data: Dictionary) -> void:
	# --- 1. Root Container (PanelContainer) ---
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Optional: Add a stylebox or theme here if you want spacing/borders
	
	# --- 2. Layout (HBox) ---
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(hbox)
	
	# --- 3. Info Column (VBox) ---
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)
	
	# --- CLEAN THE TEXT FOR STATIC DISPLAY ---
	# Directly calling the new TextUtils function we just made!
	var clean_q_text = TextUtils.parse_spintax_first(data["q_text"])
	var clean_u_ans = TextUtils.parse_spintax_first(data["user_ans_text"])
	var clean_c_ans = TextUtils.parse_spintax_first(data["correct_ans_text"])

	# Label A: Question Text
	var lbl_question = Label.new()
	lbl_question.text = "Q%d: %s" % [index + 1, clean_q_text]
	lbl_question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Make it slightly gray to distinguish from answers
	lbl_question.modulate = Color(0.9, 0.9, 0.9) 
	info_vbox.add_child(lbl_question)
	
	# Label B: Your Answer
	var lbl_yours = Label.new()
	lbl_yours.text = "Your Answer: " + clean_u_ans
	# Color Code: Green if right, Red if wrong
	lbl_yours.modulate = Color.GREEN if data["is_correct"] else Color.RED
	info_vbox.add_child(lbl_yours)
	
	# Label C: Correct Answer (Only if wrong)
	if not data["is_correct"]:
		var lbl_right = Label.new()
		lbl_right.text = "Correct Answer: " + clean_c_ans
		lbl_right.modulate = Color.YELLOW
		info_vbox.add_child(lbl_right)
	
	# --- 4. Mark Button ---
	var btn_mark = Button.new()
	btn_mark.text = "MARK"
	btn_mark.custom_minimum_size = Vector2(80, 0)
	btn_mark.toggle_mode = false # We handle the toggle logic manually
	
	# Set Initial Color
	_update_mark_visual(btn_mark, data["marked"])
	
	# Connect Signal (Pass the button and the specific data entry)
	btn_mark.pressed.connect(_on_mark_pressed.bind(btn_mark, data))
	
	hbox.add_child(btn_mark)
	
	# Add the finished panel to the list
	content_vbox.add_child(panel)

# --- Interaction Logic ---

func _update_mark_visual(btn: Button, is_marked: bool) -> void:
	if is_marked:
		btn.modulate = Color.YELLOW
	else:
		btn.modulate = Color.WHITE

func _on_mark_pressed(btn: Button, data: Dictionary) -> void:
	# 1. Flip the boolean in memory
	data["marked"] = !data["marked"]
	
	# 2. Update the Button Color
	_update_mark_visual(btn, data["marked"])
	
	# 3. Save to CSV
	_save_mark_to_csv(data["csv_line_index"], data["marked"])

# --- CSV Saving Logic (Mirrors logic in Quiz Main) ---

func _save_mark_to_csv(line_index: int, new_state: bool) -> void:
	var path = "res://resources/csv/" + GVar.current_csv
	
	# 1. Read All Lines
	var file_read = FileAccess.open(path, FileAccess.READ)
	if not file_read:
		push_error("ResultList: Could not open CSV to save mark.")
		return
		
	var lines = []
	while not file_read.eof_reached():
		var row = file_read.get_csv_line()
		if row.size() > 0: lines.append(row)
	file_read.close()
	
	# 2. Modify the specific line
	if line_index < lines.size():
		var target_row = lines[line_index]
		if target_row.size() >= 6:
			target_row[5] = "1" if new_state else "0"
			lines[line_index] = target_row
	
	# 3. Write Back
	var file_write = FileAccess.open(path, FileAccess.WRITE)
	for row in lines:
		file_write.store_csv_line(row)
	file_write.close()
	
	print("Result Screen: Saved Mark status for Line ", line_index, " to: ", new_state)
