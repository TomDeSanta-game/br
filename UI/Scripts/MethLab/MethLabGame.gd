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
@onready var beaker = $MainContainer/VBoxContainer/ContentContainer/CenterColumn/BeakerPanel/Beaker
@onready var beaker_liquid = $MainContainer/VBoxContainer/ContentContainer/CenterColumn/BeakerPanel/Beaker/BeakerLiquid
@onready var timer_label = $MainContainer/VBoxContainer/ContentContainer/RightColumn/StatsPanel/VBoxContainer/TimerContainer/TimerValue
@onready var stirring_label = $MainContainer/VBoxContainer/ContentContainer/LeftColumn/EquipmentPanel/VBoxContainer/StirringContainer/StirringValue
@onready var log_panel = $MainContainer/VBoxContainer/ContentContainer/RightColumn/LogPanel/ScrollContainer/LogItems
@onready var quality_bar = $MainContainer/VBoxContainer/ContentContainer/RightColumn/StatsPanel/VBoxContainer/QualityBar
@onready var score_value = $MainContainer/VBoxContainer/ContentContainer/RightColumn/StatsPanel/VBoxContainer/ScoreContainer/ScoreValue
@onready var profit_value = $MainContainer/VBoxContainer/ContentContainer/RightColumn/StatsPanel/VBoxContainer/ProfitContainer/ProfitValue
@onready var phase_label = $MainContainer/VBoxContainer/ContentContainer/CenterColumn/BeakerPanel/VBoxContainer/PhaseValue

# Equipment panel buttons
@onready var heat_button = $MainContainer/VBoxContainer/ContentContainer/LeftColumn/EquipmentPanel/VBoxContainer/EquipmentButtons/HeatButton
@onready var cool_button = $MainContainer/VBoxContainer/ContentContainer/LeftColumn/EquipmentPanel/VBoxContainer/EquipmentButtons/CoolButton
@onready var stir_button = $MainContainer/VBoxContainer/ContentContainer/LeftColumn/EquipmentPanel/VBoxContainer/EquipmentButtons/StirButton

# Chemical panel buttons
@onready var pseudo_button = $MainContainer/VBoxContainer/ContentContainer/CenterColumn/ChemicalPanel/VBoxContainer/ChemButtons/PseudoButton
@onready var phosphorus_button = $MainContainer/VBoxContainer/ContentContainer/CenterColumn/ChemicalPanel/VBoxContainer/ChemButtons/PhosphorusButton
@onready var iodine_button = $MainContainer/VBoxContainer/ContentContainer/CenterColumn/ChemicalPanel/VBoxContainer/ChemButtons/IodineButton
@onready var methylamine_button = $MainContainer/VBoxContainer/ContentContainer/CenterColumn/ChemicalPanel/VBoxContainer/ChemButtons/MethylamineButton
@onready var aluminum_button = $MainContainer/VBoxContainer/ContentContainer/CenterColumn/ChemicalPanel/VBoxContainer/ChemButtons/AluminumButton
@onready var crystallize_button = $MainContainer/VBoxContainer/ContentContainer/CenterColumn/ChemicalPanel/VBoxContainer/CrystallizeButton

# Control panel buttons
@onready var complete_button = $MainContainer/VBoxContainer/ControlPanel/HBoxContainer/CompleteButton
@onready var reset_button = $MainContainer/VBoxContainer/ControlPanel/HBoxContainer/ResetButton
@onready var quit_button = $MainContainer/VBoxContainer/ControlPanel/HBoxContainer/QuitButton

func _ready():
	setup_game()
	connect_signals()
	update_initial_state()
	start_timer()

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
	phase_label.text = "Phase 1: Mix initial chemicals"

func connect_signals():
	# Connect chemical buttons
	pseudo_button.pressed.connect(func(): _on_chemical_button_pressed("Pseudoephedrine"))
	phosphorus_button.pressed.connect(func(): _on_chemical_button_pressed("Red Phosphorus"))
	iodine_button.pressed.connect(func(): _on_chemical_button_pressed("Iodine"))
	methylamine_button.pressed.connect(func(): _on_chemical_button_pressed("Methylamine"))
	aluminum_button.pressed.connect(func(): _on_chemical_button_pressed("Aluminum"))
	
	# Connect equipment buttons
	heat_button.pressed.connect(_on_heat_button_pressed)
	cool_button.pressed.connect(_on_cool_button_pressed)
	stir_button.pressed.connect(_on_stir_button_pressed)
	crystallize_button.pressed.connect(start_crystallization)
	
	# Connect control panel buttons
	complete_button.pressed.connect(start_crystallization)
	reset_button.pressed.connect(reset_game)
	quit_button.pressed.connect(get_tree().quit)

func update_initial_state():
	temperature_label.text = str(current_temperature) + "°C"
	stirring_label.text = "OFF"
	update_beaker()
	update_ui()
	add_log_entry("Welcome to the meth lab. Begin by adding chemicals in the correct order.", true)

func _on_chemical_button_pressed(chemical_name):
	add_chemical(chemical_name)

func _on_heat_button_pressed():
	apply_heat()

func _on_cool_button_pressed():
	apply_cooling()

func _on_stir_button_pressed():
	toggle_stirring()

