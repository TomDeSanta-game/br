extends Node2D

var rise_speed = 0
var wobble_speed = 0
var wobble_amount = 0
var lifetime = 0
var max_size = 0
var current_size = 0
var growth_speed = 0
var start_pos = Vector2.ZERO

func _ready():
	# Initialize random properties
	rise_speed = randf_range(20, 50)
	wobble_speed = randf_range(1, 3)
	wobble_amount = randf_range(5, 20)
	lifetime = randf_range(1.5, 3.0)
	max_size = randf_range(5, 15)
	current_size = 1
	growth_speed = randf_range(10, 20)
	start_pos = position
	
	# Start the death timer
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)
	
	# Create the bubble visuals
	var bubble = ColorRect.new()
	bubble.size = Vector2(current_size, current_size)
	bubble.position = Vector2(-current_size/2, -current_size/2)
	bubble.color = Color(randf_range(0.7, 1.0), randf_range(0.7, 1.0), randf_range(0.7, 1.0), randf_range(0.2, 0.7))
	add_child(bubble)

func _process(delta):
	# Rise up
	position.y -= rise_speed * delta
	
	# Wobble side to side
	position.x = start_pos.x + sin(Time.get_ticks_msec() * 0.001 * wobble_speed) * wobble_amount
	
	# Grow the bubble until max size
	if current_size < max_size:
		current_size += growth_speed * delta
		
		# Update the child ColorRect size
		if get_child_count() > 0:
			var bubble = get_child(0)
			bubble.size = Vector2(current_size, current_size)
			bubble.position = Vector2(-current_size/2, -current_size/2)
	
	# Fade out near the end of lifetime
	if lifetime < 0.5:
		modulate.a = lifetime / 0.5 