extends Node

var active_camera = null
var player_camera = null
var is_in_surveillance_mode = false
var transition_duration = 0.5
var current_tween = null
var cameras = {}
var player = null
var signal_bus = null

func _ready():
	signal_bus = get_node_or_null("/root/SignalBus")
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if player:
		player_camera = player.get_node_or_null("Camera2D")

func register_camera(camera_node, camera_name):
	cameras[camera_name] = camera_node
	camera_node.enabled = false
	if camera_node.has_signal("body_entered"):
		camera_node.body_entered.connect(_on_camera_area_entered.bind(camera_name))
		
func unregister_camera(camera_name):
	if cameras.has(camera_name):
		cameras.erase(camera_name)

func activate_camera(camera_name):
	if !cameras.has(camera_name) or is_in_surveillance_mode:
		return
		
	var camera = cameras[camera_name]
	active_camera = camera
	
	if player and player_camera:
		player_camera.enabled = false
		
	if current_tween and current_tween.is_valid():
		current_tween.kill()
		
	current_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	# Activate the surveillance camera with a smooth transition
	camera.enabled = true
	camera.zoom = Vector2(0.5, 0.5)
	camera.modulate = Color(1, 1, 1, 0)
	
	current_tween.tween_property(camera, "zoom", Vector2(1, 1), transition_duration)
	current_tween.parallel().tween_property(camera, "modulate", Color(1, 1, 1, 1), transition_duration)
	
	is_in_surveillance_mode = true
	
	# Find the camera node parent to get additional data
	var camera_node_parent = null
	for node in get_tree().get_nodes_in_group("surveillance_camera"):
		if node.camera_id == camera_name:
			camera_node_parent = node
			break
	
	var camera_data = {"camera_node": camera}
	if camera_node_parent and camera_node_parent.has_method("get_camera_data"):
		camera_data = camera_node_parent.get_camera_data()
	
	if signal_bus:
		signal_bus.emit_signal("surveillance_camera_activated", camera_name, camera_data)
		signal_bus.emit_signal("surveillance_mode_changed", true)
		signal_bus.emit_signal("player_state_changed", "surveillance", true)

func deactivate_current_camera():
	if !is_in_surveillance_mode or !active_camera:
		return
		
	if current_tween and current_tween.is_valid():
		current_tween.kill()
		
	current_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	
	# Deactivate with a transition effect
	current_tween.tween_property(active_camera, "zoom", Vector2(0.5, 0.5), transition_duration)
	current_tween.parallel().tween_property(active_camera, "modulate", Color(1, 1, 1, 0), transition_duration)
	
	current_tween.tween_callback(func():
		active_camera.enabled = false
		if player and player_camera:
			player_camera.enabled = true
		is_in_surveillance_mode = false
		
		for camera_name in cameras.keys():
			if cameras[camera_name] == active_camera:
				if signal_bus:
					signal_bus.emit_signal("surveillance_camera_deactivated", camera_name)
					signal_bus.emit_signal("surveillance_mode_changed", false)
					signal_bus.emit_signal("player_state_changed", "surveillance", false)
				break
				
		active_camera = null
	)

func switch_camera(camera_name):
	if !cameras.has(camera_name) or !is_in_surveillance_mode:
		return
		
	if active_camera == cameras[camera_name]:
		return
		
	if current_tween and current_tween.is_valid():
		current_tween.kill()
		
	# First deactivate current camera
	current_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	current_tween.tween_property(active_camera, "modulate", Color(1, 1, 1, 0), transition_duration / 2)
	
	current_tween.tween_callback(func():
		active_camera.enabled = false
		for current_name in cameras.keys():
			if cameras[current_name] == active_camera:
				if signal_bus:
					signal_bus.emit_signal("surveillance_camera_deactivated", current_name)
				break
				
		# Activate new camera
		active_camera = cameras[camera_name]
		active_camera.enabled = true
		active_camera.modulate = Color(1, 1, 1, 0)
		
		var new_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		new_tween.tween_property(active_camera, "modulate", Color(1, 1, 1, 1), transition_duration / 2)
		
		# Find the camera node parent to get additional data
		var camera_node_parent = null
		for node in get_tree().get_nodes_in_group("surveillance_camera"):
			if node.camera_id == camera_name:
				camera_node_parent = node
				break
		
		var camera_data = {"camera_node": active_camera}
		if camera_node_parent and camera_node_parent.has_method("get_camera_data"):
			camera_data = camera_node_parent.get_camera_data()
			
		if signal_bus:
			signal_bus.emit_signal("surveillance_camera_activated", camera_name, camera_data)
	)

func _on_camera_area_entered(body, camera_name):
	if body == player and !is_in_surveillance_mode:
		if signal_bus:
			signal_bus.emit_signal("show_alert_message", "Press E to access surveillance camera")

func _input(event):
	if event.is_action_pressed("ui_cancel") and is_in_surveillance_mode:
		deactivate_current_camera()
	
	# Number keys to quickly switch between cameras
	if is_in_surveillance_mode:
		for i in range(1, 10):
			if event.is_action_pressed("ui_" + str(i)):
				var camera_index = i - 1
				if camera_index < cameras.size():
					var camera_name = cameras.keys()[camera_index]
					switch_camera(camera_name)
					break 