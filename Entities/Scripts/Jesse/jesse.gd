extends CharacterBody2D

# Constants
const ANIMATIONS: Dictionary = {
	"DOWN_IDLE": "Idle_Back",
	"RIGHT_IDLE": "Idle_Right",
	"UP_IDLE": "Idle_Front",
	"DOWN_RUN": "Run_Back",
	"RIGHT_RUN": "Run_Right",
	"UP_RUN": "Run_Front"
}

# Variables
var speed: float = 200.0
var direction: Vector2 = Vector2.ZERO
var is_interact_mode = false
var is_running = false

# References
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	setup_collision()

func setup_collision() -> void:
	collision_layer = LLM.assistant_layer
	collision_mask = LLM.world_layer | LLM.enemy_layer | LLM.npc_layer | LLM.player_layer | LLM.object_layer

func _physics_process(_delta: float) -> void:
	handle_movement()

func handle_movement() -> void:
	var input_vector = get_input_vector()
	
	if input_vector != Vector2.ZERO:
		velocity = input_vector * speed
		direction = input_vector
		handle_running(input_vector)
	else:
		velocity = Vector2.ZERO
		direction = Vector2.ZERO
		handle_idle()
		
	if not is_interact_mode:
		move_and_slide()

func get_input_vector() -> Vector2:
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("RIGHT") - Input.get_action_strength("LEFT")
	input_vector.y = Input.get_action_strength("DOWN") - Input.get_action_strength("UP")
	return input_vector.normalized()

func handle_running(_input_vector: Vector2) -> void:
	is_running = true
	update_animation()

func handle_idle() -> void:
	is_running = false
	update_animation()

func update_animation() -> void:
	if is_running:
		if abs(direction.x) > abs(direction.y):
			animated_sprite.play(ANIMATIONS["RIGHT_RUN"])
			animated_sprite.flip_h = (direction.x < 0)
		elif direction.y > 0:
			animated_sprite.play(ANIMATIONS["UP_RUN"])
		else:
			animated_sprite.play(ANIMATIONS["DOWN_RUN"])
	else:
		if abs(direction.x) > abs(direction.y):
			animated_sprite.play(ANIMATIONS["RIGHT_IDLE"])
			animated_sprite.flip_h = (direction.x < 0)
		elif direction.y > 0:
			animated_sprite.play(ANIMATIONS["DOWN_IDLE"])
		else:
			animated_sprite.play(ANIMATIONS["UP_IDLE"])

func is_player_running() -> bool:
	return is_running