extends Control

# Signals to notify Main
signal finish_pressed
signal restart_pressed
signal settings_pressed
signal jump_pressed

@onready var btn_finish: Button = $Finish
@onready var btn_restart: Button = $Restart
@onready var btn_settings: Button = $SessionSettingsButton
@onready var btn_jump: Button = $JumpQuestion

func _ready() -> void:
	# Forward connections
	btn_finish.pressed.connect(func(): finish_pressed.emit())
	btn_restart.pressed.connect(func(): restart_pressed.emit())
	btn_settings.pressed.connect(func(): settings_pressed.emit())
	btn_jump.pressed.connect(func(): jump_pressed.emit())

# --- Public API ---

func setup_visibility(session_mode: int, quiz_mode: int) -> void:
	# session_mode: 0=Normal, 1=Practice, 2=Exam
	# quiz_mode: 0=Quizizz, 1=Elearning
	
	# 1. Practice Mode Specifics
	if session_mode == 1: # Practice
		btn_restart.visible = true
		btn_settings.visible = true
	else: # Normal or Exam
		btn_restart.visible = false
		btn_settings.visible = false
		
	# 2. Jump Button Logic
	# Usually visible in Elearning, maybe hidden in strict Exam mode?
	# For now, let's keep it consistent with your previous logic:
	if quiz_mode == 0: # Quizizz
		btn_jump.visible = false
	else:
		btn_jump.visible = true
