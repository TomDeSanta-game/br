extends Control

var current_step := 0
var beaker_liquid: Panel
var phase_label: Label

func _ready():
	initialize_node_references()
	update_beaker()

func initialize_node_references():
	var beaker = get_node_or_null("MainContainer/VBoxContainer/ContentContainer/BeakerPanel/BeakerContainer/Beaker")
	if beaker:
		beaker_liquid = beaker.get_node_or_null("BeakerLiquid")
	
	phase_label = get_node_or_null("MainContainer/VBoxContainer/ContentContainer/BeakerPanel/BeakerContainer/PhaseValue")

func update_beaker():
	if is_instance_valid(beaker_liquid):
		var color_value = clamp(current_step * 0.25, 0, 1.0)
		beaker_liquid.modulate = Color(0.2, 0.5 + color_value * 0.5, color_value, 0.8)
		beaker_liquid.scale = Vector2(1.0, 0.2 + current_step * 0.16)

func _on_start_button_pressed():
	current_step += 1
	update_beaker()
	
	if is_instance_valid(phase_label):
		phase_label.text = "Phase %d: Processing..." % (current_step + 1)

func _on_exit_button_pressed():
	get_tree().change_scene_to_file("res://Levels/House/House.tscn") 