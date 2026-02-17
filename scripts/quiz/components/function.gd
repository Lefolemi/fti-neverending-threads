extends Control

# Signals to notify Main
signal next_pressed
signal prev_pressed
signal flag_pressed
signal mark_pressed

@onready var btn_flag: Button = $Flag
@onready var btn_mark: Button = $Mark
@onready var btn_next: Button = $Next
@onready var btn_prev: Button = $Previous

func _ready() -> void:
	# Forward button clicks to Main
	btn_next.pressed.connect(func(): next_pressed.emit())
	btn_prev.pressed.connect(func(): prev_pressed.emit())
	btn_flag.pressed.connect(func(): flag_pressed.emit())
	btn_mark.pressed.connect(func(): mark_pressed.emit())

# --- Public API ---

func update_visuals(is_flagged: bool, is_marked: bool) -> void:
	btn_flag.modulate = Color.RED if is_flagged else Color.WHITE
	btn_mark.modulate = Color.YELLOW if is_marked else Color.WHITE

func update_nav_state(current_idx: int, total_qs: int, quiz_mode: int) -> void:
	# 1. VISIBILITY (Based on Mode)
	if quiz_mode == 0: # Quizizz
		btn_prev.visible = false
		btn_next.visible = false
		btn_flag.visible = false
		# We usually keep Mark visible even in Quizizz so users can save questions for later
		btn_mark.visible = true 
	else: # Elearning
		btn_prev.visible = true
		btn_next.visible = true
		btn_flag.visible = true
		btn_mark.visible = true

	# 2. ENABLE/DISABLE (Based on Index)
	if quiz_mode == 1:
		btn_prev.disabled = (current_idx == 0)
		btn_next.disabled = (current_idx == total_qs - 1)
