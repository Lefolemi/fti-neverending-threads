extends GridContainer

# --- Node References ---
@onready var lbl_current_rank: Label = $Content/VBox/CurrentRank
@onready var vbox_achievements: VBoxContainer = $Content/VBox/AchievementList/VBox
@onready var lbl_to_go: Label = $Confirm/AchievementToGo
@onready var btn_close: Button = $Confirm/Close

# --- Achievement Data ---
# Organized by course for clean generation. 
# Replaced UTS/UAS with Midtest/Final Test, and Midtest target to 90%+.
var achievement_data = [
	{
		"course": "Manajemen Proyek Perangkat Lunak",
		"achievements": [
			{"title": "Project Kickoff", "desc": "Start a set in Elearning Mode.", "cr": 1},
			{"title": "Requirement Gathering", "desc": "Finish 7 sets in Elearning Mode.", "cr": 10},
			{"title": "Execution Protocol", "desc": "Pass 3 sets in Quizizz Mode.", "cr": 15},
			{"title": "Stakeholder Approved", "desc": "Pass Midtest with a good grade (90%+).", "cr": 40},
			{"title": "System Manager", "desc": "Pass 11 sets in Quizizz Mode.", "cr": 30},
			{"title": "Documentation Complete", "desc": "Finish all 14 sets in Elearning Mode.", "cr": 25},
			{"title": "Final Delivery", "desc": "Pass Final Test with perfect grades (100%).", "cr": 80}
		]
	},
	{
		"course": "Jaringan Komputer",
		"achievements": [
			{"title": "Link Established", "desc": "Start a set in Elearning Mode.", "cr": 1},
			{"title": "Subnetting Practice", "desc": "Finish 7 sets in Elearning Mode.", "cr": 10},
			{"title": "Routing Apprentice", "desc": "Pass 3 sets in Quizizz Mode.", "cr": 15},
			{"title": "Network Qualified", "desc": "Pass Midtest with a good grade (90%+).", "cr": 40},
			{"title": "Traffic Controller", "desc": "Pass 11 sets in Quizizz Mode.", "cr": 30},
			{"title": "Full Topology", "desc": "Finish all 14 sets in Elearning Mode.", "cr": 25},
			{"title": "Core Architect", "desc": "Pass Final Test with perfect grades (100%).", "cr": 80}
		]
	},
	{
		"course": "Keamanan Siber",
		"achievements": [
			{"title": "Activate Antivirus", "desc": "Start a set in Elearning Mode.", "cr": 1},
			{"title": "Vulnerability Scanning", "desc": "Finish 7 sets in Elearning Mode.", "cr": 10},
			{"title": "Into the Threat Surface", "desc": "Pass 3 sets in Quizizz Mode.", "cr": 15},
			{"title": "Integrity Holds", "desc": "Pass Midtest with a good grade (90%+).", "cr": 40},
			{"title": "The System Stands Guard", "desc": "Pass 11 sets in Quizizz Mode.", "cr": 30},
			{"title": "Security Audit", "desc": "Finish all 14 sets in Elearning Mode.", "cr": 25},
			{"title": "No False Alarm", "desc": "Pass Final Test with perfect grades (100%).", "cr": 80}
		]
	},
	{
		"course": "Pemrograman Web 1",
		"achievements": [
			{"title": "<head></head>", "desc": "Start a set in Elearning Mode.", "cr": 1},
			{"title": "", "desc": "Finish 7 sets in Elearning Mode.", "cr": 10},
			{"title": "body {}", "desc": "Pass 3 sets in Quizizz Mode.", "cr": 15},
			{"title": "page.load()", "desc": "Pass Midtest with good grades (90%+).", "cr": 40},
			{"title": "bindEvents()", "desc": "Pass 11 sets in Quizizz Mode.", "cr": 30},
			{"title": "console.log(\"tested\")", "desc": "Finish all 14 sets in Elearning Mode.", "cr": 25},
			{"title": "// this is going to work", "desc": "Pass Final Test with perfect grades (100%).", "cr": 80}
		]
	},
	{
		"course": "Mobile Programming",
		"achievements": [
			{"title": "New Project", "desc": "Start a set in Elearning Mode.", "cr": 1},
			{"title": "Read the Docs", "desc": "Finish 7 sets in Elearning Mode.", "cr": 10},
			{"title": "Hot Reload Hero", "desc": "Pass 3 sets in Quizizz Mode.", "cr": 15},
			{"title": "Product Checkpoint", "desc": "Pass Midtest with good grades (90%+).", "cr": 40},
			{"title": "Feature Complete-ish", "desc": "Pass 11 sets in Quizizz Mode.", "cr": 30},
			{"title": "Beta Tester", "desc": "Finish all 14 sets in Elearning Mode.", "cr": 25},
			{"title": "Production Ready", "desc": "Pass Final Test with perfect grades (100%).", "cr": 80}
		]
	},
	{
		"course": "Metodologi Riset",
		"achievements": [
			{"title": "Why the Sky is Blue?", "desc": "Start a set in Elearning Mode.", "cr": 1},
			{"title": "Literature Review", "desc": "Finish 7 sets in Elearning Mode.", "cr": 10},
			{"title": "Read the Literature", "desc": "Pass 3 sets in Quizizz Mode.", "cr": 15},
			{"title": "Critical Thinking", "desc": "Pass Midtest with good grade (90%+).", "cr": 40},
			{"title": "On the Trail", "desc": "Pass 11 sets in Quizizz Mode.", "cr": 30},
			{"title": "Data Gathered", "desc": "Finish all 14 sets in Elearning Mode.", "cr": 25},
			{"title": "More Questions than Answers", "desc": "Pass Final Test with perfect grades (100%).", "cr": 80}
		]
	},
	{
		"course": "Computer Vision",
		"achievements": [
			{"title": "Early Vision", "desc": "Start a set in Elearning Mode.", "cr": 1},
			{"title": "Feature Extraction", "desc": "Finish 7 sets in Elearning Mode.", "cr": 10},
			{"title": "Object Seeker", "desc": "Pass 3 sets in Quizizz Mode.", "cr": 15},
			{"title": "Biometrics", "desc": "Pass Midtest with good grade (90%+).", "cr": 40},
			{"title": "Found You", "desc": "Pass 11 sets in Quizizz Mode.", "cr": 30},
			{"title": "Dataset Annotated", "desc": "Finish all 14 sets in Elearning Mode.", "cr": 25},
			{"title": "Full Perception", "desc": "Pass Final Test with perfect grades (100%).", "cr": 80}
		]
	},
	{
		"course": "Pengolahan Citra Digital",
		"achievements": [
			{"title": "Pixel Boot", "desc": "Start a set in Elearning Mode.", "cr": 1},
			{"title": "Noise Reduction", "desc": "Finish 7 sets in Elearning Mode.", "cr": 10},
			{"title": "Image Pipeline", "desc": "Pass 3 sets in Quizizz Mode.", "cr": 15},
			{"title": "Correct Image", "desc": "Pass Midtest with good grade (90%+).", "cr": 40},
			{"title": "Continuous Filtering", "desc": "Pass 11 sets in Quizizz Mode.", "cr": 30},
			{"title": "Color Space Mapped", "desc": "Finish all 14 sets in Elearning Mode.", "cr": 25},
			{"title": "Final Reconstruction", "desc": "Pass Final Test with perfect grades (100%).", "cr": 80}
		]
	}
]

