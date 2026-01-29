extends Label

func _ready() -> void:
	# "application/config/version" is the path to that setting
	var current_version = ProjectSettings.get_setting("application/config/version", "0.0.0")

	# Update the text automatically
	text = "v" + str(current_version)
