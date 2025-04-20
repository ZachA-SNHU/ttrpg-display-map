extends Node2D

# Get a reference to the MapSprite node.
# The '$' syntax is a shortcut for get_node().
# '@onready' ensures the node is ready before we try to access it.
@onready var map_sprite: Sprite2D = $MapSprite
@onready var token_layer = $TokenLayer
const TokenScene = preload("res://scenes/tokens/Tokens.tscn")
	
# This function runs once when the node enters the scene tree.
func _ready():
	# Define the path to your test map image.
	# Make sure this path matches where you put your map in the assets folder.
	var map_image_path = "res://assets/maps/HiResMaps/MapLibrary_HiRes_17x22 2/MapLibrary_HiRes_17x22/Arctic_01B_CosyTavern_/Arctic_01B_CosyTavern_grid.jpg" # <<< CHANGE THIS to your actual map file name

	# Load the image file as a texture
	var map_texture = load(map_image_path)

	# Check if loading was successful
	if map_texture:
		map_sprite.texture = map_texture
		map_sprite.rotation_degrees = 90.0
		print("Map loaded and rotated successfully!")
	else:
		printerr("Failed to load map texture at path: ", map_image_path)

	#====================================================================
	#begin handling Cameras script
	#====================================================================
	
@onready var camera: Camera2D = $Camera2D
var is_panning = false
func _input(event):
	# Handle panning start/stop with middle mouse button
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
		if event.is_pressed():
			is_panning = true
			Input.set_default_cursor_shape(Input.CURSOR_DRAG)
		else:
			is_panning = false
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)

	# Handle panning movement
	if event is InputEventMouseMotion and is_panning:
		# event.relative contains the amount the mouse moved since the last frame.
		# We move the camera offset in the opposite direction of the mouse movement.
		# We scale by zoom so panning feels consistent at different zoom levels.
		camera.offset -= event.relative * camera.zoom
		
	#Begin camera zoom logic
	if event is InputEventMouseButton:
		var zoom_amount = 0.1
		var min_zoom = 0.2
		var max_zoom = 5.0
		var zoom_factor = 1.0
		
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_factor = 1.0 - zoom_amount
		
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_factor = 1.0 + zoom_amount
			
		if zoom_factor != 1.0:
			var new_zoom = camera.zoom * zoom_factor
			#This clamps the zoom level to be within our set max/min bounds
			new_zoom.x = clampf(new_zoom.x, min_zoom, max_zoom)
			new_zoom.y = clampf(new_zoom.y, min_zoom, max_zoom)
			camera.zoom = new_zoom
