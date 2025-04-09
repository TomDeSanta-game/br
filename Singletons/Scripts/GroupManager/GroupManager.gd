extends Node

var player: Node2D = null
var assistant: Node2D = null
var hank: Node2D = null
var skinny_pete: Node2D = null
var tuco: Node2D = null
var inventory: Control = null
 
func register_player(player_node: Node2D) -> void:
	player = player_node

func register_assistant(assistant_node: Node2D) -> void:
	assistant = assistant_node

func register_hank(hank_node: Node2D) -> void:
	hank = hank_node

func register_skinny_pete(skinny_pete_node: Node2D) -> void:
	skinny_pete = skinny_pete_node

func register_tuco(tuco_node: Node2D) -> void:
	tuco = tuco_node

func register_inventory(inventory_node: Control) -> void:
	inventory = inventory_node