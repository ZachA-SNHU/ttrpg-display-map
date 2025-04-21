# File: res://scenes/tokens/Token.gd 
extends Area2D
class_name Token # Makes it easy to reference this type

# Signal emitted when the token is clicked to start a drag
signal drag_started

# Optional signal if needed elsewhere, not strictly required for basic drag
# signal drag_stopped

@onready var visual: Sprite2D = $VisualSprite2D # CHANGE 'Visual' if your Sprite2D has a different name

# You don't need is_dragging here anymore, the map script handles the state

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

# Function the map script can call to change visual appearance (e.g., on drag stop)
func set_drag_visual(is_dragging: bool):
	if is_dragging:
		visual.modulate = Color(0.7, 0.7, 1.0, 0.8) # Example: Tint blueish and slightly transparent
	else:
		visual.modulate = Color(1.0, 1.0, 1.0, 1.0) # Reset to normal (white, opaque)

	
