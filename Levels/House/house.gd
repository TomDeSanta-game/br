extends Node2D
@onready var player: Node2D = $Player
@onready var car: Area2D = $CarCollidor
@onready var Dialogic = get_node("/root/Dialogic")
var car_entered: bool = false
var quest: Quest = load("res:
func _ready() -> void:
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	player.hide_ui(true)
	Dialogic.timeline_ended.connect(on_dialog_timeline_ended)
	register_console_commands()
	car.body_entered.connect(_on_car_body_entered)
	await get_tree().create_timer(1.0).timeout
	Dialogic.start("walter-skyler-jr-1st-inter")
func register_console_commands() -> void:
	if LimboConsole:
		LimboConsole.register_command(end_dialogic, "end_dialogic")
func end_dialogic(_args = null) -> String:
	if Dialogic.current_timeline:
		Dialogic.end_timeline()
		return "Timeline ended"
	return "No active timeline to end"
func on_dialog_timeline_ended() -> void:
	player.set_physics_process(true)
	player.set_process_unhandled_input(true)
	player.hide_ui(false)
	QuestSystem.start_quest(quest)
	player.show_objective(quest.quest_objective)
	player.position.x = 5
func _on_car_body_entered(body: Node2D) -> void:
	if car_entered:
		return
	if body == player:
		car_entered = true
		QuestSystem.complete_quest(quest)
		player.complete_objective()
		player.hide()
		player.set_physics_process(false)
		player.set_process_unhandled_input(false)
		player.hide_ui(true)
		$AnimationPlayer.play("CAR")
		await get_tree().create_timer(1.0).timeout
		SceneManager.change_scene("res: