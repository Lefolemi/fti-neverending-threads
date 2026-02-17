extends Control

# Signal to tell Main that a button was clicked
signal answer_selected(index: int)

# The buttons are children of VBox, based on your structure
@onready var buttons: Array[Button] = [
	$VBox/Answer1,
	$VBox/Answer2,
	$VBox/Answer3,
	$VBox/Answer4
]

func _ready() -> void:
	# Connect internal button signals
	for i in range(buttons.size()):
		buttons[i].pressed.connect(_on_btn_pressed.bind(i))

func _on_btn_pressed(idx: int) -> void:
	answer_selected.emit(idx)

# --- Public API called by Main ---

func load_buttons(q_data: Dictionary, quiz_mode: int, hide_text: bool) -> void:
	# Use processed options if available (Stable), otherwise use raw (Volatile)
	var options = q_data.get("processed_options", q_data["options"])
	
	var user_ans = q_data["user_answer"]
	var is_locked = q_data["is_locked"]
	
	for i in range(4):
		var btn = buttons[i]
		
		if i >= options.size():
			btn.hide()
			continue
		
		btn.show()
		
		# Use the pre-processed text if available, otherwise raw text
		var final_text = ""
		if options[i].has("processed_text"):
			final_text = options[i]["processed_text"]
		else:
			# Fallback (Shouldn't happen if Main does its job, but good for safety)
			final_text = TextUtils.process_text(options[i]["text"], false)
			
		btn.text = final_text if not hide_text else "???"
		
		# ... (Rest of function remains same: State, Colors, etc.)
		btn.disabled = false
		btn.modulate = Color.WHITE
		
		if quiz_mode == 1: 
			if user_ans == i: btn.modulate = Color(1, 1, 0)
		elif quiz_mode == 0:
			if is_locked:
				btn.disabled = true
				# Note: We must check 'is_correct' from the processed/raw option
				if options[i]["is_correct"]:
					btn.modulate = Color.GREEN
				elif user_ans == i:
					btn.modulate = Color.RED
				if user_ans == -1 and options[i]["is_correct"]:
					btn.modulate = Color.GREEN
