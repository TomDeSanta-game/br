extends Control

# Variables for chemicals and cooking
var chemicals = []
var selected_method = ""
var heat_level = 100
var purity = 0.0
var cooking_complete = false
var max_chemicals = 3

# Optimal recipes and heat levels
var optimal_recipes = {
	"P2P": ["Methylamine", "Phenylacetic Acid", "Aluminum"],
	"Nagai": ["Pseudoephedrine", "Red Phosphorus", "Hydroiodic Acid"],
	"Birch": ["Pseudoephedrine", "Lithium", "Ammonia"]
}

var optimal_heat = {
	"P2P": 170,
	"Nagai": 120,
	"Birch": 90
}

# Called when the node enters the scene tree
func _ready():
	print("MethLabGame: _ready called")
	
	# Debug printing
	print("MainContainer path:", $MainContainer)
	
	if has_node("MainContainer"):
		print("HeaderPanel path:", $MainContainer/HeaderPanel)
	else:
		print("MainContainer not found")
	
	# Catch any errors in setup
	var error_occurred = false
	if !has_node("MainContainer"):
		print("ERROR: MainContainer not found")
		error_occurred = true
		
	if !has_node("MainContainer/MainPanel"):
		print("ERROR: MainPanel not found")
		error_occurred = true
		
	if !error_occurred:
		setup_signals()
		reset_lab()
		print("MethLabGame: initialization complete")
	else:
		print("MethLabGame: initialization failed - node structure does not match expected paths")

# Connect all UI signals
func setup_signals():
	# Method selection
	$MainContainer/MainPanel/HBoxContainer/RecipePanel/MarginContainer/VBoxContainer/MethodSection/StructureOptions/P2P.pressed.connect(_on_method_selected.bind("P2P"))
	$MainContainer/MainPanel/HBoxContainer/RecipePanel/MarginContainer/VBoxContainer/MethodSection/StructureOptions/Nagai.pressed.connect(_on_method_selected.bind("Nagai"))
	$MainContainer/MainPanel/HBoxContainer/RecipePanel/MarginContainer/VBoxContainer/MethodSection/StructureOptions/Birch.pressed.connect(_on_method_selected.bind("Birch"))
	
	# Chemical handling
	$MainContainer/MainPanel/HBoxContainer/RecipePanel/MarginContainer/VBoxContainer/ChemicalSection/ChemicalOptions/AddChemical.pressed.connect(_on_add_chemical_pressed)
	
	# Cooking actions
	$MainContainer/MainPanel/HBoxContainer/LabPanel/MarginContainer/VBoxContainer/ActionButtons/Mix.pressed.connect(_on_mix_pressed)
	$MainContainer/MainPanel/HBoxContainer/LabPanel/MarginContainer/VBoxContainer/ActionButtons/Cook.pressed.connect(_on_cook_pressed)
	$MainContainer/MainPanel/HBoxContainer/LabPanel/MarginContainer/VBoxContainer/ActionButtons/Clear.pressed.connect(_on_clear_pressed)
	
	# Heat control
	$MainContainer/MainPanel/HBoxContainer/LabPanel/MarginContainer/VBoxContainer/HeatControls/HeatSlider.value_changed.connect(_on_heat_slider_changed)
	
	# Quit button
	$MainContainer/HeaderPanel/MarginContainer/HBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)

# When a synthesis method is selected
func _on_method_selected(method):
	selected_method = method
	add_console_message("Selected method: " + method)
	update_interface()

# When a chemical is added
func _on_add_chemical_pressed():
	if chemicals.size() >= max_chemicals:
		add_console_message("Too many chemicals (max 3)!")
		return
		
	var option = $MainContainer/MainPanel/HBoxContainer/RecipePanel/MarginContainer/VBoxContainer/ChemicalSection/ChemicalOptions/OptionMenu
	var chemical = option.get_item_text(option.selected)
	
	if chemicals.has(chemical):
		add_console_message("Already added: " + chemical)
		return
		
	chemicals.append(chemical)
	add_console_message("Added: " + chemical)
	update_interface()

# When mix button is pressed
func _on_mix_pressed():
	if chemicals.size() == 0:
		add_console_message("No chemicals to mix!")
		return
		
	if selected_method == "":
		add_console_message("Select a synthesis method first!")
		return
		
	add_console_message("Mixing chemicals...")
	update_liquid_display()

# When cook button is pressed
func _on_cook_pressed():
	if chemicals.size() == 0:
		add_console_message("No chemicals to cook!")
		return
		
	if selected_method == "":
		add_console_message("Select a synthesis method first!")
		return
		
	calculate_purity()
	cooking_complete = true
	update_interface()
	
	if purity > 90:
		add_console_message("Excellent! Purity: " + str(purity) + "%")
	elif purity > 70:
		add_console_message("Good batch. Purity: " + str(purity) + "%")
	else:
		add_console_message("Poor quality. Purity: " + str(purity) + "%")

