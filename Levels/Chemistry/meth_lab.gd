extends Control

# Game Variables
var time_remaining := 300.0
var score := 0
var quality := 0.0
var profit := 0.0
var current_phase := 0
var current_temperature := 25.0
var is_stirring := false
var is_crystallizing := false
var chemicals_added := []

# Recipe information
var required_chemicals := ["Pseudoephedrine", "Red Phosphorus", "Iodine", "Methylamine", "Aluminum"]
var current_step := 0
var heating_phase_temp_range := [60.0, 80.0]
var cooling_phase_temp_range := [20.0, 35.0]

# Node references
@onready var temperature_label = $MainContainer/VBoxContainer/ContentContainer/LeftColumn/EquipmentPanel/VBoxContainer/TemperatureContainer/TemperatureValue
@onready var beaker_liquid = $MainContainer/VBoxContainer/ContentContainer/CenterColumn/BeakerPanel/BeakerContainer/Beaker/BeakerLiquid
@onready var phase_label = $MainContainer/VBoxContainer/ContentContainer/CenterColumn/BeakerPanel/BeakerContainer/PhaseValue
@onready var time_value = $MainContainer/VBoxContainer/HeaderPanel/HeaderContainer/TimeContainer/TimeValue
@onready var chemicals_added_value = $MainContainer/VBoxContainer/ContentContainer/CenterColumn/StatusPanel/StatusContainer/ChemicalsAddedContainer/ChemicalsAddedValue
@onready var quality_value = $MainContainer/VBoxContainer/ContentContainer/CenterColumn/StatusPanel/StatusContainer/QualityContainer/QualityValue
@onready var quality_bar = $MainContainer/VBoxContainer/ContentContainer/CenterColumn/StatusPanel/StatusContainer/QualityBar

# Timer for countdown
var timer: Timer

func _ready():
	setup_game()
	
	# Create timer for countdown
	timer = Timer.new()
	timer.wait_time = 1.0
	timer.connect("timeout", _on_timer_timeout)
	add_child(timer)
	timer.start()

func setup_game():
	time_remaining = 300.0
	score = 0
	quality = 0.0
	profit = 0.0
	current_phase = 0
	current_temperature = 25.0
	is_stirring = false
	is_crystallizing = false
	chemicals_added = []
	current_step = 0
	
	update_ui()
	update_beaker()

func update_ui():
	# Update temperature display
	if temperature_label:
		temperature_label.text = str(int(current_temperature)) + "°C"
	
	# Update phase display
	if phase_label:
		var phase_text = "Mix Initial Chemicals"
		if current_phase == 1:
			phase_text = "Add Methylamine"
		elif current_phase == 2:
			phase_text = "Final Processing"
		phase_label.text = phase_text
	
	# Update timer display
	if time_value:
		var minutes = int(time_remaining) / 60
		var seconds = int(time_remaining) % 60
		time_value.text = "%02d:%02d" % [minutes, seconds]
	
	# Update chemicals added
	if chemicals_added_value:
		chemicals_added_value.text = str(chemicals_added.size()) + "/5"
	
	# Update quality display
	if quality_value and quality_bar:
		quality_value.text = str(int(quality * 100)) + "%"
		quality_bar.value = quality * 100

func update_beaker():
	if beaker_liquid:
		# Change color based on phase and chemicals added
		var color_value = clamp(chemicals_added.size() * 0.25, 0, 1.0)
		
		if current_phase == 0:
			beaker_liquid.modulate = Color(0.2, 0.5 + color_value * 0.5, color_value, 0.8)
		elif current_phase == 1:
			beaker_liquid.modulate = Color(0.1, 0.7, 0.3, 0.8)
		elif current_phase == 2:
			beaker_liquid.modulate = Color(0.0, 0.8, 0.4, 0.9)
		
		# Change fill level based on chemicals added
		beaker_liquid.scale = Vector2(1.0, 0.2 + chemicals_added.size() * 0.16)

func _process(delta: float) -> void:
	# Handle temperature changes over time
	if current_temperature > 25.0:
		current_temperature -= 0.1 * delta
		update_ui()

func _on_timer_timeout():
	time_remaining -= 1
	
	if time_remaining <= 0:
		timer.stop()
		# Game over - ran out of time
		var dialog = AcceptDialog.new()
		dialog.title = "Time's Up!"
		dialog.dialog_text = "You ran out of time. The batch failed."
		add_child(dialog)
		dialog.popup_centered()
		dialog.connect("confirmed", _on_exit_button_pressed)
	
	update_ui()

