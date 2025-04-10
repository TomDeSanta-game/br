extends Node

var player: Node2D = null
var inventory: Control = null
 
func register_player(player_node: Node2D) -> void:
	player = player_node

func register_inventory(inventory_node: Control) -> void:
	inventory = inventory_node