# When clear button is pressed
func _on_clear_pressed():
	reset_lab()
	add_console_message("Lab cleared and reset.")

# When heat slider is changed
func _on_heat_slider_changed(value):
	heat_level = value
	$MainContainer/MainPanel/HBoxContainer/LabPanel/MarginContainer/VBoxContainer/HeatControls/HeatLabel.text = "Heat Level: " + str(heat_level) + "°C"

# When quit button is pressed
func _on_quit_pressed():
	if is_instance_valid(get_node("/root/SceneManager")):
		get_node("/root/SceneManager").change_scene("res://Levels/House/House.tscn")
	else:
		get_tree().change_scene_to_file("res://Levels/House/House.tscn")

# Calculate purity based on correct chemicals and heat
func calculate_purity():
	var base_purity = 0.0
	var heat_factor = 0.0
	var correct_chemicals = 0
	
	# Check if all chemicals match the optimal recipe
	if optimal_recipes.has(selected_method):
		var optimal = optimal_recipes[selected_method]
		
		for chemical in chemicals:
			if chemical in optimal:
				correct_chemicals += 1
				
		# Base purity determined by correct chemicals
		base_purity = (correct_chemicals / float(optimal.size())) * 85.0
		
		# Heat factor based on how close to optimal heat
		var target_heat = optimal_heat[selected_method]
		var heat_diff = abs(heat_level - target_heat)
		
		# Heat factor is best at optimal heat, decreases as you move away
		if heat_diff <= 5:
			heat_factor = 14.1  # Can reach 99.1% max (85 + 14.1)
		elif heat_diff <= 15:
			heat_factor = 10.0
		elif heat_diff <= 30:
			heat_factor = 5.0
		else:
			heat_factor = 0.0
	
	purity = base_purity + heat_factor
	purity = clamp(purity, 0.0, 99.1)
	
	# Update UI
	$MainContainer/MainPanel/HBoxContainer/LabPanel/MarginContainer/VBoxContainer/PurityContainer/PurityLabel.text = "Purity: " + str(purity) + "%"
	$MainContainer/MainPanel/HBoxContainer/LabPanel/MarginContainer/VBoxContainer/PurityContainer/PurityProgressBar.value = purity

# Update liquid display based on chemicals
func update_liquid_display():
	var liquid = $MainContainer/MainPanel/HBoxContainer/LabPanel/MarginContainer/VBoxContainer/MixingBeaker/LiquidDisplay
	
	if chemicals.size() == 0:
		liquid.color = Color(1, 1, 1, 0)  # Clear
		return
		
	# Different color based on method and chemicals
	if selected_method == "P2P":
		liquid.color = Color(0.12, 0.5, 0.8, 0.8)  # Blue
	elif selected_method == "Nagai":
		liquid.color = Color(0.8, 0.8, 0.2, 0.8)  # Yellow
	elif selected_method == "Birch":
		liquid.color = Color(0.2, 0.5, 0.2, 0.8)  # Green
	else:
		liquid.color = Color(0.5, 0.5, 0.5, 0.8)  # Gray

# Update interface elements
func update_interface():
	# Update chemical list
	var chemicals_text = "Selected: "
	if chemicals.size() == 0:
		chemicals_text += "None"
	else:
		chemicals_text += ", ".join(chemicals)
	
	$MainContainer/MainPanel/HBoxContainer/RecipePanel/MarginContainer/VBoxContainer/ChemicalSection/SelectedChemicals.text = chemicals_text
	
	# Update content label
	var content_text = "Contents: "
	if chemicals.size() == 0:
		content_text += "Empty"
	else:
		content_text += "Mixed Chemicals"
		if cooking_complete:
			content_text += " (Cooked)"
	
	$MainContainer/MainPanel/HBoxContainer/LabPanel/MarginContainer/VBoxContainer/MixingBeaker/ContentLabel.text = content_text
	
	# Update liquid display
	update_liquid_display()

# Add message to console
func add_console_message(message):
	var console = $MainContainer/ConsolePanel/MarginContainer/ConsoleScroll/ConsoleOutput
	console.text = "> " + message + "\n" + console.text

# Reset the lab to initial state
func reset_lab():
	chemicals.clear()
	selected_method = ""
	heat_level = 100
	purity = 0.0
	cooking_complete = false
	
	$MainContainer/MainPanel/HBoxContainer/LabPanel/MarginContainer/VBoxContainer/HeatControls/HeatSlider.value = 100
	$MainContainer/MainPanel/HBoxContainer/LabPanel/MarginContainer/VBoxContainer/PurityContainer/PurityLabel.text = "Purity: 0.0%"
	$MainContainer/MainPanel/HBoxContainer/LabPanel/MarginContainer/VBoxContainer/PurityContainer/PurityProgressBar.value = 0
	
	update_interface() 