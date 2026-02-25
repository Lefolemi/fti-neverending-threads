extends Node

# Game Information
var current_points: int = 0;
var current_credits: int = 0;
var unlocked_achievements: Array;
var shop_unlocks: Array;
var course_stats: Dictionary;
var player_statistics: Dictionary;

# General Information
var current_matkul: int = -1;
var current_mode: int = -1;
var current_course: int = -1;
var last_scene: String = "";

# General Settings
var music_volume: float = 1.0
var sfx_volume: float = 1.0

# Cosmetics Settings
var active_set: int = 1
var ui_color: int = 0
var invert_ui_color: bool = false
var curved_borders: bool = false
var ui_shadow: bool = false

# Colors are stored as hex strings in the JSON
var bg_color: String = "1e1e1e" 
var wallpaper_color: String = "ffffff" 
var wallpaper_opacity: float = 1.0
var wallpaper_path: String = ""
var wallpaper_motion: Vector2 = Vector2.ZERO
var wallpaper_scale: float = 1.0
var wallpaper_warp: float = 0.0

# Background Settings
var current_bg_color: Color = Color("121212")
var current_wp_color: Color = Color.WHITE
var current_wp_id: int = 0
var current_opacity: float = 1.0
var current_velocity: Vector2 = Vector2.ZERO
var current_scale: float = 1.0
var current_warp: float = 0.0

# Current Quiz Information
var current_csv: String = "";
var set_range_from: int = 0;
var set_range_to: int = 0;
var current_quiz_mode: int = 0;
var current_quiz_timer: int = 0;
var quiz_session_mode: int = 0;

# Quiz Options Information
var quiz_subset_qty: int = 0;
var quiz_randomize_set: bool;
var quiz_only_show_marked: bool;
var quiz_allow_stopwatch: bool;
var quiz_hide_questions: bool;
var quiz_hide_answers: bool;
var quiz_show_question_number: bool;
var quiz_score_count: bool;

# Quiz Session Information
var quiz_total_questions: int = 0;
var quiz_correct_count: int = 0;
var quiz_time_taken: int = 0;
var quiz_history: Array;