func add_chemical(chemical_name):
	if chemicals_added.size() == current_step and current_step < required_chemicals.size():
		if chemical_name == required_chemicals[current_step]:
			chemicals_added.append(chemical_name)
			current_step += 1
			score += 10
			quality += 5.0
			add_log_entry("Added " + chemical_name + " to the mixture.", true)
			
			if current_step == 3:  # After adding first three chemicals
				current_phase = 1
				phase_label.text = "Phase 2: Heat the mixture"
				add_log_entry("Phase 2: Heat the mixture to between " + str(heating_phase_temp_range[0]) + "°C and " + str(heating_phase_temp_range[1]) + "°C", true)
			elif current_step == required_chemicals.size():
				current_phase = 3
				phase_label.text = "Phase 4: Ready to crystallize"
				add_log_entry("All chemicals added. Ready to crystallize when conditions are right.", true)
		else:
			add_log_entry("Wrong chemical! " + chemical_name + " is not what we need right now.", true)
			quality -= 10.0
			score -= 5
		
		update_beaker()
		update_ui()

func apply_heat():
	current_temperature += 5.0
	temperature_label.text = str(current_temperature) + "°C"
	
	if current_phase == 1:  # Heating phase
		check_temperature(1)
	elif current_phase == 2:  # Cooling phase
		add_log_entry("The mixture is too hot! Cool it down.", true)
		quality -= 5.0
	
	update_ui()

func apply_cooling():
	current_temperature -= 5.0
	temperature_label.text = str(current_temperature) + "°C"
	
	if current_phase == 2:  # Cooling phase
		check_temperature(2)
	elif current_phase == 1:  # Heating phase
		add_log_entry("The mixture needs to be hotter!", true)
		quality -= 5.0
	
	update_ui()

func check_temperature(phase):
	if phase == 1:  # Heating phase check
		if current_temperature >= heating_phase_temp_range[0] and current_temperature <= heating_phase_temp_range[1]:
			add_log_entry("Perfect temperature for heating phase!", true)
			score += 15
			quality += 10.0
			current_phase = 2
			phase_label.text = "Phase 3: Cool and stir the mixture"
			add_log_entry("Phase 3: Cool the mixture to between " + str(cooling_phase_temp_range[0]) + "°C and " + str(cooling_phase_temp_range[1]) + "°C and stir", true)
		elif current_temperature > heating_phase_temp_range[1]:
			add_log_entry("Too hot! The mixture is degrading.", true)
			quality -= 10.0
	elif phase == 2:  # Cooling phase check
		if current_temperature >= cooling_phase_temp_range[0] and current_temperature <= cooling_phase_temp_range[1]:
			add_log_entry("Perfect temperature for cooling phase!", true)
			score += 15
			quality += 10.0
		elif current_temperature < cooling_phase_temp_range[0]:
			add_log_entry("Too cold! The reaction is slowing down.", true)
			quality -= 5.0

func toggle_stirring():
	is_stirring = !is_stirring
	stirring_label.text = "ON" if is_stirring else "OFF"
	
	if is_stirring and current_phase == 2:
		add_log_entry("Stirring the mixture - good job!", true)
		score += 10
		quality += 5.0
	elif is_stirring and current_phase != 2:
		add_log_entry("Stirring now isn't necessary.", true)
	
	update_ui()

func start_crystallization():
	if current_phase >= 3 and chemicals_added.size() == required_chemicals.size():
		is_crystallizing = true
		add_log_entry("Starting crystallization process...", true)
		finish_batch()
	else:
		add_log_entry("Not ready to crystallize yet!", true)
		quality -= 10.0
		score -= 10

func finish_batch():
	time_remaining = 0
	
	# Calculate final quality and profit
	quality = clamp(quality, 0.0, 100.0)
	profit = quality * 10.0  # $10 per quality point
	
	add_log_entry("Batch complete!", true)
	add_log_entry("Final Quality: " + str(quality) + "%", true)
	add_log_entry("Final Profit: $" + str(profit), true)
	
	update_ui()

func update_beaker():
	var color_value = clamp(current_step * 0.25, 0, 1.0)
	if beaker_liquid:
		beaker_liquid.modulate = Color(0.2, 0.5 + color_value * 0.5, color_value, 0.8)
		beaker_liquid.scale = Vector2(1.0, 0.2 + current_step * 0.16)

func update_ui():
	quality_bar.value = quality
	quality_bar.get_node("Label").text = str(quality) + "%"
	score_value.text = str(score)
	profit_value.text = "$" + str(profit)

func add_log_entry(text, new_line = false):
	var new_text = ""
	if log_panel.text != "":
		new_text = log_panel.text
		if new_line:
			new_text += "\n"
		else:
			new_text += " "
	new_text += text
	log_panel.text = new_text

func start_timer():
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 1.0
	timer.one_shot = false
	timer.autostart = true
	timer.timeout.connect(func(): time_remaining -= 1.0 if time_remaining > 0 else 0)

func reset_game():
	setup_game()
	update_initial_state()
	add_log_entry("New game started. Mix the initial chemicals in the correct order.", true)

func _process(delta):
	if time_remaining > 0:
		timer_label.text = format_time(time_remaining)
	else:
		timer_label.text = "00:00"
		if !is_crystallizing:
			finish_batch()

func format_time(seconds):
	var mins = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%02d:%02d" % [mins, secs] 