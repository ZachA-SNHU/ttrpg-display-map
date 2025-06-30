# File: res://scenes/ui/CreatureDisplayPanel.gd
# Purpose: Displays the detailed statistics of a single creature.
# This script is attached to the root node of CreatureDisplayPanel.tscn (e.g., a ScrollContainer).
extends ScrollContainer # Or PanelContainer, adjust if your root node is different

# --- Node References ---
# Use '%' for unique names if you've set them in the editor,
# otherwise, use full paths like $MarginContainer/StatsContainer/NameLabel.
# Ensure these node names/paths EXACTLY match your CreatureDisplayPanel.tscn scene structure.

@onready var name_label: RichTextLabel = %NameLabel
@onready var size_label: Label = %SizeLabel
@onready var ac_label: Label = %ACLabel
@onready var hp_label: Label = %HPLabel
@onready var speed_label: Label = %SpeedLabel
#@onready var abilities_grid: GridContainer = %AbilitiesGrid
@onready var abilities_rich_text_label: RichTextLabel = %AbilitiesRichTextLabel # For formatted abilities

@onready var senses_label: Label = %SensesLabel
@onready var languages_label: Label = %LanguagesLabel
@onready var challenge_label: Label = %ChallengeLabel
@onready var skills_label: Label = %SkillsLabel
@onready var saving_throws_label: Label = %SavingThrowsLabel
@onready var damage_vulnerabilities_label: Label = %DamageVulnerabilitiesLabel
@onready var damage_resistances_label: Label = %DamageResistancesLabel
@onready var damage_immunities_label: Label = %DamageImmunitiesLabel
@onready var condition_immunities_label: Label = %ConditionImmunitiesLabel

# Title Labels for sections (to hide/show them)
@onready var traits_title_label: Label = %TraitsTitleLabel
@onready var actions_title_label: Label = %ActionsTitleLabel
@onready var special_actions_title_label: Label = %SpecialActionsTitleLabel
@onready var reactions_title_label: Label = %ReactionsTitleLabel
@onready var legendary_actions_title_label: Label = %LegendaryActionsTitleLabel
@onready var lair_actions_title_label: Label = %LairActionsTitleLabel
@onready var regional_effects_title_label: Label = %RegionalEffectsTitleLabel

# Containers for list items
@onready var traits_list_container: VBoxContainer = %TraitsListContainer
@onready var actions_list_container: VBoxContainer = %ActionsListContainer
@onready var special_actions_list_container: VBoxContainer = %SpecialActionsListContainer
@onready var reactions_list_container: VBoxContainer = %ReactionsListContainer
@onready var legendary_actions_list_container: VBoxContainer = %LegendaryActionsListContainer
@onready var lair_actions_list_container: VBoxContainer = %LairActionsListContainer
@onready var regional_effects_list_container: VBoxContainer = %RegionalEffectsListContainer


