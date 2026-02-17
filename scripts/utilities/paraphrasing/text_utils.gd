class_name TextUtils extends RefCounted

# --------------------------------------------------------------------------
# MASTER FUNCTION: Process Text
# --------------------------------------------------------------------------
# Call this from your UI. It handles Spintax first, then Synonyms.
static func process_text(raw_text: String, use_synonyms: bool = true) -> String:
	# Step 1: Resolve Spintax ({A|B})
	var text = parse_spintax(raw_text)
	
	# Step 2: Inject Synonyms (if enabled)
	if use_synonyms:
		# Using a 30% chance is usually the sweet spot for readability.
		text = SynonymDB.inject_synonyms(text, 0.3)
		
	return text

# --------------------------------------------------------------------------
# SPINTAX LOGIC (Robust & Supports Nesting)
# --------------------------------------------------------------------------
static func parse_spintax(text: String) -> String:
	# 1. Quick exit if there's no spintax (saves CPU)
	if not "{" in text:
		return text
	
	var regex = RegEx.new()
	# This pattern looks for the INNERMOST brackets.
	# Example: In "{A|{B|C}}", it will find "{B|C}" first.
	regex.compile("\\{([^{}]*)\\}")
	
	var result = text
	var iterations = 0
	
	# 2. Loop until no more brackets are found
	# (We cap it at 100 just in case you miss a bracket in your CSV and cause an infinite loop)
	while iterations < 100:
		var match_data = regex.search(result)
		
		# If no more matches, we are done!
		if not match_data:
			break
			
		# Extract the inner options
		var inner_content = match_data.get_string(1) # e.g., "Option A|Option B"
		var options = inner_content.split("|")
		
		# Pick one at random
		var chosen_option = options[randi() % options.size()]
		
		# 3. Safe Replacement
		# We use slicing (left/right) instead of .replace() because if you have 
		# identical spintax blocks twice, .replace() might accidentally overwrite both at once.
		var start_pos = match_data.get_start()
		var end_pos = match_data.get_end()
		
		result = result.left(start_pos) + chosen_option + result.right(-end_pos)
		
		iterations += 1
		
	if iterations >= 100:
		push_warning("TextUtils: Spintax parsing hit the 100 iteration limit! Check your CSV for broken brackets: " + text)
		
	return result
