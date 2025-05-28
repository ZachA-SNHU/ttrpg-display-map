# File: res://scenes/tokens/Token.gd 
extends Area2D
class_name Token 

# Signal emitted when the token is clicked to start a drag
signal drag_started



@onready var visual: Sprite2D = $VisualSprite2D 
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


# Called by Godot when an input event occurs within this Area2D's shape
func _on_input_event(viewport, event, shape_idx):
	
	# Check if it's the left mouse button being pressed down
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		print("Token._on_input_event: Clicked on Token ID: ", self.get_instance_id())
		# Emit the signal to notify the map script
		emit_signal("drag_started")
		# Provide immediate visual feedback
		set_drag_visual(true)
		# Consume the event so the map doesn't immediately place a *new* token
		get_viewport().set_input_as_handled()
	#Right click for deleting tokens
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
		queue_free()
		get_viewport().set_input_as_handled()
# --- NEW HELPER FUNCTION ---
# Allows external scripts (like main_map.gd) to set the token's texture
func set_visual_texture(texture_resource: Texture2D):
	# --- ADD DETAILED PRINTS TO THIS FUNCTION ---
	print("--- Token.set_visual_texture ---")
	print("  - Attempting to set texture on Token ID: ", self.get_instance_id())
	print("  - Is visual node valid?: ", is_instance_valid(visual))
	print("  - Is texture_resource valid?: ", is_instance_valid(texture_resource))
	print("  - visual node reference: ", visual)
	print("  - texture_resource received: ", texture_resource)

	if is_instance_valid(visual) and is_instance_valid(texture_resource):
		print("  - Validation PASSED. Assigning texture to visual.texture.")
		visual.texture = texture_resource
		print("  - Assignment complete. Visual texture should now be: ", visual.texture)
	else:
		printerr("  - Validation FAILED. Could not assign texture.")
		if not is_instance_valid(visual):
			printerr("    - Reason: Visual node ($VisualSprite2D) reference is invalid!")
		if not is_instance_valid(texture_resource):
			printerr("    - Reason: Received texture resource is invalid!")
	print("--- End Token.set_visual_texture ---")
# ------------------------------------------
# Function the map script can call to change visual appearance (e.g., on drag stop)
func set_drag_visual(is_dragging: bool):
	if is_dragging:
		visual.modulate = Color(0.7, 0.7, 1.0, 0.8) # Example: Tint blueish and slightly transparent
	else:
		visual.modulate = Color(1.0, 1.0, 1.0, 1.0) # Reset to normal (white, opaque)

func set_token_scale(new_scale_vector: Vector2):
	if is_instance_valid(visual) and is_instance_valid(collision_shape):
		visual.scale = new_scale_vector
		
		if collision_shape.shape is CircleShape2D and visual.texture:
			collision_shape.scale = new_scale_vector
