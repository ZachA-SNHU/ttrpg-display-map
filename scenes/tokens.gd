extends Area2D
class_name Token

var is_dragging = false

#Signal to notify the map when dragging starts
signal drag_started
#signal to notify the map when dragging stops
signal drag_stopped

#variable to track if this token is the one currently being moved globally
var is_being_dragged_globally = false

@onready var visual = $VisualSprite2D
func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			#start dragging when left mouse button is pressed down on the token
			#is_dragging = true
			emit_signal("drag_started")
			#visually indicate what is selected/being dragged
			visual.modulate = Color(0.7, 0.7, 1.0) #gives it a blueish tint
			
			#IMPORTANT: We prevent the map click from placing a NEW token when clicking ON a token
			get_viewport().set_input_as_handled()
			#No longer handling the release, as the map will do it for us
		#else:
			#stop dragging when left mouse button is released (while the cursor is still over the token)
			if is_dragging:
					is_dragging = false
					#reset the visual indication
					visual.modulate = Color(1.0, 1.0, 1.0) #resets the tint
func _input(event):
	
	#only process if  this token is currently being dragged
	if is_dragging:
		#check if the event is mouse motion
		if event is InputEventMouseMotion:
			#update the tokens position to follow the mouse cursor globally
			# we need the position relative to the parent (TokenLayer)
			#Get parent reference, assuming its a Node2d or derived type
			var parent_node = get_parent()
			if parent_node is Node2D:
				#convert the global mouse position to the parents local coordinate space
				global_position = parent_node.to_local(get_global_mouse_position())
			else:
				#fallback or handle the error if the parent isnt a Node2d
				#for simplicity, using global pos might work if scaling/rotation isn't complex
				global_position = get_global_mouse_position()
				
		#handle the case where mouse button is released anywhere while dragging
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed():
			is_dragging = false
			#Reset visual indication
			$Visual.modulate = Color(1.0, 1.0, 1.0) #resets the tint
			#
func set_drag_visual(is_dragging):
	if is_dragging:
		visual.modulate = Color(0.7, 0.7, 1.0)
	else:
		visual.modulate = Color(1.0, 1.0, 1.0)
		is_being_dragged_globally = false #ensuring the state is reset
