extends Area2D
@onready var player: Node2D = get_tree().get_first_node_in_group("Player")
@onready var sparkles: CPUParticles2D = $CrystalContainer/Sparkles
@onready var crystal1: Polygon2D = $CrystalContainer/Crystal1
@onready var crystal2: Polygon2D = $CrystalContainer/Crystal2
@onready var crystal3: Polygon2D = $CrystalContainer/Crystal3

func _ready() -> void:
    collision_layer = LLM.object_layer
    collision_mask = LLM.player_layer | LLM.assistant_layer
    randomize()

    crystal1.color = crystal1.color.lightened(randf_range(-0.1, 0.1))
    crystal2.color = crystal2.color.lightened(randf_range(-0.1, 0.1))
    crystal3.color = crystal3.color.lightened(randf_range(-0.1, 0.1))

func _on_body_entered(body: Node2D) -> void:
    if body == player:
        sparkles.emitting = true
        

        var tween = create_tween().set_parallel(true)
        tween.tween_property($CrystalContainer, "scale", Vector2(0.1, 0.1), 0.4).set_ease(Tween.EASE_IN)
        tween.tween_property($CrystalContainer, "rotation", randf_range(-PI, PI), 0.4)
        tween.tween_property(crystal1, "color:a", 0.0, 0.4)
        tween.tween_property(crystal2, "color:a", 0.0, 0.4)
        tween.tween_property(crystal3, "color:a", 0.0, 0.4)
        

        await get_tree().create_timer(0.5).timeout
        
        Log.info(self.name, "Collected")
        SignalBus.emit_signal("meth_batch_collected", "01")
        queue_free()

func _on_glow_timer_timeout() -> void:

    if randf() > 0.3:
        animate_crystal_glow()
    

    if randf() > 0.7:
        sparkles.emitting = true

func animate_crystal_glow() -> void:

    var crystal = [crystal1, crystal2, crystal3][randi() % 3]
    

    var original_color = crystal.color
    

    var tween = create_tween()
    tween.tween_property(crystal, "color", crystal.color.lightened(0.3), 0.3)
    tween.tween_property(crystal, "color", original_color, 0.5)