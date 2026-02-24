extends GridContainer

signal closed # Emitted when Cancel is pressed

@onready var init_matkul_title: Label = $Content/Margin/VBox/MatkulTitle
@onready var init_course_title: Label = $Content/Margin/VBox/CourseSetTitle
@onready var init_grade: Label = $Content/Margin/VBox/Grade
@onready var init_score: Label = $Content/Margin/VBox/Score
@onready var init_time: Label = $Content/Margin/VBox/BestTime # --- NEW NODE ---

@onready var chk_allow_stopwatch: CheckBox = $Content/Margin/VBox/InitContent/AllowStopwatch
@onready var btn_quizizz: Button = $Content/Margin/VBox/InitContent/Buttons/QuizizzMode
@onready var btn_elearning: Button = $Content/Margin/VBox/InitContent/Buttons/ElearningMode

@onready var btn_start: Button = $Confirm/Start
@onready var btn_cancel: Button = $Confirm/Cancel

var _selected_session_type: int = 0 
var _current_course_name: String = ""
var _current_set_name: String = ""

func _ready() -> void:
	btn_cancel.pressed.connect(_on_cancel_pressed)
	btn_start.pressed.connect(_on_start_pressed)
	btn_quizizz.pressed.connect(_on_session_type_selected.bind(0))
	btn_elearning.pressed.connect(_on_session_type_selected.bind(1))

# Called by MainMenu right before showing this popup
func setup(course_index: int, course_names_cache: Array) -> void:
	var matkul_names = [
		"Manajemen Proyek Perangkat Lunak", 
		"Jaringan Komputer", 
		"Keamanan Siber", 
		"Pemrograman Web 1", 
		"Mobile Programming", 
		"Metodologi Riset", 
		"Computer Vision", 
		"Pengolahan Citra Digital"
	]
	
	# 1. Determine the Master Course Name
	if GVar.current_matkul >= 0 and GVar.current_matkul < matkul_names.size():
		_current_course_name = matkul_names[GVar.current_matkul]
		init_matkul_title.text = _current_course_name
	else:
		_current_course_name = "Unknown Subject"
		init_matkul_title.text = _current_course_name

	# 2. Determine the Set Name (Must exactly match the keys in player_save.json!)
	if GVar.current_mode == 0:
		_current_set_name = "Set " + str(course_index + 1)
		
		# For display, we still want the pretty CSV title if it exists
		if GVar.current_matkul >= 0 and GVar.current_matkul < course_names_cache.size():
			var set_names = course_names_cache[GVar.current_matkul]
			if course_index >= 0 and course_index < set_names.size():
				init_course_title.text = set_names[course_index]
			else:
				init_course_title.text = _current_set_name
		else:
			init_course_title.text = _current_set_name
			
	elif GVar.current_mode == 2:
		_current_set_name = "Midtest"
		init_course_title.text = "Midtest (UTS)"
	elif GVar.current_mode == 3:
		_current_set_name = "Final Test"
		init_course_title.text = "Final Test (UAS)"
	elif GVar.current_mode == 4:
		_current_set_name = "All in One"
		init_course_title.text = "All in One"

	# Sync the checkbox with your save file setting
	if chk_allow_stopwatch: 
		chk_allow_stopwatch.button_pressed = GVar.quiz_allow_stopwatch
	
	# 3. Trigger the stats display to update automatically
	_on_session_type_selected(0) 

func _on_session_type_selected(type_index: int) -> void:
	_selected_session_type = type_index
	if type_index == 0:
		btn_quizizz.modulate = Color.WHITE
		btn_elearning.modulate = Color(0.5, 0.5, 0.5)
	else:
		btn_elearning.modulate = Color.WHITE
		btn_quizizz.modulate = Color(0.5, 0.5, 0.5)
		
	# Update the grades every time they click a different mode button
	_update_stats_display()

# --- THE DATA FETCHER ---

func _update_stats_display() -> void:
	var mode_str = "Quizizz" if _selected_session_type == 0 else "Elearning"
	
	if GVar.course_stats.has(_current_course_name) and GVar.course_stats[_current_course_name][mode_str].has(_current_set_name):
		var stats = GVar.course_stats[_current_course_name][mode_str][_current_set_name]
		var saved_score = stats["grade"] # This holds the raw number (e.g., 100, 30) OR "Locked"/"Unplayed"
		var saved_time = stats["time"]
		
		# 1. Hide the speedrun elements by default
		chk_allow_stopwatch.hide()
		init_time.hide()
		
		# Check if it's a string meaning it hasn't been beaten yet
		if str(saved_score) == "Locked" or str(saved_score) == "Unplayed":
			init_grade.text = "-"
			init_score.text = "--%"
			init_time.text = "Best time: 00:00:00"
		else:
			# It's a real score! Convert to float just to be safe for math
			var numeric_score = float(saved_score)
			
			init_score.text = str(numeric_score) + "%"
			init_grade.text = _get_letter_grade(numeric_score, saved_time)
			init_time.text = "Best time: " + _format_time(saved_time)
			
			# 2. Reveal the speedrun UI only if they got a B (70%) or higher
			if numeric_score >= 70.0:
				chk_allow_stopwatch.show()
				init_time.show()
	else:
		init_grade.text = "Error"
		init_score.text = "Error"
		init_time.text = "Best time: Error"
		chk_allow_stopwatch.hide()
		init_time.hide()

# --- HELPER FUNCTIONS ---

func _get_letter_grade(percent: float, total_time: float) -> String:
	if percent >= 100:
		# Assuming an average set is ~15 questions. 15 * 3 seconds = 45 seconds for S Rank.
		# You can adjust this 45.0 threshold later if some sets are longer!
		if total_time > 0 and total_time <= 45.0: 
			return "S"
		else:
			return "A+"
	elif percent >= 90: return "A"
	elif percent >= 80: return "A-"
	elif percent >= 75: return "B+"
	elif percent >= 70: return "B"
	elif percent >= 65: return "B-"
	elif percent >= 50: return "C"
	elif percent >= 20: return "D"
	elif percent > 0:   return "E"
	else:
		return "Ɐ" # The Easter Egg!

func _format_time(time_sec: float) -> String:
	if time_sec <= 0.0:
		return "00:00:00"
		
	var mins = int(time_sec) / 60
	var secs = int(time_sec) % 60
	var msec = int((time_sec - int(time_sec)) * 100)
	
	return "%02d:%02d:%02d" % [mins, secs, msec]

# --- Interactions ---

func _on_cancel_pressed() -> void:
	hide()
	closed.emit() 

func _on_start_pressed() -> void:
	# Save their stopwatch preference permanently if they changed it
	if chk_allow_stopwatch and GVar.quiz_allow_stopwatch != chk_allow_stopwatch.button_pressed:
		GVar.quiz_allow_stopwatch = chk_allow_stopwatch.button_pressed
		SaveManager.save_game() 
	
	if GVar.current_mode >= 2:
		GVar.current_quiz_mode = 2 
	else:
		GVar.current_quiz_mode = _selected_session_type 

	GVar.current_csv = "matkul/course" + str(GVar.current_matkul) + ".csv"
	Load.load_res(["res://scenes/quiz/quiz_main.tscn"], "res://scenes/quiz/quiz_main.tscn")
