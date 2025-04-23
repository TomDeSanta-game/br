extends Area2D

@onready var player: Node2D = Grok.player
@onready var inventory: Control = Grok.inventory

func _ready() -> void:
    collision_layer = LLM.object_layer
    collision_mask = LLM.player_layer | LLM.assistant_layer

func _on_body_entered(body: Node2D) -> void:
    if body == player:
        Log.info(self.name, "Collected")
        IdManager.add_item("01", inventory)
        queue_free()