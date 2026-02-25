extends PanelContainer

# --- Node References ---
@onready var lbl_what_gives: Label = $Margin/VBox/WhatGives
@onready var lbl_title: Label = $Margin/VBox/Title
@onready var lbl_desc: Label = $Margin/VBox/Description

# --- Queue System ---
var _queue: Array[Dictionary] = []
var _is_showing: bool = false

func _ready() -> void:
	# Hide the notification system entirely when the game boots
	modulate.a = 0.0
	hide()
	
	# Set labels to fully visible so they are ready for the first fade-in
	lbl_what_gives.modulate.a = 1.0
	lbl_title.modulate.a = 1.0
	lbl_desc.modulate.a = 1.0

# ==========================================
# --- PUBLIC METHODS (Call these from anywhere) ---
# ==========================================

func notify_achievement(ach_title: String, ach_desc: String) -> void:
	_queue.append({
		"type": "ACHIEVEMENT GET!",
		"title": ach_title,
		"desc": ach_desc
	})
	_process_queue()

func notify_rank_up(rank_name: String, rank_desc: String = "") -> void:
	var desc = rank_desc if rank_desc != "" else "You have unlocked new features!"
	_queue.append({
		"type": "RANK UP!",
		"title": "You have been promoted to " + rank_name,
		"desc": desc
	})
	_process_queue()

# ==========================================
# --- INTERNAL QUEUE LOGIC ---
# ==========================================

func _process_queue() -> void:
	# If an animation is already running, or there's nothing to show, do nothing.
	if _is_showing or _queue.is_empty():
		return
		
	_is_showing = true
	_show_next_notification()

func _show_next_notification() -> void:
	# Pop the oldest notification from the front of the line
	var current_notif = _queue.pop_front()
	
	# 1. Update the text
	lbl_what_gives.text = current_notif["type"]
	lbl_title.text = current_notif["title"]
	lbl_desc.text = current_notif["desc"]
	
	# If it's a Rank Up, you could change colors here!
	if current_notif["type"] == "RANK UP!":
		lbl_what_gives.add_theme_color_override("font_color", Color.YELLOW)
	else:
		lbl_what_gives.add_theme_color_override("font_color", Color.AQUA)
	
	# 2. Setup Tween
	var tween = create_tween()
	
	# If the panel is completely hidden, fade the WHOLE PANEL in
	if not visible:
		show()
		tween.tween_property(self, "modulate:a", 1.0, 0.3)
	else:
		# If panel is already visible (from a previous queue item), fade the LABELS in
		tween.tween_property(lbl_what_gives, "modulate:a", 1.0, 0.2)
		tween.parallel().tween_property(lbl_title, "modulate:a", 1.0, 0.2)
		tween.parallel().tween_property(lbl_desc, "modulate:a", 1.0, 0.2)

	# 3. Reading Time (Wait 3 seconds)
	tween.tween_interval(3.0)
	
	# 4. Outro branch
	tween.tween_callback(_on_read_time_finished)

func _on_read_time_finished() -> void:
	var tween = create_tween()
	
	if _queue.is_empty():
		# The queue is done. Fade out the entire panel and hide it.
		tween.tween_property(self, "modulate:a", 0.0, 0.3)
		tween.tween_callback(hide)
		tween.tween_callback(func(): _is_showing = false)
	else:
		# There are still notifications! Fade out JUST the labels.
		tween.tween_property(lbl_what_gives, "modulate:a", 0.0, 0.2)
		tween.parallel().tween_property(lbl_title, "modulate:a", 0.0, 0.2)
		tween.parallel().tween_property(lbl_desc, "modulate:a", 0.0, 0.2)
		
		# Once the text is invisible, loop back to swap the text and fade back in
		tween.tween_callback(_show_next_notification)
