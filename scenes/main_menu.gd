	  
# File: res://scenes/main_menu/MainMenu.gd
extends Control

@export_dir var base_map_directory: String = ""
# References to the UI nodes
@onready var select_map_button: Button = $SelectMapButton # Adjust path if nodes are nested
@onready var load_map_button: Button = $LoadMapButton
@onready var map_file_dialog: FileDialog = $MapFileDialog
@onready var selected_path_label: Label = $SelectedPathLabel # Optional label

# Path to the scene containing your map viewer
const MAIN_MAP_SCENE_PATH = "res://scenes/main_map.tscn" # MAKE SURE this path is correct!
const BASE_MAP_DIR = "res://assets/maps/HiResMaps/MapLibrary_HiRes_17x22 2/MapLibrary_HiRes_17x22/"

func _ready():
	# --- Configure FileDialog ---
	# --- Validate the exported directory path ---
	var is_path_valid = false
	if not base_map_directory.is_empty() and DirAccess.dir_exists_absolute(base_map_directory):
		print("Base map directory set via @export: ", base_map_directory)
		is_path_valid = true
		# Configure FileDialog using the exported variable
		map_file_dialog.root_subfolder = base_map_directory
	else:
		printerr("ERROR: 'Base Map Directory' is not set or invalid in the MainMenu node's Inspector!")
		printerr("  - Provided path: '", base_map_directory, "'")
		# Disable the button if the path is invalid, preventing errors later
		select_map_button.disabled = true
	# ------------------------------------------
	map_file_dialog.access = FileDialog.ACCESS_FILESYSTEM # Ensure correct access mode
	map_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE # We still need to select a FILE
	# Set initial filters (ensure these are still correct)
	map_file_dialog.clear_filters() # Clear any defaults first
	map_file_dialog.add_filter("*.png ; PNG Images")
	map_file_dialog.add_filter("*.jpg, *.jpeg ; JPEG Images")
	# ----------------------------
	# Connect signals from UI elements to functions in this script
	
	select_map_button.pressed.connect(_on_select_map_button_pressed)
	map_file_dialog.file_selected.connect(_on_map_file_dialog_file_selected)
	load_map_button.pressed.connect(_on_load_map_button_pressed)

	# Initially disable the load button
	load_map_button.disabled = true
	# Clear any path potentially leftover in global state from previous runs (optional)
	GlobalState.selected_map_path = ""


func _on_select_map_button_pressed():
	# Show the file dialog when the select button is pressed
	# Set the starting directory *each time* the button is pressed
	map_file_dialog.current_dir = BASE_MAP_DIR
	map_file_dialog.popup_centered() # Or .popup()


func _on_map_file_dialog_file_selected(path: String):
	# This function is called when the user selects a file in the dialog
	print("Selected file: ", path)

	# Store the selected path in our global state object
	GlobalState.selected_map_path = path

	# Update the optional label to show the selected path
	if selected_path_label:
		selected_path_label.text = path.get_file() # Show just the filename

	# Enable the load button now that a path is selected
	load_map_button.disabled = false


func _on_load_map_button_pressed():
	# Check if a valid path was actually selected (should be if button is enabled)
	if GlobalState.selected_map_path.is_empty():
		printerr("No map path selected!")
		# Optionally show an error message to the user
		return

	# --- Change to the main map scene ---
	# The _ready() function in main_map.gd will now use GlobalState.selected_map_path
	var error = get_tree().change_scene_to_file(MAIN_MAP_SCENE_PATH)
	if error != OK:
		printerr("Error changing scene to main map: ", error)
		# Optionally show an error message to the user

	
