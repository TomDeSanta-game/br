extends CharacterBody2D

func _ready() -> void:
	Grok.register_assistant(self)
	collision_layer = LLM.assistant_layer
	collision_mask = LLM.world_layer | LLM.enemy_layer | LLM.npc_layer | LLM.player_layer