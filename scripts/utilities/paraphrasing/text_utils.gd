class_name TextUtils extends RefCounted

# --------------------------------------------------------------------------
# MASTER FUNCTION: Process Text (Active Gameplay)
# --------------------------------------------------------------------------
# Call this from your UI. It handles Spintax first, then Synonyms.
static func process_text(raw_text: String, use_synonyms: bool = true) -> String:
	# Step 1: Resolve Spintax ({A|B}) randomly
	var text = parse_spintax(raw_text)
	
	# Step 2: Inject Synonyms (if enabled)
	if use_synonyms:
		# Using a 30% chance is usually the sweet spot for readability.
		text = SynonymDB.inject_synonyms(text, 0.3)
		
	return text

# --------------------------------------------------------------------------
# MASTER FUNCTION: Process Text Static (Result Screens / History)
# --------------------------------------------------------------------------
# Call this when you want a completely static, predictable string.
static func process_text_static(raw_text: String) -> String:
	# Only resolves Spintax (always picks the first option). No synonyms.
	return parse_spintax_first(raw_text)

# --------------------------------------------------------------------------
# SPINTAX LOGIC (Random - Active Gameplay)
# --------------------------------------------------------------------------
static func parse_spintax(text: String) -> String:
	if not "{" in text:
		return text
	
	var regex = RegEx.new()
	regex.compile("\\{([^{}]*)\\}")
	
	var result = text
	var iterations = 0
	
	while iterations < 100:
		var match_data = regex.search(result)
		if not match_data: break
			
		var inner_content = match_data.get_string(1)
		var options = inner_content.split("|")
		var chosen_option = options[randi() % options.size()]
		
		var start_pos = match_data.get_start()
		var end_pos = match_data.get_end()
		result = result.left(start_pos) + chosen_option + result.right(-end_pos)
		iterations += 1
		
	if iterations >= 100:
		push_warning("TextUtils: Spintax parsing hit 100 iteration limit: " + text)
		
	return result

# --------------------------------------------------------------------------
# SPINTAX LOGIC (Static - Always Picks First Option)
# --------------------------------------------------------------------------
static func parse_spintax_first(text: String) -> String:
	if not "{" in text:
		return text
	
	var regex = RegEx.new()
	regex.compile("\\{([^{}]*)\\}")
	
	var result = text
	var iterations = 0
	
	while iterations < 100:
		var match_data = regex.search(result)
		if not match_data: break
			
		var inner_content = match_data.get_string(1)
		var options = inner_content.split("|")
		
		# ALWAYS pick the first option instead of randi()
		var chosen_option = options[0]
		
		var start_pos = match_data.get_start()
		var end_pos = match_data.get_end()
		result = result.left(start_pos) + chosen_option + result.right(-end_pos)
		iterations += 1
		
	if iterations >= 100:
		push_warning("TextUtils: Spintax static parsing hit 100 iteration limit: " + text)
		
	return result
