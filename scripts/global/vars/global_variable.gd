extends Node

# General Information
var current_matkul: int = 0;
var current_mode: int = 0;
var current_course: int = 0;
var last_scene: String = "";

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
