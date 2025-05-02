extends BTAction
@export var target_pos: StringName = &"position"
@export var direction: StringName = &"direction"
@export var speed: float = 100.0
@export var tolerance: float = 10.0
func _tick(delta: float) -> Status:
    var target_position: Vector2 = blackboard.get_var(target_pos, agent.global_position)
    
    
    if agent.global_position.distance_to(target_position) < tolerance:
        return SUCCESS
    
    
    var dir: String = blackboard.get_var(direction, "right")
    var velocity := Vector2.ZERO
    
    match dir:
        "up":
            velocity.y = -speed * delta
        "down":
            velocity.y = speed * delta
        "left":
            velocity.x = -speed * delta
        "right":
            velocity.x = speed * delta
    
    agent.global_position += velocity
    return RUNNING