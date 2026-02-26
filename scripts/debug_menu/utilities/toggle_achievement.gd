extends GridContainer

@onready var close_button: Button = $Close
@onready var vbox_achievements: VBoxContainer = $Content/VBox/AchievementList/VBox

var category_names = [
	"Manajemen Proyek Perangkat Lunak", "Jaringan Komputer", 
	"Keamanan Siber", "Pemrograman Web 1", "Mobile Programming", 
	"Metodologi Riset", "Computer Vision", "Pengolahan Citra Digital", 
	"Time Related", "Challenge Related"
]

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	_generate_achievements()

# --- Navigation Logic ---
func show_menu(node: String) -> void:
	hide()
	var target_menu = owner.get_node_or_null(node)
	if target_menu:
		target_menu.show()

func _on_close_pressed() -> void:
	show_menu("MenuVBox")

# --- Async UI Generation ---
func _generate_achievements() -> void:
	for child in vbox_achievements.get_children():
		child.queue_free()
		
	await get_tree().process_frame 
		
	var current_cat_idx = -1
	
	# Fetch the master list directly from the new Autoload!
	var achievements = AchievementManager.parsed_achievements
	
	for i in range(achievements.size()):
		var ach = achievements[i]
		
		var cat_idx = 0
		if i < 56:   cat_idx = i / 7 
		elif i < 62: cat_idx = 8     
		else:        cat_idx = 9     
		
		if cat_idx != current_cat_idx:
			current_cat_idx = cat_idx
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(0, 10)
			vbox_achievements.add_child(spacer)
			
			var header = Label.new()
			header.text = "--- " + category_names[current_cat_idx].to_upper() + " ---"
			header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			header.add_theme_color_override("font_color", Color.AQUA)
			vbox_achievements.add_child(header)
			
		# Check if already unlocked
		var is_unlocked = GVar.unlocked_achievements.has(ach["title"])
		
		var btn = _create_debug_button(i, ach["title"], ach["desc"], is_unlocked)
		vbox_achievements.add_child(btn)
		
		if i % 4 == 0:
			await get_tree().process_frame

func _create_debug_button(index: int, title: String, desc: String, is_unlocked: bool) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(0, 60)
	btn.disabled = is_unlocked
	
	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE, 5)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(hbox)
	
	var text_vbox = VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(text_vbox)
	
	var lbl_title = Label.new()
	lbl_title.text = title if not is_unlocked else title + " (UNLOCKED)"
	lbl_title.add_theme_font_size_override("font_size", 14)
	lbl_title.add_theme_color_override("font_color", Color.GOLD if not is_unlocked else Color.GRAY)
	text_vbox.add_child(lbl_title)
	
	var lbl_desc = Label.new()
	lbl_desc.text = desc
	lbl_desc.add_theme_font_size_override("font_size", 12)
	text_vbox.add_child(lbl_desc)
	
	# We only need to pass the index, the button, and the label now.
	btn.pressed.connect(_on_force_unlock_pressed.bind(index, btn, lbl_title))
	
	return btn

# --- THE FORCE UNLOCK ENGINE ---
func _on_force_unlock_pressed(index: int, btn: Button, title_lbl: Label) -> void:
	# 1. Disable the button visually
	btn.disabled = true
	title_lbl.text += " (UNLOCKED)"
	title_lbl.add_theme_color_override("font_color", Color.GRAY)
	
	# 2. Force the underlying GVar Save Data to match the achievement
	_manipulate_save_data(index)
	
	# 3. Ask the Autoload to scan changes, add points, notify, and save!
	AchievementManager.evaluate_all()

# --- SAVE FILE MANIPULATION ---
func _manipulate_save_data(index: int) -> void:
	# Course Specific Data (0-55)
	if index < 56:
		var course_idx = index / 7
		var ach_type = index % 7
		var c_name = category_names[course_idx]
		var stats = GVar.course_stats[c_name]
		
		match ach_type:
			0: # Started any set
				stats["Quizizz"]["Set 1"]["grade"] = 50.0
			1: # Passed 7 sets
				for i in range(1, 8): stats["Quizizz"]["Set " + str(i)]["grade"] = 100.0
			2: # Passed 14 sets
				for i in range(1, 15): stats["Quizizz"]["Set " + str(i)]["grade"] = 100.0
			3: # Midtest 90+
				stats["Quizizz"]["Midtest"]["grade"] = 95.0
			4: # Passed 21 sets
				for i in range(1, 15): stats["Quizizz"]["Set " + str(i)]["grade"] = 100.0
				for i in range(1, 8): stats["Elearning"]["Set " + str(i)]["grade"] = 100.0
			5: # Passed 28 sets
				for i in range(1, 15): 
					stats["Quizizz"]["Set " + str(i)]["grade"] = 100.0
					stats["Elearning"]["Set " + str(i)]["grade"] = 100.0
			6: # Final Test 100
				stats["Quizizz"]["Final Test"]["grade"] = 100.0
				
	# Time Related Data (56-61)
	elif index < 62:
		var time_reqs = {56: 1200, 57: 7200, 58: 18000, 59: 43200, 60: 86400, 61: 129600}
		if GVar.player_statistics["total_playtime"] < time_reqs[index]:
			GVar.player_statistics["total_playtime"] = time_reqs[index]
			
	# Challenge Related (62-64)
	else:
		match index:
			62: # 1 AIO
				GVar.course_stats[category_names[0]]["Quizizz"]["All in One"]["grade"] = 100.0
			63: # 8 AIO
				for i in range(8):
					GVar.course_stats[category_names[i]]["Quizizz"]["All in One"]["grade"] = 100.0
			64: # 100% Complete
				for i in range(8):
					var c_name = category_names[i]
					for mode in ["Quizizz", "Elearning"]:
						for s in range(1, 15): GVar.course_stats[c_name][mode]["Set " + str(s)]["grade"] = 100.0
					GVar.course_stats[c_name]["Quizizz"]["Final Test"]["grade"] = 100.0
