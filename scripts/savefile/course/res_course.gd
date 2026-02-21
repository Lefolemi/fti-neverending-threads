extends Resource
class_name ResCourse

# Logic: Array of 14 Dictionaries.
# Each Dict: { "unlocked": bool, "high_score": float, "best_time": float, "stars": int }
@export var sets: Array[Dictionary] = []

# Exam Gates
@export var midtest_unlocked: bool = false
@export var midtest_passed: bool = false
@export var midtest_score: float = 0.0

@export var finaltest_unlocked: bool = false
@export var finaltest_passed: bool = false
@export var finaltest_score: float = 0.0

# Constructor to ensure data isn't null when created
func _init():
	sets.resize(14)
	for i in range(14):
		sets[i] = {
			"unlocked": (i == 0), # Only Set 1 unlocked by default
			"high_score": 0.0,
			"best_time": 0.0,
			"stars": 0 # 0=None, 1=Pass, 2=Good, 3=Perfect
		}