func _on_chemical_pressed(chemical_name: String):
	# Check if this chemical has already been added
	if chemical_name in chemicals_added:
		return
	
	# Check if this is the correct chemical for the current phase
	var should_add = false
	var correct_order = false
	
	if current_phase == 0 and chemical_name in ["Pseudoephedrine", "Red Phosphorus", "Iodine"]:
		should_add = true
		correct_order = chemicals_added.size() == ["Pseudoephedrine", "Red Phosphorus", "Iodine"].find(chemical_name)
	elif current_phase == 1 and chemical_name == "Methylamine":
		should_add = true
		correct_order = true
	elif current_phase == 2 and chemical_name == "Aluminum":
		should_add = true
		correct_order = true
	
	if should_add:
		chemicals_added.append(chemical_name)
		
		# Increase quality if added in correct order
		if correct_order:
			quality += 0.1
		else:
			quality += 0.05
		
		quality = clamp(quality, 0.0, 1.0)
		
		# Check for phase transitions
		check_phase_transition()
		
		update_ui()
		update_beaker()

func check_phase_transition():
	if current_phase == 0 and "Pseudoephedrine" in chemicals_added and "Red Phosphorus" in chemicals_added and "Iodine" in chemicals_added:
		if is_temperature_in_range(heating_phase_temp_range) and is_stirring:
			current_phase = 1
			is_stirring = false
	elif current_phase == 1 and "Methylamine" in chemicals_added:
		if is_temperature_in_range(heating_phase_temp_range) and is_stirring:
			current_phase = 2
			is_stirring = false
	
	update_ui()

func is_temperature_in_range(range_array: Array) -> bool:
	return current_temperature >= range_array[0] and current_temperature <= range_array[1]

func _on_increase_temp_pressed():
	current_temperature += 5.0
	if current_temperature > 100.0:
		current_temperature = 100.0
		
		# Overheated - batch ruined
		var dialog = AcceptDialog.new()
		dialog.title = "Batch Ruined!"
		dialog.dialog_text = "You overheated the solution and ruined the batch!"
		add_child(dialog)
		dialog.popup_centered()
		dialog.connect("confirmed", _on_exit_button_pressed)
	
	update_ui()

func _on_decrease_temp_pressed():
	current_temperature -= 5.0
	if current_temperature < 20.0:
		current_temperature = 20.0
	update_ui()

func _on_stir_button_pressed():
	is_stirring = true
	
	# Add visual feedback
	var tween = create_tween()
	tween.tween_property(beaker_liquid, "rotation_degrees", 5, 0.2)
	tween.tween_property(beaker_liquid, "rotation_degrees", -5, 0.4)
	tween.tween_property(beaker_liquid, "rotation_degrees", 0, 0.2)
	
	check_phase_transition()
	
	# Increase quality slightly if stirring at the right temperature
	if current_phase == 0 and is_temperature_in_range(heating_phase_temp_range):
		quality += 0.05
	elif current_phase == 1 and is_temperature_in_range(cooling_phase_temp_range):
		quality += 0.05
	elif current_phase == 2 and is_temperature_in_range([60.0, 70.0]):
		quality += 0.05
	
	quality = clamp(quality, 0.0, 1.0)
	update_ui()

func _on_crystallize_button_pressed():
	# Can only crystallize in final phase with correct temperature
	if current_phase == 2 and is_temperature_in_range(cooling_phase_temp_range) and "Aluminum" in chemicals_added:
		is_crystallizing = true
		
		# Visual feedback
		var tween = create_tween()
		tween.tween_property(beaker_liquid, "modulate", Color(0.9, 0.9, 0.5, 0.9), 1.0)
		
		# Final quality boost if conditions are right
		if quality > 0.7:
			quality = 1.0
		else:
			quality += 0.1
		
		quality = clamp(quality, 0.0, 1.0)
		update_ui()
	else:
		# Warn player about incorrect conditions
		var dialog = AcceptDialog.new()
		dialog.title = "Cannot Crystallize"
		dialog.dialog_text = "Conditions are not right for crystallization."
		add_child(dialog)
		dialog.popup_centered()

func _on_finish_button_pressed():
	if is_crystallizing and current_phase == 2:
		timer.stop()
		
		# Calculate profit based on quality and time
		profit = quality * 5000.0 + (time_remaining / 300.0) * 2000.0
		
		# Show results
		var dialog = AcceptDialog.new()
		dialog.title = "Batch Complete!"
		
		var quality_text = "Poor"
		if quality >= 0.3 and quality < 0.6:
			quality_text = "Average"
		elif quality >= 0.6 and quality < 0.9:
			quality_text = "Good"
		elif quality >= 0.9:
			quality_text = "Pure"
		
		dialog.dialog_text = "Batch completed!\nQuality: %s (%.0f%%)\nProfit: $%.2f" % [quality_text, quality * 100, profit]
		add_child(dialog)
		dialog.popup_centered()
		dialog.connect("confirmed", _on_exit_button_pressed)
	else:
		# Warn player
		var dialog = AcceptDialog.new()
		dialog.title = "Cannot Finish"
		dialog.dialog_text = "The batch is not ready to be completed yet."
		add_child(dialog)
		dialog.popup_centered()

func _on_exit_button_pressed():
	# Exit the meth lab scene and return to previous scene
	get_tree().change_scene_to_file("res://Levels/House/House.tscn") 