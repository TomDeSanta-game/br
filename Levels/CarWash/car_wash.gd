extends Node2D

var player_in_office: bool = false
var player_in_wash_area: bool = false
var player_in_lobby: bool = false

var player: Node2D

const PIXELATED_RESOLUTION = Vector2(1152, 648)
const A1A_SLOGAN = "Have an A1 day!"

@onready var game_viewport = $GameViewport
@onready var viewport_display = $ViewportDisplay
@onready var grid_visualizer = $GameViewport/GridVisualizer

func _ready():
	setup_viewport()
	create_player_placeholder()
	
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 6.0
	timer.one_shot = false
	timer.timeout.connect(show_a1a_slogan)
	timer.start()

func show_a1a_slogan():
	if player_in_lobby or player_in_office:
		print(A1A_SLOGAN)
		
		if randf() < 0.2:
			var skyler_quotes = [
				"We're just getting started.",
				"This car wash is for laundering money, not cars.",
				"We need to look legit to the auditors.",
				"Business has been steady.",
				"We have the best equipment, the best location."
			]
			var random_quote = skyler_quotes[randi() % skyler_quotes.size()]
			await get_tree().create_timer(1.0).timeout
			print("Skyler: " + random_quote)

func setup_viewport():
	if game_viewport and viewport_display:
		viewport_display.texture = game_viewport.get_texture()
		get_tree().root.connect("size_changed", Callable(self, "_on_window_resized"))
		_on_window_resized()

func _on_window_resized():
	if viewport_display:
		var window_size = get_viewport_rect().size
		viewport_display.scale = Vector2(1, 1)
		
		var target_size = PIXELATED_RESOLUTION
		var scale_factor = min(window_size.x / target_size.x, window_size.y / target_size.y)
		if scale_factor < 1:
			scale_factor = 1
		viewport_display.scale = Vector2(scale_factor, scale_factor)
		
		var scaled_size = Vector2(target_size.x * scale_factor, target_size.y * scale_factor)
		viewport_display.position = (window_size - scaled_size) / 2

func create_player_placeholder():
	var placeholder = Node2D.new()
	placeholder.name = "PlayerPlaceholder"
	
	var sprite = ColorRect.new()
	sprite.color = Color(0, 0, 0, 1)
	sprite.size = Vector2(16, 16)
	sprite.position = Vector2(-8, -8)
	placeholder.add_child(sprite)
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(16, 16)
	collision.shape = shape
	
	var body = CharacterBody2D.new()
	body.add_child(collision)
	body.collision_layer = 2
	body.add_to_group("Player")
	body.name = "Body"
	placeholder.add_child(body)
	
	var start_pos = $GameViewport/PlayerStartPosition
	if start_pos:
		placeholder.global_position = start_pos.global_position
	else:
		placeholder.global_position = Vector2(576, 568)
	
	game_viewport.add_child(placeholder)
	player = placeholder
	
	print("Welcome to A1A Car Wash - Have an A1 Day!")
	await get_tree().create_timer(1.0).timeout
	print("Explore the area or talk to Skyler in the office.")

func _process(_delta):
	if player and player.has_node("Body"):
		var body = player.get_node("Body")
		var direction = Vector2.ZERO
		
		if Input.is_action_pressed("ui_right"):
			direction.x += 1
		if Input.is_action_pressed("ui_left"):
			direction.x -= 1
		if Input.is_action_pressed("ui_down"):
			direction.y += 1
		if Input.is_action_pressed("ui_up"):
			direction.y -= 1
		
		direction = direction.normalized()
		
		if direction != Vector2.ZERO:
			body.velocity = direction * 200
		else:
			body.velocity = Vector2.ZERO
		
		body.move_and_slide()
		player.global_position = body.global_position

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if grid_visualizer and grid_visualizer.has_method("toggle_grid"):
			grid_visualizer.toggle_grid()
	
	if event.is_action_pressed("INTERACT"):
		check_interactions()

func check_interactions():
	if player_in_office:
		var office_dialogue = [
			"Skyler: Welcome to A1A Car Wash.",
			"Skyler: We have the best cleaning products in town.",
			"Skyler: Would you like the basic wash or deluxe service?"
		]
		var rand_dialogue = office_dialogue[randi() % office_dialogue.size()]
		print(rand_dialogue)
		
	elif player_in_wash_area:
		var wash_dialogue = [
			"Walter: I used to work here before... you know.",
			"Walter: Make sure you don't miss any spots.",
			"Walter: Chemistry is the study of change."
		]
		var rand_dialogue = wash_dialogue[randi() % wash_dialogue.size()]
		print(rand_dialogue)
		
	elif player_in_lobby:
		var lobby_dialogue = [
			"Bogdan: Have an A1 day!",
			"Bogdan: As for your eyebrows... *raises eyebrows*",
			"Bogdan: Why don't you handle the register for once?"
		]
		var rand_dialogue = lobby_dialogue[randi() % lobby_dialogue.size()]
		print(rand_dialogue)

func _on_office_area_body_entered(body):
	if body.is_in_group("Player"):
		player_in_office = true
		print("Player entered office area")
		print("Skyler: Welcome to A1A Car Wash. Have an A1 day!")

func _on_office_area_body_exited(body):
	if body.is_in_group("Player"):
		player_in_office = false
		print("Player exited office area")

func _on_wash_area_body_entered(body):
	if body.is_in_group("Player"):
		player_in_wash_area = true
		print("Player entered wash area")
		print("Walter: *scrubs vigorously*")

func _on_wash_area_body_exited(body):
	if body.is_in_group("Player"):
		player_in_wash_area = false
		print("Player exited wash area")

func _on_lobby_area_body_entered(body):
	if body.is_in_group("Player"):
		player_in_lobby = true
		print("Player entered lobby area")
		print("Bogdan: Have an A1 day!")

func _on_lobby_area_body_exited(body):
	if body.is_in_group("Player"):
		player_in_lobby = false
		print("Player exited lobby area") 