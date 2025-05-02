extends CharacterBody2D
var speaking = false
var player_nearby = false
func _ready():
	add_to_group("Interactable")
func interact(player):
	if speaking:
		return
		
	speaking = true
	
	
	if Dialogic.has_subsystem("Timeline"):
		Dialogic.timeline_ended.connect(_on_dialogue_ended)
		Dialogic.start("doctor-appointment")
	
	
	if player.has_method("show_thought"):
		player.show_thought("I should talk to the doctor about my condition.", 3.0)
func _on_dialogue_ended():
	speaking = false
	Dialogic.timeline_ended.disconnect(_on_dialogue_ended)
	
	
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_method("show_styled_objective"):
		player.show_styled_objective("Medical Consultation", "Get your prescription and leave the office", 5.0) 