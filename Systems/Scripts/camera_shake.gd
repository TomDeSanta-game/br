extends Camera2D
@export var decay = 0.8
@export var max_offset = Vector2(100, 75)
@export var max_roll = 0.1
@export var trauma_power = 2
var trauma = 0.0
var noise
var noise_y = 0
func _ready():
	randomize()
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = randi()
	noise.frequency = 0.5
func _process(delta):
	if trauma > 0:
		trauma = max(trauma - decay * delta, 0)
		shake()
func add_trauma(amount):
	trauma = min(trauma + amount, 1.0)
func shake():
	var amount = pow(trauma, trauma_power)
	noise_y += 1
	rotation = max_roll * amount * noise.get_noise_2d(noise.seed, noise_y)
	offset.x = max_offset.x * amount * noise.get_noise_2d(noise.seed * 2, noise_y)
	offset.y = max_offset.y * amount * noise.get_noise_2d(noise.seed * 3, noise_y)
func reset_shake():
	trauma = 0.0
	rotation = 0.0
	offset = Vector2.ZERO