extends Node2D
@onready var player = $Player
@onready var doctor = $Doctor
var scene_initialized = false
var objective_shown = false
func _ready():
	if player:
		player.set_physics_process(false)
		player.set_process_unhandled_input(false)
		player.hide_ui(true)
	await get_tree().create_timer(1.0).timeout
	var tween = create_tween()
	tween.tween_property($ColorRect, "color:a", 0.0, 1.5)
	await tween.finished
	if player:
		player.set_physics_process(true)
		player.set_process_unhandled_input(true)
		player.hide_ui(false)
		if player.has_method("show_thought"):
			player.show_thought("The doctor should have my test results today...", 4.0)
		if player.has_method("show_styled_objective") and not objective_shown:
			player.show_styled_objective("Doctor's Appointment", "Speak with the doctor about your condition", 5.0)
			objective_shown = true
	scene_initialized = true
func _process(_delta):
	if not scene_initialized:
		return
func exit_scene():
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	player.hide_ui(true)
	var tween = create_tween()
	tween.tween_property($ColorRect, "color:a", 1.0, 1.5)
	await tween.finished
	SceneManager.change_scene("res: