# File: res://scenes/ui/CreatureInfoWindow.gd
# Purpose: Main window for displaying creature information, listing creatures, and managing active creature tabs.
extends Window

# --- Node References ---
# Ensure these paths or %unique_names match your CreatureInfoWindow.tscn structure.
@onready var all_creatures_list: ItemList = $MarginContainer/MainVBox/TopBarHBox/AllCreaturesList 
@onready var add_active_button: Button = $MarginContainer/MainVBox/TopBarHBox/AddActiveButton
@onready var active_creatures_tabs: TabContainer = $MarginContainer/MainVBox/ActiveCreaturesTab

# --- Scene Preload ---
const CREATURE_DISPLAY_PANEL_SCENE = preload("res://scenes/ui/CreatureDisplayPanel.tscn") # Verify this path!


func _ready():
	print(CREATURE_DISPLAY_PANEL_SCENE)
	
	#get_viewport().set_embedding_subwindows(false)
	self.mode=Window.MODE_WINDOWED
	# --- Load Creature Data ---
	if CreatureDatabase.all_creatures.is_empty():
		printerr("CreatureDatabase is empty in CreatureInfoWindow! Attempting to load...")
		CreatureDatabase.load_creatures_from_json() 
		if CreatureDatabase.all_creatures.is_empty():
			printerr("FATAL: Failed to load creatures for CreatureInfoWindow. Window will be non-functional.")
			if is_instance_valid(add_active_button):
				add_active_button.disabled = true
			return 

	

	# --- Connect Signals ---
	if is_instance_valid(add_active_button) and not add_active_button.is_connected("pressed", Callable(self, "_on_add_active_button_pressed")):
		add_active_button.pressed.connect(_on_add_active_button_pressed)

	if is_instance_valid(active_creatures_tabs):
		var tab_bar = active_creatures_tabs.get_tab_bar()
		if is_instance_valid(tab_bar): 
			if not tab_bar.is_connected("tab_close_pressed", Callable(self, "_on_tab_close_button_pressed")):
				tab_bar.tab_close_pressed.connect(_on_tab_close_button_pressed)
		else:
			printerr("CreatureInfoWindow: Could not get internal TabBar from ActiveCreaturesTabs in _ready().")
	
	# --- Configure Window and TabContainer ---
	title = "DM Creature Compendium"
	size = Vector2i(800, 700)
	
	# Set tab close display policy using integer values:
	# 0 = CLOSE_BUTTON_SHOW_NEVER
	# 1 = CLOSE_BUTTON_SHOW_ACTIVE_ONLY
	# 2 = CLOSE_BUTTON_SHOW_ALWAYS
	if is_instance_valid(active_creatures_tabs):
		print("ActiveCreaturesTab is valid")
		#active_creatures_tabs.tab_close_display_policy = CloseButtonDisplayPolicy # Set to CLOSE_BUTTON_SHOW_ACTIVE_ONLY
	populate_all_creatures_list()


func populate_all_creatures_list():
	print("Populate_all_creatures_list called")
	if not is_instance_valid(all_creatures_list):
		printerr("AllCreaturesList node is not ready or invalid in populate_all_creatures_list.")
		return
		
	all_creatures_list.clear()
	var creature_names: Array[String] = CreatureDatabase.get_all_creature_names()
	print("CreatureInfoWindow: Populating AllCreaturesList with ", creature_names.size()," names")
	for creature_name in creature_names:
		all_creatures_list.add_item(creature_name)
	
	if not creature_names.is_empty():
		all_creatures_list.select(0)
		all_creatures_list.ensure_current_is_visible()


func _on_add_active_button_pressed():
	print("Add button pressed")
	if not is_instance_valid(all_creatures_list): return

	var selected_indices = all_creatures_list.get_selected_items()
	if selected_indices.is_empty():
		print("No creature selected from the list to add to active tabs.")
		return

	var creature_name_to_add = all_creatures_list.get_item_text(selected_indices[0])
	var creature_data = CreatureDatabase.get_creature_by_name(creature_name_to_add)

	if creature_data.is_empty():
		printerr("Could not find data in database for creature: {creature_name_to_add}")
		return

	add_creature_to_tabs(creature_data)
	print("Added creature , creature_data, to active creatures tab")


func add_creature_to_tabs(creature_data: Dictionary):
	print("adding creature to tabs")
	if not is_instance_valid(active_creatures_tabs): 
		print("active creatures tab not valid")
		return

	var creature_name = creature_data.get("Name", "Unknown Creature")

	for i in range(active_creatures_tabs.get_tab_count()):
		if active_creatures_tabs.get_tab_title(i) == creature_name:
			active_creatures_tabs.current_tab = i
			print("Switched to existing tab for: {creature_name}")
			return

	var display_panel_instance = CREATURE_DISPLAY_PANEL_SCENE.instantiate()
	print("CIW:  Does display_panel_instance have method 'display_creature_data'?: ", display_panel_instance.has_method("display_creature_data"))
	if not is_instance_valid(display_panel_instance):
		printerr("Failed to instance CreatureDisplayPanel scene! Check the preload path and scene integrity.")
		return
	
	active_creatures_tabs.add_child(display_panel_instance)
	var new_tab_index = active_creatures_tabs.get_tab_count() - 1
	active_creatures_tabs.set_tab_title(new_tab_index, creature_name)
	active_creatures_tabs.current_tab = new_tab_index

	display_panel_instance.display_creature_data(creature_data)
	print("Added new tab for creature data")


func _on_tab_close_button_pressed(tab_idx: int):
	if not is_instance_valid(active_creatures_tabs): return

	var tab_title = active_creatures_tabs.get_tab_title(tab_idx)
	print("Close button pressed for tab '{tab_title}' (index {tab_idx}). TabContainer will handle removal.")
	# TabContainer automatically removes the child when its close button is pressed
	# if tab_close_display_policy is set appropriately. No manual removal needed here.

func popup_window():
	print("--- CreatureInfoWindow.gd: popup_window() CALLED (MINIMAL) ---")
	print("CreatureInfoWindow: popup_window() CALLED")
	self.popup_centered() 
	self.grab_focus()
	self.position = DisplayServer.screen_get_position(0) + Vector2i(50, 50)
	print("CreatureInfoWindow: after popup_centered. Visible: ", self.visible)

func _on_close_requested():
	print("Creature Info Window close requested (e.g., by OS window manager). Hiding window.")
	hide()
