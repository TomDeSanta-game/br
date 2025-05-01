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

# Node references (initialized in _ready to prevent crashes)
var temperature_label: Label
var beaker: Control
var beaker_liquid: Panel
var phase_label: Label

func _ready():
	# Wait one frame to make sure all nodes are properly initialized
	await get_tree().process_frame
	
	# Initialize node references safely
	initialize_node_references()
	
	# Setup game state
	setup_game()

func initialize_node_references():
	# Find nodes using safe methods
	var temp_path = "MainContainer/VBoxContainer/ContentContainer/LeftColumn/EquipmentPanel/VBoxContainer/TemperatureContainer/TemperatureValue"
	temperature_label = get_node_or_null(temp_path)
	
	var beaker_path = "MainContainer/VBoxContainer/ContentContainer/CenterColumn/BeakerPanel/BeakerContainer/Beaker"
	beaker = get_node_or_null(beaker_path)
	
	if beaker:
		beaker_liquid = beaker.get_node_or_null("BeakerLiquid")
	
	var phase_path = "MainContainer/VBoxContainer/ContentContainer/CenterColumn/BeakerPanel/BeakerContainer/PhaseValue"
	phase_label = get_node_or_null(phase_path)

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
	
	if is_instance_valid(phase_label):
		phase_label.text = "Phase 1: Mix initial chemicals"
	
	update_beaker()

func update_beaker():
	if is_instance_valid(beaker_liquid):
		var color_value = clamp(current_step * 0.25, 0, 1.0)
		beaker_liquid.modulate = Color(0.2, 0.5 + color_value * 0.5, color_value, 0.8)
		beaker_liquid.scale = Vector2(1.0, 0.2 + current_step * 0.16) 