extends Control

var temperature = 25.0
var beaker_contents = {
	"pseudoephedrine": 0,
	"red_phosphorus": 0,
	"iodine": 0,
	"methylamine": 0,
	"aluminum": 0
}

var current_phase = "idle"
var batch_quality = 0.0

var equipment_buttons = {}
var beaker
var temperature_label
var phase_label
var quality_label
var complete_button

func _ready():
	await get_tree().process_frame
	initialize_node_references()
	setup_equipment_buttons()
	connect_control_buttons()
	reset_game()
	print("MethLab Game successfully loaded!")

func initialize_node_references():
	var equipment_container = $MainContainer/VBoxContainer/ContentArea/LeftPanel/Equipment
	
	beaker = $MainContainer/VBoxContainer/ContentArea/CenterPanel/Beaker
	
	var add_pseudoephedrine = Button.new()
	add_pseudoephedrine.text = "Add Pseudoephedrine"
	equipment_container.add_child(add_pseudoephedrine)
	equipment_buttons["pseudoephedrine"] = add_pseudoephedrine
	
	var add_red_phosphorus = Button.new()
	add_red_phosphorus.text = "Add Red Phosphorus"
	equipment_container.add_child(add_red_phosphorus)
	equipment_buttons["red_phosphorus"] = add_red_phosphorus
	
	var add_iodine = Button.new()
	add_iodine.text = "Add Iodine"
	equipment_container.add_child(add_iodine)
	equipment_buttons["iodine"] = add_iodine
	
	var add_methylamine = Button.new()
	add_methylamine.text = "Add Methylamine"
	equipment_container.add_child(add_methylamine)
	equipment_buttons["methylamine"] = add_methylamine
	
	var add_aluminum = Button.new()
	add_aluminum.text = "Add Aluminum"
	equipment_container.add_child(add_aluminum)
	equipment_buttons["aluminum"] = add_aluminum
	
	var heat_button = Button.new()
	heat_button.text = "Heat Reaction"
	equipment_container.add_child(heat_button)
	equipment_buttons["heat"] = heat_button
	
	var cool_button = Button.new()
	cool_button.text = "Cool Reaction"
	equipment_container.add_child(cool_button)
	equipment_buttons["cool"] = cool_button
	
	var crystallize_button = Button.new()
	crystallize_button.text = "Crystallize"
	equipment_container.add_child(crystallize_button)
	equipment_buttons["crystallize"] = crystallize_button
	
	var beaker_liquid = ColorRect.new()
	beaker_liquid.name = "BeakerLiquid"
	beaker_liquid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	beaker_liquid.custom_minimum_size = Vector2(0, 200)
	beaker_liquid.color = Color(0.5, 0.5, 0.5, 0.5)
	beaker.add_child(beaker_liquid)
	
	temperature_label = Label.new()
	temperature_label.name = "TemperatureLabel"
	temperature_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	beaker.add_child(temperature_label)
	
	var stats_container = $MainContainer/VBoxContainer/ContentArea/RightPanel/Stats
	
	phase_label = Label.new()
	phase_label.name = "PhaseLabel"
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_container.add_child(phase_label)
	
	quality_label = Label.new()
	quality_label.name = "QualityLabel"
	quality_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_container.add_child(quality_label)
	
	complete_button = $MainContainer/VBoxContainer/ControlPanel/HBoxContainer/CompleteButton

func setup_equipment_buttons():
	for chemical in beaker_contents.keys():
		if equipment_buttons.has(chemical):
			equipment_buttons[chemical].pressed.connect(func(): add_chemical(chemical))
	
	if equipment_buttons.has("heat"):
		equipment_buttons["heat"].pressed.connect(apply_heat)
	
	if equipment_buttons.has("cool"):
		equipment_buttons["cool"].pressed.connect(apply_cooling)
	
	if equipment_buttons.has("crystallize"):
		equipment_buttons["crystallize"].pressed.connect(crystallize)

func connect_control_buttons():
	complete_button = $MainContainer/VBoxContainer/ControlPanel/HBoxContainer/CompleteButton
	var reset_button = $MainContainer/VBoxContainer/ControlPanel/HBoxContainer/ResetButton
	var quit_button = $MainContainer/VBoxContainer/ControlPanel/HBoxContainer/QuitButton
	
	if complete_button:
		complete_button.pressed.connect(complete_batch)
	
	if reset_button:
		reset_button.pressed.connect(reset_game)
	
	if quit_button:
		quit_button.pressed.connect(func(): get_tree().quit())

