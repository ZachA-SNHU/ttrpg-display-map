	  
# File: main_map.gd 
extends Node2D

# --- Existing Variables ---
@onready var map_sprite: Sprite2D = $MapSprite
@onready var token_layer = $TokenLayer # Make sure this Node2D exists in your scene tree
@onready var camera: Camera2D = $Camera2D
const TokenScene = preload("res://scenes/Tokens.tscn") # Ensure this path is correct

# --- State Variables ---
var is_panning = false
var currently_dragged_token: Token = null # Variable to hold the token being dragged

# --- Existing _ready() function ---
func _ready():
	var map_image_path = GlobalState.selected_map_path
	
	if map_image_path.is_empty():
		printerr("Error: no map image path provided by GlobalSteel")
		return
	var map_texture = load(map_image_path)
	#var map_image_path = "res://assets/maps/HiResMaps/MapLibrary_HiRes_17x22 2/MapLibrary_HiRes_17x22/Arctic_01B_CosyTavern_/Arctic_01B_CosyTavern_grid.jpg"
	#var map_texture = load(map_image_path)
	if map_texture:
		map_sprite.texture = map_texture
		map_sprite.rotation_degrees = 90.0
		print("Map loaded and rotated successfully!")
	else:
		printerr("Failed to load map texture at path: ", map_image_path)
	# Camera setup is handled by @onready now, no need for code here unless doing more setup


# --- Modified _unhandled_input for Token Placement ---
# Use unhandled_input so UI clicks don't place tokens later
func _unhandled_input(event):
	# Place a new token ONLY if:
	# 1. It's a left mouse click press
	# 2. We are NOT currently dragging another token (important!)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() and currently_dragged_token == null:
		#var new_token: Token = TokenScene.instantiate()
		#print("Map._unhandled_input: PLACING NEW Token ID: ", new_token.get_instance_id())
		# Calculate placement position relative to the token_layer
		#var placement_position = token_layer.to_local(get_global_mouse_position())
		#new_token.position = placement_position

		# Add the token to the scene under the token_layer
		#token_layer.add_child(new_token)
		# --- NEW: Check if clicking on an existing token AREA before placing ---
		var mouse_pos = get_global_mouse_position()
		var space_state = get_world_2d().direct_space_state # Get physics space
		var query = PhysicsPointQueryParameters2D.new()
		query.position = mouse_pos
		query.collide_with_areas = true # Make sure we check Area2D nodes
		# Optional but recommended: Define a specific physics layer for tokens
		# and set query.collision_mask = YOUR_TOKEN_LAYER_BIT
		var results = space_state.intersect_point(query)
		# --------------------------------------------------------------------

		# Check if the click DID NOT hit any relevant area AND we are not already dragging
		if results.is_empty() and currently_dragged_token == null:
			# --- Placement Logic ---
			print("Map._unhandled_input: Click hit empty space. PLACING NEW Token.")
			var new_token: Token = TokenScene.instantiate()
			# Print ID here if needed: print("  New Token ID: ", new_token.get_instance_id())
			var placement_position = token_layer.to_local(mouse_pos) # Use stored mouse_pos
			new_token.position = placement_position
			token_layer.add_child(new_token)
		# ---- NEW: Connect the signal from the new token ----
		# This connects the token's 'drag_started' signal to our '_on_token_drag_started' function.
		# .bind(new_token) passes the token itself as an argument to the handler function.
			new_token.drag_started.connect(_on_token_drag_started.bind(new_token))
		# --------------------------------------------------

		# Consume the event so nothing else processes this click (like the map itself if it had other click actions)
		#get_viewport().set_input_as_handled()


# --- Modified _input for Panning, Zooming, and Dragging ---
# Use _input for continuous actions like panning, zooming, and drag movement
func _input(event):
	#print ("inside _input(event)")
	# --- Motion Events ---
	if event is InputEventMouseMotion:
		# Panning Movement (only if middle mouse is held AND we are not dragging a token)
		if is_panning and currently_dragged_token == null:
			camera.offset -= event.relative / camera.zoom # Corrected: Divide by zoom for consistent feel

		# ---- NEW: Token Drag Movement ----
		# If a token is being dragged, update its position
		elif currently_dragged_token != null:
			# Set token position relative to its parent (token_layer)
			currently_dragged_token.position = token_layer.to_local(get_global_mouse_position())
		# ----------------------------------

	# --- Button Press/Release Events ---
	elif event is InputEventMouseButton:

		# Panning Start/Stop (Middle Mouse Button)
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.is_pressed():
				is_panning = true
				Input.set_default_cursor_shape(Input.CURSOR_DRAG)
			else:
				is_panning = false
				Input.set_default_cursor_shape(Input.CURSOR_ARROW)

		# ---- NEW: Token Drag Release ----
		# If the Left mouse button is RELEASED and we WERE dragging a token
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed():
			if currently_dragged_token != null:
				# Tell the token to reset its visual state
				currently_dragged_token.set_drag_visual(false)
				# Stop dragging - clear the reference
				currently_dragged_token = null
		# -----------------------------------

		# Zooming (Mouse Wheel) - Process after other button checks
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var zoom_amount = 0.1
			var min_zoom = Vector2(0.2, 0.2) # Use Vector2 for zoom
			var max_zoom = Vector2(5.0, 5.0) # Use Vector2 for zoom
			var zoom_factor = 1.0

			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom_factor = 1.0 - zoom_amount
			else: # Must be wheel down
				zoom_factor = 1.0 + zoom_amount

			# Store mouse position before zoom relative to viewport
			var mouse_pos_viewport = get_viewport().get_mouse_position()
			# Convert mouse position to global world coordinates
			var mouse_pos_global_before_zoom = camera.get_global_mouse_position()

			# Apply and clamp zoom
			var new_zoom = camera.zoom * zoom_factor
			new_zoom.x = clampf(new_zoom.x, min_zoom.x, max_zoom.x)
			new_zoom.y = clampf(new_zoom.y, min_zoom.y, max_zoom.y)
			camera.zoom = new_zoom

			# Get global position under mouse AFTER zoom applied
			var mouse_pos_global_after_zoom = camera.get_global_mouse_position()

			# Adjust camera offset to keep the point under the mouse stationary
			camera.offset += mouse_pos_global_before_zoom - mouse_pos_global_after_zoom


# --- NEW: Signal Handler Function ---
# This function is called when ANY token emits the 'drag_started' signal
func _on_token_drag_started(token: Token):
	print("Map._on_token_drag_started: Drag started for Token ID: ", token.get_instance_id())
	# Set this token as the one currently being dragged
	currently_dragged_token = token
	# The token itself already handled its visual change in its _on_input_event
# ------------------------------------

	
