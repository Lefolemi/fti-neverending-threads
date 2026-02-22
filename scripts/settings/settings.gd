extends GridContainer

@onready var btn_general: Button = $Menu/General
@onready var btn_background: Button = $Menu/Background

@onready var scroll_general: ScrollContainer = $Content/General
@onready var scroll_background: ScrollContainer = $Content/Background

# Flags to track if a tab has been generated yet
var is_general_loaded: bool = false
var is_background_loaded: bool = false

func _ready() -> void:
	# Connect signals
	btn_general.pressed.connect(_on_general_tab_pressed)
	btn_background.pressed.connect(_on_background_tab_pressed)
	$Confirm/Cancel.pressed.connect(_on_cancel_pressed)
	
	# Open default tab
	_on_general_tab_pressed()

func _on_general_tab_pressed() -> void:
	scroll_general.show()
	scroll_background.hide()
	
	btn_general.modulate = Color.WHITE
	btn_background.modulate = Color(0.5, 0.5, 0.5)
	
	# LAZY LOAD: Only build the UI if it hasn't been built yet
	if not is_general_loaded:
		if scroll_general.has_method("init_tab"):
			scroll_general.init_tab()
		is_general_loaded = true

func _on_background_tab_pressed() -> void:
	scroll_general.hide()
	scroll_background.show()

	btn_background.modulate = Color.WHITE
	btn_general.modulate = Color(0.5, 0.5, 0.5)
	
	# LAZY LOAD: Wait until the user actually clicks this tab!
	if not is_background_loaded:
		if scroll_background.has_method("init_tab"):
			scroll_background.init_tab()
		is_background_loaded = true

func _on_cancel_pressed() -> void:
	if GVar.last_scene != "":
		Load.load_res([GVar.last_scene], GVar.last_scene)
	else:
		push_warning("GVar.last_scene is empty!")
