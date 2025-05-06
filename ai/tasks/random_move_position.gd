extends BTAction
var range_min_in_dir: float = 50.0
var range_max_in_dir: float = 100.0
var pos_var: StringName = &"position"
var direction_var: StringName = &"direction"
func _tick(_delta: float) -> Status:
    var direction := random_direction()
    var position := random_position(direction)
    blackboard.set_var(pos_var, position)
    return SUCCESS
func random_position(direction: String) -> Vector2:
    var vector := Vector2.ZERO
    var distance := randf_range(range_min_in_dir, range_max_in_dir)
    match direction:
        "up":
            vector.y = -distance
        "down":
            vector.y = distance
        "left":
            vector.x = -distance
        "right":
            vector.x = distance
    vector += agent.global_position
    return vector
func random_direction() -> String:
    var directions: Array[String] = ["up", "down", "left", "right"]
    var direction: String = directions[randi_range(0, 3)]
    blackboard.set_var(direction_var, direction)
    return direction