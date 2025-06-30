# File: res://scripts/CreatureDatabase.gd
# Purpose: Autoload script to load and manage the creature database from a JSON file.
# Remember to add this to Project -> Project Settings -> Autoload with Node Name "CreatureDatabase".
extends Node

# This variable will hold all creature data after loading.
# It's an array where each element is expected to be a Dictionary representing a creature.
var all_creatures: Array[Dictionary] = []

# Path to your generated JSON database file.
# Ensure this path is correct and the file exists after running your conversion tool.
const DB_FILE_PATH = "res://data/creatures_db.json"

# Called when the node (and thus the Autoload) enters the scene tree (i.e., at game start).
func _ready():
	load_creatures_from_json()

# Loads creature data from the specified JSON file.
func load_creatures_from_json():
	all_creatures.clear() # Clear any existing data

	# Check if the database file exists
	if not FileAccess.file_exists(DB_FILE_PATH):
		printerr("Creature database JSON file not found at: {DB_FILE_PATH}")
		return

	# Open the file for reading
	var file = FileAccess.open(DB_FILE_PATH, FileAccess.READ)
	if file == null: # Check if opening failed
		printerr("Failed to open creature database JSON file: {DB_FILE_PATH}. Error: {FileAccess.get_open_error()}")
		return

	# Read the entire file content as text
	var json_string = file.get_as_text()
	file.close() # Close the file immediately after reading

	# Check if the file was empty
	if json_string.is_empty():
		printerr("Creature JSON database file is empty: {DB_FILE_PATH}")
		return

	# --- JSON Parsing using an instance (Godot 4) ---
	var json_parser = JSON.new() # Create an instance of the JSON class
	var error_code = json_parser.parse(json_string) # Parse the string

	# Check for parsing errors
	if error_code != OK:
		var err_line = json_parser.get_error_line()
		var err_msg = json_parser.get_error_message()
		printerr("Error parsing creature JSON data at line {err_line}: {err_msg} in file {DB_FILE_PATH}. Error code: {error_code}")
		return

	# Get the parsed data from the JSON parser instance
	var parsed_data_variant = json_parser.get_data()
	# -------------------------------------------------

	# --- Populate all_creatures by iterating and checking types ---
	if parsed_data_variant is Array:
		var temp_array = parsed_data_variant as Array # Get the generic array from the Variant
		var all_items_are_dictionaries = true

		for item in temp_array:
			if item is Dictionary:
				all_creatures.append(item) # This is type-safe now
			else:
				printerr("Type Mismatch during iteration: Found non-dictionary item in parsed JSON array. Item value: {item}, Type: {typeof(item)}")
				all_items_are_dictionaries = false
				# Optionally, you could break here if strict data integrity is required:
				# break 
		
		if all_items_are_dictionaries or not all_creatures.is_empty():
			print("Successfully processed {all_creatures.size()} dictionary items from JSON database: {DB_FILE_PATH}")
			# Optional: Debug print the first creature if loaded
			# if not all_creatures.is_empty():
			#    print("First creature example: ", all_creatures[0].get("Name", "N/A"))
		if not all_items_are_dictionaries:
			printerr("Warning: Some items in the JSON array were not dictionaries. The database might be incomplete or contain unexpected data types.")
			# If strictness is required and any item was not a dictionary, you might want to clear it:
			# all_creatures.clear() 
			# printerr("Database cleared due to non-dictionary items found.")
			
	else:
		printerr("Creature JSON data is not in the expected Array format. Root type found: {typeof(parsed_data_variant)}")
	# ----------------------------------------------------------

# --- Accessor Functions ---

# Returns an array of all creature names, sorted alphabetically.
func get_all_creature_names() -> Array[String]:
	var names: Array[String] = []
	for creature_dict in all_creatures: # Iterating over Array[Dictionary]
		if creature_dict.has("Name") and creature_dict["Name"] is String:
			names.append(creature_dict["Name"])
		else:
			# This warning helps identify issues in your JSON structure
			printerr("Warning: Found creature entry without a valid 'Name' string: {creature_dict}")
	names.sort()
	return names

# Returns the dictionary for a specific creature by its name.
# Returns an empty dictionary if the creature is not found.
func get_creature_by_name(creature_name: String) -> Dictionary:
	for creature_dict in all_creatures: # Iterating over Array[Dictionary]
		# Ensure Name exists and is a string before comparing
		if creature_dict.has("Name") and creature_dict["Name"] is String and creature_dict["Name"] == creature_name:
			return creature_dict
	# print(f"Creature not found by name: {creature_name}") # Optional: Debug if a specific lookup fails
	return {}