func _ready() -> void:
	btn_close.pressed.connect(_on_close_pressed)
	_generate_achievements()
	_update_overall_progress()

# --- Dynamic Generation ---

func _generate_achievements() -> void:
	# Clear whatever placeholder nodes are currently in the VBox
	for child in vbox_achievements.get_children():
		child.queue_free()
		
	# Build the list dynamically
	for course_data in achievement_data:
		# 1. Add a Course Header so it's not a massive 56-item wall of text
		var header = Label.new()
		header.text = "--- " + course_data["course"].to_upper() + " ---"
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		header.add_theme_color_override("font_color", Color.AQUA)
		header.add_theme_font_size_override("font_size", 16)
		vbox_achievements.add_child(header)
		
		# 2. Add each achievement for this course
		for ach in course_data["achievements"]:
			var ach_box = _create_achievement_box(ach["title"], ach["desc"], ach["cr"])
			vbox_achievements.add_child(ach_box)
			
		# 3. Add a spacer between courses
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 20)
		vbox_achievements.add_child(spacer)

# The improved "AchievementBox" generator
func _create_achievement_box(title: String, desc: String, credits: int) -> Control:
	var bg_panel = PanelContainer.new()
	bg_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var hbox = HBoxContainer.new()
	bg_panel.add_child(hbox)
	
	# 1. ICON (TextureRect)
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(64, 64)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# Placeholder color if no texture is loaded
	icon.modulate = Color(0.3, 0.3, 0.3) 
	hbox.add_child(icon)
	
	# 2. TEXT CONTAINER (VBox)
	var text_vbox = VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(text_vbox)
	
	# Title Label
	var lbl_title = Label.new()
	lbl_title.text = title + " (" + str(credits) + " cr)"
	lbl_title.add_theme_font_size_override("font_size", 14)
	lbl_title.add_theme_color_override("font_color", Color.GOLD)
	text_vbox.add_child(lbl_title)
	
	# Description Label
	var lbl_desc = Label.new()
	lbl_desc.text = desc
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_desc.add_theme_font_size_override("font_size", 12)
	lbl_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	text_vbox.add_child(lbl_desc)
	
	# 3. PERCENTAGE (Right aligned)
	var lbl_percent = Label.new()
	# Dummy logic for now: Randomly locked (0%) or completed (100%)
	var is_unlocked = randi() % 2 == 0
	lbl_percent.text = "100%" if is_unlocked else "0%"
	lbl_percent.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_percent.add_theme_color_override("font_color", Color.GREEN if is_unlocked else Color.DARK_GRAY)
	hbox.add_child(lbl_percent)
	
	return bg_panel

# --- Progress Logic ---

func _update_overall_progress() -> void:
	var total_achievements = 56 # 8 courses * 7 achievements
	var unlocked_count = 0 
	var current_credits = 0
	var total_credits = 1608 # Sum of all credits in this list
	
	# TODO: Replace with real check against Godot Save Data later. 
	# Using dummy random values for UI testing:
	unlocked_count = randi_range(5, 40)
	current_credits = unlocked_count * 15 # rough estimate
	
	var achievements_left = total_achievements - unlocked_count
	
	# Update the UI strings
	var rank_name = _get_rank_name_by_credits(current_credits)
	lbl_current_rank.text = "Rank\n" + rank_name + "\n" + str(achievements_left) + " to go"
	
	lbl_to_go.text = str(unlocked_count) + "/" + str(total_achievements) + " Unlocked!"

func _get_rank_name_by_credits(credits: int) -> String:
	if credits >= 1500: return "Summa Cum Laude"
	if credits >= 1000: return "Magistra"
	if credits >= 500: return "Senior"
	if credits >= 100: return "Sophomore"
	return "Freshman"

func _on_close_pressed() -> void:
	if GVar.last_scene != "":
		Load.load_res([GVar.last_scene], GVar.last_scene)
	else:
		push_warning("GVar.last_scene is empty!")
