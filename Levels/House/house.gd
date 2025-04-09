extends Node2D

@onready var player = $Player

func _ready() -> void:
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	player.hide_ui(true)
	Dialogic.timeline_ended.connect(dte)
	register_console_commands()
	await get_tree().create_timer(1.0).timeout
	Dialogic.start("walter-skyler-jr-1st-inter")

func register_console_commands() -> void:
	if LimboConsole:
		LimboConsole.register_command(end_dialogic, "end_dialogic")

func end_dialogic(_args = null) -> String:
	if Dialogic.current_timeline:
		Dialogic.end_timeline()
		dte()
		return "Timeline ended"
	return "No active timeline to end"

func dte() -> void:
	player.set_physics_process(true)
	player.set_process_unhandled_input(true)
	player.hide_ui(false)
	
	player.position.x = 5