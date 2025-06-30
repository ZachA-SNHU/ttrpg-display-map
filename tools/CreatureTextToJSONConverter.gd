# File: res://tools/ConvertCreaturesToJSON.gd
# Purpose: A tool script to convert the creature text file to a JSON database.
# Add '@tool' at the very top of this script.
@tool
extends EditorScript

const TEXT_FILE_PATH = "res://tools/CreatureCompendium.txt"  # Path to your source text file
const JSON_OUTPUT_PATH = "res://data/creatures_db.json" # Path to save the JSON database
const PARSER_SCRIPT_PATH = "res://scripts/utils/CreatureTextParser.gd" # Path to your parser class

# This function will be called when you run the script from Godot's Script Editor
# (File -> Run, or Ctrl+Shift+X when this script is active)
func _run():
	print("Starting creature data conversion to JSON...")

	# Ensure the output directory exists
	var output_dir = JSON_OUTPUT_PATH.get_base_dir()
	if not DirAccess.dir_exists_absolute(output_dir):
		print("Creating output directory: ", output_dir)
		var err = DirAccess.make_dir_recursive_absolute(output_dir)
		if err != OK:
			printerr("Failed to create output directory: ", output_dir, " Error: ", err)
			return

	var ParserClass = load(PARSER_SCRIPT_PATH)
	if ParserClass == null:
		printerr("Failed to load CreatureTextParser script at: ", PARSER_SCRIPT_PATH)
		return

	var parser_instance = ParserClass.new()
	var creature_data_array: Array[Dictionary] = parser_instance.parse_creature_file(TEXT_FILE_PATH)

	if creature_data_array.is_empty():
		printerr("No creature data was parsed. Aborting JSON save.")
		return

	var json_string = JSON.stringify(creature_data_array, "\t", true) # Use "\t" for indentation, true for sort_keys

	if json_string.is_empty() and not creature_data_array.is_empty(): # Check if stringify failed
		printerr("JSON.stringify returned an empty string for non-empty data. Possible error in data structure for JSON.")
		return
	elif json_string.is_empty() and creature_data_array.is_empty():
		print("Parsed data was empty, so JSON output is also empty.")
		json_string = "[]" # Write an empty JSON array for consistency

	var file = FileAccess.open(JSON_OUTPUT_PATH, FileAccess.WRITE)
	if file == null:
		var err_code = FileAccess.get_open_error()
		printerr("Failed to open/create JSON output file: {JSON_OUTPUT_PATH}. Error: {err_code}")
		return

	file.store_string(json_string)
	file.close()

	print("Successfully converted and saved ", creature_data_array.size()," creatures to: ",JSON_OUTPUT_PATH)
	print("Please check the output file for correctness.")
	print("You may need to briefly click outside Godot and back, or use Project -> Reload Current Project for the new JSON file to be fully recognized by the FileSystem dock if it's the first time creating it.")
