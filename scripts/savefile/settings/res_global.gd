extends Resource
class_name ResProfile

# Currency
@export var credits: int = 0 # Rank
@export var points: int = 0 # Shop

# Statistics (The "A LOT" list)
@export var total_playtime_seconds: float = 0.0
@export var total_logins: int = 0
@export var quizzes_started: int = 0
@export var quizzes_completed: int = 0
@export var questions_answered_total: int = 0
@export var questions_correct_total: int = 0

# Mode specific stats
@export var practice_sessions: int = 0
@export var exam_attempts: int = 0
@export var all_in_one_attempts: int = 0

# Achievements (Key = Achievement ID, Value = Unlocked Bool)
@export var achievements: Dictionary = {}