func add_chemical(chemical_name):
	if current_phase != "idle" and current_phase != "mixing":
		return
	
	beaker_contents[chemical_name] += 1
	current_phase = "mixing"
	update_beaker_display()
	update_phase_display()

func apply_heat():
	if current_phase != "mixing" and current_phase != "heating":
		return
	
	temperature += 10.0
	current_phase = "heating"
	update_beaker_display()
	update_phase_display()
	
	check_reaction_progress()

func apply_cooling():
	if current_phase != "heating" and current_phase != "cooling":
		return
	
	temperature -= 5.0
	current_phase = "cooling"
	update_beaker_display()
	update_phase_display()
	
	check_reaction_progress()

func crystallize():
	if current_phase != "cooling" and current_phase != "crystallizing":
		return
	
	current_phase = "crystallizing"
	update_phase_display()
	calculate_quality()
	update_quality_display()

func check_reaction_progress():
	if temperature > 80.0 and beaker_contents["pseudoephedrine"] > 0 and beaker_contents["red_phosphorus"] > 0 and beaker_contents["iodine"] > 0:
		current_phase = "reacting"
	elif temperature < 40.0 and current_phase == "reacting":
		current_phase = "cooling"
	
	update_phase_display()

func calculate_quality():
	batch_quality = 0.0
	
	# Base quality
	if beaker_contents["pseudoephedrine"] > 0 and beaker_contents["red_phosphorus"] > 0 and beaker_contents["iodine"] > 0:
		batch_quality = 30.0
	
	# Walter White's special methylamine recipe
	if beaker_contents["methylamine"] > 0:
		batch_quality += 40.0
	
	# Catalyst bonus
	if beaker_contents["aluminum"] > 0:
		batch_quality += 10.0
	
	# Perfect temperature handling
	if temperature > 85.0 and temperature < 95.0:
		batch_quality += 20.0
	
	# Cap at 100%
	batch_quality = min(batch_quality, 100.0)

func complete_batch():
	if current_phase != "crystallizing":
		return
	
	var message = "Batch completed!\n"
	
	if batch_quality >= 90.0:
		message += "Blue Sky quality! Heisenberg would be proud."
	elif batch_quality >= 70.0:
		message += "Good quality product. Jesse says it's 'tight, tight, tight!'"
	elif batch_quality >= 40.0:
		message += "Average quality. Might need to adjust your recipe."
	else:
		message += "Poor quality. Back to chemistry class!"
	
	print(message)
	# In a real game, you'd display this message to the player
	
	reset_game()

func reset_game():
	temperature = 25.0
	for chemical in beaker_contents.keys():
		beaker_contents[chemical] = 0
	current_phase = "idle"
	batch_quality = 0.0
	
	update_beaker_display()
	update_phase_display()
	update_quality_display()

func update_beaker_display():
	if temperature_label:
		temperature_label.text = "Temperature: %.1f°C" % temperature
	
	var beaker_liquid = beaker.get_node_or_null("BeakerLiquid")
	if beaker_liquid:
		# Change color based on contents and phase
		var color = Color(0.5, 0.5, 0.5, 0.5) # Default gray
		
		if beaker_contents["pseudoephedrine"] > 0:
			color = Color(1.0, 1.0, 1.0, 0.7) # White
		
		if beaker_contents["red_phosphorus"] > 0 and beaker_contents["iodine"] > 0:
			color = Color(0.8, 0.4, 0.4, 0.7) # Reddish
		
		if current_phase == "reacting":
			color = Color(0.9, 0.7, 0.2, 0.8) # Amber
		
		if current_phase == "cooling" and beaker_contents["methylamine"] > 0:
			color = Color(0.2, 0.7, 0.9, 0.8) # Blue
		
		if current_phase == "crystallizing":
			color = Color(0.3, 0.8, 0.9, 0.9) # Blue crystal
		
		beaker_liquid.color = color

func update_phase_display():
	if phase_label:
		var phase_text = "Phase: "
		match current_phase:
			"idle":
				phase_text += "Ready"
			"mixing":
				phase_text += "Mixing Chemicals"
			"heating":
				phase_text += "Heating"
			"reacting":
				phase_text += "Chemical Reaction"
			"cooling":
				phase_text += "Cooling Down"
			"crystallizing":
				phase_text += "Crystallizing"
		
		phase_label.text = phase_text

func update_quality_display():
	if quality_label:
		quality_label.text = "Product Quality: %.1f%%" % batch_quality 