# Called by CreatureInfoWindow to populate this panel with data
func display_creature_data(creature_data: Dictionary):
	print("--- CDP: display_creature_data CALLED for: ", creature_data.get("Name", "Unknown"))
	if creature_data.is_empty():
		print("CDP: Creature data is empty.")
		name_label.text = "[center]No Creature Data[/center]" # BBCode for center
		# Clear or hide other fields
		size_label.text = ""
		ac_label.text = ""
		hp_label.text = ""
		speed_label.text = ""
		abilities_rich_text_label.clear()
		senses_label.text = ""
		languages_label.text = ""
		challenge_label.text = ""
		skills_label.text = ""
		saving_throws_label.text = ""
		damage_vulnerabilities_label.text = ""
		damage_resistances_label.text = ""
		damage_immunities_label.text = ""
		condition_immunities_label.text = ""

		_clear_list_container(traits_list_container)
		_clear_list_container(actions_list_container)
		_clear_list_container(special_actions_list_container)
		_clear_list_container(reactions_list_container)
		_clear_list_container(legendary_actions_list_container)
		_clear_list_container(lair_actions_list_container)
		_clear_list_container(regional_effects_list_container)
		
		# Hide all title labels
		for title_node in [traits_title_label, actions_title_label, special_actions_title_label, reactions_title_label, legendary_actions_title_label, lair_actions_title_label, regional_effects_title_label]:
			if is_instance_valid(title_node): title_node.visible = false
		return

	# --- Populate Basic Info ---
	name_label.clear() # Clear previous BBCode
	name_label.push_font_size(24) # Example: Make name bigger
	name_label.push_bold()
	name_label.add_text(creature_data.get("Name", "N/A"))
	name_label.pop() # Pop bold
	name_label.pop() # Pop font size

	size_label.text = creature_data.get("Size Type Alignment", "N/A")
	ac_label.text = "Armor Class: " + creature_data.get("Armor Class", "N/A")
	hp_label.text = "Hit Points: " + creature_data.get("Hit Points", "N/A")
	speed_label.text = "Speed: " + creature_data.get("Speed", "N/A")

	# --- Populate Abilities with GridContainer ---
	if is_instance_valid(abilities_rich_text_label):
		abilities_rich_text_label.clear()
		abilities_rich_text_label.push_bold()
		abilities_rich_text_label.add_text("ABILITIES") # Using all caps like typical stat blocks
		abilities_rich_text_label.pop() # Pop bold
		abilities_rich_text_label.newline() # Add a newline after the "ABILITIES" title

		var abilities_dict: Dictionary = creature_data.get("Abilities", {})
		print(creature_data.get("Abilities", {}))
		var ability_order = ["STR", "DEX", "CON", "INT", "WIS", "CHA"]
		
		for stat_key in ability_order:
			if abilities_dict.has(stat_key):
				# Add each ability on its own line
				abilities_rich_text_label.push_bold() # Optional: bold the stat name
				abilities_rich_text_label.add_text("{stat_key}: ")
				abilities_rich_text_label.pop() # Pop bold for stat name
				abilities_rich_text_label.add_text("{abilities_dict[stat_key]}")
				abilities_rich_text_label.newline() # Add a newline after each ability
		
		# Remove the last newline if any abilities were added to prevent extra space
		# This is a bit tricky with RichTextLabel directly. 
		# An alternative is to build a string then set it, or manage paragraph spacing.
		# For simplicity now, we'll just have the newlines. If it's an issue, we can refine.
	else:
		printerr("CDP: abilities_rich_text_label is NULL!")


	# --- Populate Other Stats ---
	senses_label.text = "Senses: " + creature_data.get("Senses", "N/A")
	languages_label.text = "Languages: " + creature_data.get("Languages", "N/A")
	challenge_label.text = "Challenge: " + creature_data.get("Challenge", "N/A")
	
	# Fields that might be missing - set text and visibility
	_set_optional_field(skills_label, "Skills", creature_data.get("Skills", ""))
	_set_optional_field(saving_throws_label, "Saving Throws", creature_data.get("Saving Throws", ""))
	_set_optional_field(damage_vulnerabilities_label, "Damage Vulnerabilities", creature_data.get("Damage Vulnerabilities", ""))
	_set_optional_field(damage_resistances_label, "Damage Resistances", creature_data.get("Damage Resistances", ""))
	_set_optional_field(damage_immunities_label, "Damage Immunities", creature_data.get("Damage Immunities", ""))
	_set_optional_field(condition_immunities_label, "Condition Immunities", creature_data.get("Condition Immunities", ""))

	# --- Populate List Sections ---
	_populate_list_section(traits_list_container, traits_title_label, creature_data.get("Traits", []))
	_populate_list_section(actions_list_container, actions_title_label, creature_data.get("Actions", []))
	_populate_list_section(special_actions_list_container, special_actions_title_label, creature_data.get("Special Actions", []))
	_populate_list_section(reactions_list_container, reactions_title_label, creature_data.get("Reactions", []))
	_populate_list_section(legendary_actions_list_container, legendary_actions_title_label, creature_data.get("Legendary Actions", []))
	_populate_list_section(lair_actions_list_container, lair_actions_title_label, creature_data.get("Lair Actions", []))
	_populate_list_section(regional_effects_list_container, regional_effects_title_label, creature_data.get("Regional Effects", []))


# Helper to set text for optional fields and manage their visibility
func _set_optional_field(label_node: Label, prefix: String, value: String):
	if is_instance_valid(label_node):
		if value.is_empty() or value.to_lower() == "n/a" or value.to_lower() == "—":
			label_node.text = ""
			label_node.visible = false
		else:
			label_node.text = prefix + ": " + value
			label_node.visible = true

# Helper to clear a VBoxContainer of its children
func _clear_list_container(container: VBoxContainer):
	if not is_instance_valid(container): return
	for child in container.get_children():
		child.queue_free()

# Helper to populate a VBoxContainer with list items (Traits, Actions, etc.)
func _populate_list_section(container: VBoxContainer, title_label: Label, items_array: Array):
	if not is_instance_valid(container) or not is_instance_valid(title_label): return

	_clear_list_container(container)

	if items_array.is_empty():
		title_label.visible = false
		container.visible = false
		return

	title_label.visible = true
	container.visible = true

	for item_text_or_dict in items_array:
		var item_entry_label = RichTextLabel.new()
		item_entry_label.fit_content = true # For RichTextLabel in containers
		item_entry_label.autowrap_mode = TextServer.AUTOWRAP_WORD # Default for RTL

		if item_text_or_dict is String:
			var text_to_parse = item_text_or_dict
			# Try to bold the part before the first colon, if it's reasonably short (like a name)
			var colon_pos = text_to_parse.find(":")
			if colon_pos != -1 and colon_pos < 50 and not text_to_parse.begins_with("  "): # Heuristic
				item_entry_label.push_bold()
				item_entry_label.add_text(text_to_parse.substr(0, colon_pos + 1) + " ") # Add space after colon
				item_entry_label.pop()
				item_entry_label.add_text(text_to_parse.substr(colon_pos + 1).strip_edges())
			else:
				# For multi-line descriptions within a single item, preserve newlines
				# The parser should have joined them with \n
				item_entry_label.add_text(text_to_parse.replace("\n", " ")) # Or handle newlines better if needed for formatting
		elif item_text_or_dict is Dictionary:
			# Placeholder for more structured items if your parser creates them
			# e.g., for spells with distinct name, components, description fields
			if item_text_or_dict.has("name") and item_text_or_dict.has("description"):
				item_entry_label.push_bold()
				item_entry_label.add_text(item_text_or_dict["name"] + ": ")
				item_entry_label.pop()
				item_entry_label.add_text(item_text_or_dict["description"])
			else:
				item_entry_label.add_text(str(item_text_or_dict)) # Fallback
		
		container.add_child(item_entry_label)
