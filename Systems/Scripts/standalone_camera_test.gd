extends Node2D

func _ready():
	print("Starting standalone camera test")
	
	# Create player with camera
	var player = create_player()
	add_child(player)
	
	# Create test cameras without depending on other systems
	var camera1 = create_camera("camera_1", Vector2(200, 0), Color.RED)
	var camera2 = create_camera("camera_2", Vector2(-200, 0), Color.BLUE)
	var camera3 = create_camera("camera_3", Vector2(0, 200), Color.GREEN)
	
	add_child(camera1)
	add_child(camera2)
	add_child(camera3)
	
	# Add test UI
	create_ui()
	
	# Wait a frame to ensure cameras are in the scene tree
	await get_tree().process_frame
	
	# Register cameras manually since the dynamic script might not be ready yet
	register_cameras()
	
	print("Camera test setup completed")

func register_cameras():
	var cameras = get_tree().get_nodes_in_group("test_cameras")
	if Engine.has_singleton("SurveillanceCameraSystem"):
		var system = Engine.get_singleton("SurveillanceCameraSystem")
		for camera_node in cameras:
			var camera = camera_node.get_node("Camera2D")
			var id = camera_node.get_meta("camera_id")
			if camera and id:
				system.register_camera(camera, id)
				print("Camera " + id + " registered")

func create_player():
	var player = CharacterBody2D.new()
	player.name = "Player"
	player.add_to_group("player")
	
	var sprite = Sprite2D.new()
	sprite.texture = create_colored_texture(Color.WHITE)
	player.add_child(sprite)
	
	var player_camera = Camera2D.new()
	player_camera.enabled = true
	player.add_child(player_camera)
	
	# Directly register with the system
	if Engine.has_singleton("SurveillanceCameraSystem"):
		var system = Engine.get_singleton("SurveillanceCameraSystem")
		system.register_player_camera(player_camera)
	
	return player

func create_camera(id: String, camera_position: Vector2, color: Color):
	var camera_node = Node2D.new()
	camera_node.name = "Camera_" + id
	camera_node.position = camera_position
	
	var sprite = Sprite2D.new()
	sprite.texture = create_colored_texture(color)
	camera_node.add_child(sprite)
	
	var camera = Camera2D.new()
	camera.name = "Camera2D"
	camera.enabled = false
	camera_node.add_child(camera)
	
	var label = Label.new()
	label.name = "Label"
	label.text = "Camera " + id
	label.position = Vector2(-50, -70)
	camera_node.add_child(label)
	
	# Set basic properties directly without dynamic script
	camera_node.set_meta("camera_id", id)
	camera_node.add_to_group("test_cameras")
	
	return camera_node

func create_colored_texture(color: Color):
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(color)
	var texture = ImageTexture.create_from_image(image)
	return texture

func create_ui():
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100  # Ensure it's on top
	add_child(canvas_layer)
	
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel.custom_minimum_size = Vector2(0, 80)
	canvas_layer.add_child(panel)
	
	var label = Label.new()
	label.text = "STANDALONE TEST - Press keys 1-3 to switch cameras, ESC to exit camera view"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(label)
	
func _input(event):
	if event is InputEventKey and event.pressed:
		var key_num = event.keycode - KEY_1
		if key_num >= 0 and key_num <= 2 and Engine.has_singleton("SurveillanceCameraSystem"):
			var system = Engine.get_singleton("SurveillanceCameraSystem")
			var cameras = get_tree().get_nodes_in_group("test_cameras")
			if key_num < cameras.size():
				var id = cameras[key_num].get_meta("camera_id")
				system.activate_camera(id)
				print("Activating camera: " + id)
		elif event.keycode == KEY_ESCAPE and Engine.has_singleton("SurveillanceCameraSystem"):
			var system = Engine.get_singleton("SurveillanceCameraSystem")
			system.deactivate_current_camera()
			print("Deactivating current camera") 