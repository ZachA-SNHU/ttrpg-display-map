# File: res://scripts/utils/CreatureTextParser.gd
# Purpose: Contains the logic to parse the creature text file into structured data.
class_name CreatureTextParser
extends RefCounted # Use RefCounted so it can be instantiated easily

# Parses a single line like "STR 15 (+2), DEX 10 (+0), ..."
func _parse_abilities(ability_string: String) -> Dictionary:
	var abilities_dict = {}
	var parts = ability_string.split(",", false) # Don't skip empty parts initially
	for part in parts:
		var trimmed_part = part.strip_edges()
		if trimmed_part.is_empty():
			continue
		# Expects format like "STR 15 (+2)"
		var ability_detail = trimmed_part.split(" ", false, 2) # Split into 3 parts max: STAT, SCORE, (MOD)
		if ability_detail.size() >= 2: # Need at least STAT and SCORE
			var stat_name = ability_detail[0].strip_edges()
			var stat_value_mod = ability_detail[1].strip_edges()
			if ability_detail.size() > 2: # If modifier is separate
				stat_value_mod += " " + ability_detail[2].strip_edges()
			abilities_dict[stat_name] = stat_value_mod
	return abilities_dict

# Main parsing function
func parse_creature_file(file_path: String) -> Array[Dictionary]:
	var all_parsed_creatures: Array[Dictionary] = []
	var file = FileAccess.open(file_path, FileAccess.READ)

	if not FileAccess.file_exists(file_path) or file == null:
		printerr("Failed to open creature data file: ", file_path)
		if file:
			file.close()
		return all_parsed_creatures

	var current_creature_data: Dictionary = {}
	# current_major_section helps handle multi-line entries under a specific heading like Traits, Actions, Spellcasting
	var current_major_section_key: String = "" 
	var current_major_section_text_buffer: String = "" # Accumulates text for a multi-line section item

	while not file.eof_reached():
		var line = file.get_line().strip_edges()

		if line.is_empty():
			# If an empty line is found and we were buffering text for a major section item, finalize it.
			if not current_major_section_text_buffer.is_empty() and not current_major_section_key.is_empty():
				if not current_creature_data.has(current_major_section_key):
					current_creature_data[current_major_section_key] = []
				current_creature_data[current_major_section_key].append(current_major_section_text_buffer.strip_edges())
				current_major_section_text_buffer = ""
			continue # Skip empty lines

		# --- Creature Separator or New Creature ---
		if line == "---" or line.begins_with("Creature:"):
			# Finalize any buffered text for the previous creature's last section
			if not current_major_section_text_buffer.is_empty() and not current_major_section_key.is_empty():
				if not current_creature_data.has(current_major_section_key):
					current_creature_data[current_major_section_key] = []
				current_creature_data[current_major_section_key].append(current_major_section_text_buffer.strip_edges())
			current_major_section_text_buffer = "" # Reset buffer

			# Save the completed current_creature_data
			if not current_creature_data.is_empty():
				all_parsed_creatures.append(current_creature_data)
			
			current_creature_data = {} # Reset for new creature
			current_major_section_key = "" # Reset section key

			if line.begins_with("Creature:"):
				current_creature_data["Name"] = line.replace("Creature: ", "").strip_edges()
			# If it was "---", we just reset and wait for the next "Creature:" line
			continue

		if current_creature_data.is_empty(): # Skip lines if no current creature context yet
			continue

		# --- Section Headers (Traits, Actions, Legendary Actions, etc.) ---
		var known_section_headers = [
			"Traits", "Actions", "Legendary_Actions", "Lair_Actions", "Regional_Effects", "Lair_Traits",
			"Reactions", "Special_Actions", "Variant_Actions", "Spellcasting", "Innate Spellcasting"
		] # "Saving_Throws", "Skills", "Damage_Vulnerabilities", etc. are handled as key-value

		var found_section_header = false
		for header_base in known_section_headers:
			if line.begins_with(header_base + ":"):
				# Finalize previous section's buffered text if any
				if not current_major_section_text_buffer.is_empty() and not current_major_section_key.is_empty():
					if not current_creature_data.has(current_major_section_key):
						current_creature_data[current_major_section_key] = []
					current_creature_data[current_major_section_key].append(current_major_section_text_buffer.strip_edges())
				current_major_section_text_buffer = "" # Reset buffer

				current_major_section_key = line.trim_suffix(":").replace("_", " ").strip_edges()
				# Initialize as array for list items, or string for spellcasting blocks
				if current_major_section_key == "Spellcasting" or current_major_section_key == "Innate Spellcasting":
					# For spellcasting, the part after ":" is the first line of its description
					var parts_val = line.split(":", true, 1)
					if parts_val.size() > 1:
						current_creature_data[current_major_section_key] = parts_val[1].strip_edges()
					else:
						current_creature_data[current_major_section_key] = "" # Should have a value
				else:
					current_creature_data[current_major_section_key] = [] # For lists like Traits, Actions
				found_section_header = true
				break
		
		if found_section_header:
			continue # Processed the header, move to next line

		# --- List Items (under Traits, Actions, etc.) or Continuation of Text Blocks ---
		if not current_major_section_key.is_empty():
			if line.begins_with("- "): # An item in a list (Traits, Actions, etc.)
				# Finalize previous buffered item for this section
				if not current_major_section_text_buffer.is_empty():
					if not current_creature_data.has(current_major_section_key): # Should exist from header
						current_creature_data[current_major_section_key] = []
					current_creature_data[current_major_section_key].append(current_major_section_text_buffer.strip_edges())
				
				current_major_section_text_buffer = line.replace("- ", "").strip_edges() # Start new buffer
			elif current_major_section_key == "Spellcasting" or current_major_section_key == "Innate Spellcasting" or \
				 current_major_section_key == "Eye Rays" or current_major_section_key == "Challenge": # Multi-line text blocks
				# Append to the existing string for these sections
				if current_creature_data.has(current_major_section_key) and current_creature_data[current_major_section_key] is String:
					current_creature_data[current_major_section_key] += "\n" + line
				else: # Should have been initialized as string if it's one of these keys
					current_creature_data[current_major_section_key] = line # Start new if not string (error case)
			elif not current_major_section_text_buffer.is_empty(): # Continuation of a list item text
				current_major_section_text_buffer += "\n" + line
			# else: (This line is not a list item, and not a continuation of spellcasting, and buffer is empty)
			# This could be an error or the start of a new key-value, let the next block handle it.
			# This logic can get complex if text format is very loose.

			# Fall through if it's not a new list item or continuation of spellcasting,
			# to be caught by the key-value pair logic below.
			# However, this means we might lose current_major_section_key context if it's not a list.

		# --- Regular Key-Value Pairs ---
		# This should only run if not currently processing a multi-line item for a major section
		if current_major_section_text_buffer.is_empty() or not current_major_section_key in ["Traits", "Actions", "Legendary Actions", "Lair Actions", "Regional Effects", "Lair Traits", "Reactions", "Special Actions", "Variant Actions"]:
			var parts = line.split(":", true, 1)
			if parts.size() > 1:
				# Finalize any buffered text for the previous section *before* processing a new key-value
				if not current_major_section_text_buffer.is_empty() and not current_major_section_key.is_empty():
					if not current_creature_data.has(current_major_section_key):
						current_creature_data[current_major_section_key] = []
					current_creature_data[current_major_section_key].append(current_major_section_text_buffer.strip_edges())
				current_major_section_text_buffer = ""
				current_major_section_key = "" # Reset, this is a new top-level key

				var key = parts[0].replace("_", " ").strip_edges()
				var value = parts[1].strip_edges()

				if key == "Abilities":
					current_creature_data[key] = _parse_abilities(value)
				elif key == "Eye Rays": # Special case for Beholder-like multi-line block starting with a key
					current_creature_data[key] = value # Store first line
					current_major_section_key = key # For subsequent lines
				elif key == "Challenge" and "#" in value: # Handle comments in Challenge
					current_creature_data[key] = value.split("#")[0].strip_edges()
				else:
					current_creature_data[key] = value
			elif not current_major_section_key.is_empty() and \
				 (current_major_section_key == "Eye Rays"): # Multi-line text blocks that are not lists
				# Append to the existing string for these sections
				if current_creature_data.has(current_major_section_key) and current_creature_data[current_major_section_key] is String:
					current_creature_data[current_major_section_key] += "\n" + line

	# Add the last creature's last buffered section item
	if not current_major_section_text_buffer.is_empty() and not current_major_section_key.is_empty():
		if not current_creature_data.has(current_major_section_key):
			current_creature_data[current_major_section_key] = []
		current_creature_data[current_major_section_key].append(current_major_section_text_buffer.strip_edges())
	
	# Add the very last creature
	if not current_creature_data.is_empty() and (all_parsed_creatures.is_empty() or all_parsed_creatures.back() != current_creature_data):
		all_parsed_creatures.append(current_creature_data)

	file.close()
	print("Parsed {all_parsed_creatures.size()} creatures from text file.")
	return all_parsed_creatures
