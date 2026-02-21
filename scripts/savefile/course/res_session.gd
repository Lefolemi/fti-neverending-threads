extends Resource
class_name ResSession

@export var course_id: int = 0
@export var current_question_index: int = 0
@export var current_score_right: int = 0
@export var current_score_wrong: int = 0
@export var timer_remaining: float = 0.0

# We need to save the shuffled order so they resume exactly where they left off
# Array of Dictionaries (The entire _question_deck)
@export var saved_deck_state: Array = []
