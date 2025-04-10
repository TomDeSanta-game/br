extends Node

@onready var player: Node2D = $Player

func _ready() -> void:
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	player.hide_ui(true)