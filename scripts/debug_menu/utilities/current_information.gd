extends GridContainer

# Nodes
@onready var info_label: RichTextLabel = $Content/Information
@onready var close_button: Button = $Close

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	
	# THE MAGIC TRIGGER:
	# Whenever this menu is shown or hidden, this signal fires.
	visibility_changed.connect(_on_visibility_changed)

# --- The Logic ---

func _on_visibility_changed():
	# We only care if the menu just became VISIBLE.
	if visible:
		_refresh_display()

func _refresh_display():
	# We build a single long string using formatted text
	# BBCode is great here for coloring headers or values
	var txt = ""
	
	txt += "[b][u]GENERAL INFO[/u][/b]\n"
	txt += "Matkul ID: %d\n" % GVar.current_matkul
	txt += "Mode ID: %d\n" % GVar.current_mode
	txt += "Course ID: %d\n" % GVar.current_course
	txt += "Last Scene: %s\n" % GVar.last_scene
	txt += "\n"
	
	txt += "[b][u]QUIZ CONFIG[/u][/b]\n"
	txt += "CSV Path: [color=yellow]%s[/color]\n" % GVar.current_csv
	txt += "Range: %d - %d\n" % [GVar.set_range_from, GVar.set_range_to]
	txt += "Quiz Mode: %d\n" % GVar.current_quiz_mode
	txt += "Timer: %ds\n" % GVar.current_quiz_timer
	txt += "Result Mode: %s\n" % ("Immediate" if GVar.quiz_result_mode else "Normal")
	txt += "\n"
	
	txt += "[b][u]QUIZ FLAGS[/u][/b]\n"
	txt += "Random Set: %s\n" % _bool_str(GVar.quiz_randomize_set)
	txt += "Random Words: %s\n" % _bool_str(GVar.quiz_randomize_words)
	txt += "Only Marked: %s\n" % _bool_str(GVar.quiz_only_show_marked)
	txt += "Stopwatch: %s\n" % _bool_str(GVar.quiz_allow_stopwatch)
	txt += "Hide Quest: %s\n" % _bool_str(GVar.quiz_hide_questions)
	txt += "Hide Ans: %s\n" % _bool_str(GVar.quiz_hide_answers)
	txt += "Show Num: %s\n" % _bool_str(GVar.quiz_show_question_number)
	txt += "Score Count: %s\n" % _bool_str(GVar.quiz_score_count)
	
	info_label.text = txt

# Helper to make booleans look nicer (Green True / Red False)
func _bool_str(val: bool) -> String:
	if val:
		return "[color=green]ON[/color]"
	return "[color=red]OFF[/color]"

# --- Navigation Logic ---
func show_menu(node: String):
	hide()
	var target_menu = owner.get_node(node)
	if target_menu:
		target_menu.show()

func _on_close_pressed():
	show_menu("MenuVBox")
