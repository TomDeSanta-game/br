extends Node

signal camera_activated(camera_name)
signal camera_deactivated
signal returned_to_player_view

var _cameras = {}
var _current_camera = null
var _previous_player_state = null
var _player_camera = null
var _transition_time = 0.5
var _is_active = false

func _ready():
	print("Surveillance Camera System initialized")

func register_camera(camera: Camera2D, camera_name: String):
	_cameras[camera_name] = camera
	print("Camera registered: " + camera_name)

func register_player_camera(camera: Camera2D):
	_player_camera = camera
	print("Player camera registered")

func activate_camera(camera_name: String):
	if !_cameras.has(camera_name):
		push_error("Camera not found: " + camera_name)
		return false
	
	if _is_active and _current_camera == _cameras[camera_name]:
		return true  # Already active
	
	if _player_camera == null:
		push_error("Player camera not registered")
		return false
	
	# Store player camera enabled state before disabling
	if !_is_active:
		_previous_player_state = _player_camera.enabled
		# Freeze player if in a CharacterBody
		var player = _player_camera.get_parent()
		if player is CharacterBody2D:
			player.set_process_input(false)
			player.set_physics_process(false)
	
	# Disable player camera
	_player_camera.enabled = false
	
	# If another camera is active, disable it first
	if _is_active and _current_camera != null:
		_current_camera.enabled = false
		
	# Enable new camera with transition
	var camera = _cameras[camera_name]
	camera.enabled = true
	
	# Apply transition effect if needed
	if _transition_time > 0:
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 10.0
	
	_current_camera = camera
	_is_active = true
	
	emit_signal("camera_activated", camera_name)
	return true

func deactivate_current_camera():
	if !_is_active or _current_camera == null:
		return false
	
	if _player_camera == null:
		push_error("Player camera not registered")
		return false
	
	# Disable current camera
	_current_camera.enabled = false
	_current_camera = null
	
	# Restore player camera
	_player_camera.enabled = _previous_player_state
	
	# Unfreeze player if in a CharacterBody
	var player = _player_camera.get_parent()
	if player is CharacterBody2D:
		player.set_process_input(true)
		player.set_physics_process(true)
	
	_is_active = false
	
	emit_signal("camera_deactivated")
	emit_signal("returned_to_player_view")
	return true

func switch_camera(camera_name: String):
	if !_is_active:
		return activate_camera(camera_name)
	
	if !_cameras.has(camera_name):
		push_error("Camera not found: " + camera_name)
		return false
		
	if _current_camera == _cameras[camera_name]:
		return true  # Already on this camera
	
	# Disable current camera
	_current_camera.enabled = false
	
	# Enable new camera
	var camera = _cameras[camera_name]
	camera.enabled = true
	
	# Apply transition effect if needed
	if _transition_time > 0:
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 10.0
	
	_current_camera = camera
	
	emit_signal("camera_activated", camera_name)
	return true

func get_active_camera():
	return _current_camera

func is_active():
	return _is_active

func _input(event):
	if !_is_active:
		return
		
	if event.is_action_pressed("ui_cancel"):
		deactivate_current_camera()
		
	# Handle number keys for quick camera switching
	if event is InputEventKey and event.pressed:
		var camera_index = -1
		
		# Check if it's a number key 1-9
		if event.keycode >= KEY_1 and event.keycode <= KEY_9:
			camera_index = event.keycode - KEY_1
			
		if camera_index >= 0 and camera_index < _cameras.size():
			var camera_name = _cameras.keys()[camera_index]
			switch_camera(camera_name) 