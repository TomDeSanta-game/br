extends Node2D

var rise_speed = 20.0
var lifetime = 0.0
var max_lifetime = 3.0
var wiggle_amount = 2.0
var wiggle_speed = 3.0
var start_scale = 1.0
var fade_start = 0.7  # When to start fading (as fraction of lifetime)

func _ready():
	# Add to bubble group for easy management
	add_to_group("bubble")
	
	# Randomize properties for variety
	rise_speed = randf_range(15.0, 25.0)
	max_lifetime = randf_range(2.0, 4.0)
	wiggle_amount = randf_range(1.0, 3.0)
	wiggle_speed = randf_range(2.0, 4.0)
	
	# Create bubble visual
	var bubble = ColorRect.new()
	bubble.size = Vector2(4, 4)
	bubble.color = Color(1, 1, 1, 0.7)
	add_child(bubble)
	
	# Store original scale
	start_scale = scale.x

func _process(delta):
	lifetime += delta
	
	# Rise upward
	position.y -= rise_speed * delta
	
	# Add wiggly motion
	position.x += sin(lifetime * wiggle_speed) * wiggle_amount * delta
	
	# Fade out as it rises
	if lifetime > max_lifetime * fade_start:
		var fade_progress = (lifetime - max_lifetime * fade_start) / (max_lifetime * (1.0 - fade_start))
		modulate.a = 1.0 - fade_progress
	
	# Grow slightly as it rises
	var size_factor = 1.0 + lifetime * 0.1
	scale = Vector2(start_scale, start_scale) * size_factor
	
	# Remove when lifetime is over
	if lifetime >= max_lifetime:
		queue_free() 