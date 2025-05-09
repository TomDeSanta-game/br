extends Node

signal camera_activated(camera_name: String)
signal camera_deactivated(camera_name: String)
signal returned_to_player_view

var _cameras = {}
var _current_camera = null
var _previous_player_state = null
var _player_camera = null
var _transition_time = 0.5
var _is_active = false
var _initialized = false

func _ready():
	if SignalBus:
		SignalBus.surveillance_activate_camera.connect(_on_surveillance_activate_camera)
		SignalBus.surveillance_deactivate_camera.connect(_on_surveillance_deactivate_camera)
		SignalBus.surveillance_switch_camera.connect(_on_surveillance_switch_camera)
	else:
		push_error("SignalBus not found. Surveillance camera system will not work correctly.")
	
	add_to_group("persistence")
	_initialized = true

func register_camera(camera_node: Camera2D, camera_name: String):
	if not camera_node:
		push_error("Attempted to register null camera node with name " + camera_name)
		return
	
	if _cameras.has(camera_name):
		push_warning("Camera with name " + camera_name + " already registered")
		return
	
	_cameras[camera_name] = camera_node
	camera_node.enabled = false

func register_player_camera(camera: Camera2D):
	if not camera:
		push_error("Attempted to register null player camera")
		return
		
	_player_camera = camera

func _on_surveillance_activate_camera(camera_name: String):
	activate_camera(camera_name)

func _on_surveillance_deactivate_camera():
	deactivate_current_camera()

func _on_surveillance_switch_camera(camera_name: String):
	switch_camera(camera_name)

func set_transition_time(time: float):
	if time < 0:
		push_warning("Transition time must be positive, using default value")
		return
		
	_transition_time = time

func activate_camera(camera_name: String, transition: bool = true):
	if not _initialized:
		push_error("Surveillance camera system not initialized")
		return
		
	if _is_active:
		push_warning("Already viewing through surveillance camera. Deactivate current first.")
		return
	
	if not _cameras.has(camera_name):
		push_error("Camera with name " + camera_name + " not registered")
		return
	
	if _player_camera == null:
		push_error("Player camera not registered. Cannot activate surveillance camera.")
		return
	
	var player = get_tree().get_nodes_in_group("player")
	if player.size() > 0:
		player = player[0]
		if player.has_method("get_current_state"):
			_previous_player_state = player.get_current_state()
			player.set_state("frozen")
	
	_current_camera = _cameras[camera_name]
	
	if transition:
		_transition_to_camera(_current_camera)
	else:
		_player_camera.enabled = false
		_current_camera.enabled = true
	
	_is_active = true
	emit_signal("camera_activated", camera_name)

func deactivate_current_camera(transition: bool = true):
	if not _is_active or _current_camera == null:
		return
	
	var current_camera_name
	for key in _cameras:
		if _cameras[key] == _current_camera:
			current_camera_name = key
			break
	
	if transition:
		_transition_to_camera(_player_camera)
	else:
		_current_camera.enabled = false
		_player_camera.enabled = true
	
	_current_camera = null
	
	var player = get_tree().get_nodes_in_group("player")
	if player.size() > 0 and _previous_player_state != null:
		player = player[0]
		if player.has_method("set_state"):
			player.set_state(_previous_player_state)
		_previous_player_state = null
	
	_is_active = false
	emit_signal("camera_deactivated", current_camera_name)
	emit_signal("returned_to_player_view")

func switch_camera(camera_name: String):
	if not _is_active:
		activate_camera(camera_name)
		return
	
	if not _cameras.has(camera_name):
		push_error("Camera with name " + camera_name + " not registered")
		return
	
	var previous_camera = _current_camera
	var previous_camera_name
	
	for key in _cameras:
		if _cameras[key] == _current_camera:
			previous_camera_name = key
			break
	
	_current_camera = _cameras[camera_name]
	
	_transition_between_cameras(previous_camera, _current_camera)
	
	emit_signal("camera_deactivated", previous_camera_name)
	emit_signal("camera_activated", camera_name)

func _transition_to_camera(target_camera: Camera2D):
	var tween = create_tween()
	tween.tween_callback(func(): target_camera.enabled = true)
	tween.tween_interval(_transition_time)
	tween.tween_callback(func(): 
		if target_camera != _player_camera:
			_player_camera.enabled = false
		else:
			_current_camera.enabled = false
	)

func _transition_between_cameras(from_camera: Camera2D, to_camera: Camera2D):
	var tween = create_tween()
	tween.tween_callback(func(): to_camera.enabled = true)
	tween.tween_interval(_transition_time)
	tween.tween_callback(func(): from_camera.enabled = false)

func is_active() -> bool:
	return _is_active

func get_current_camera_name() -> String:
	if not _is_active or _current_camera == null:
		return ""
	
	for key in _cameras:
		if _cameras[key] == _current_camera:
			return key
	
	return ""

func _input(event):
	if not _is_active:
		return
	
	if event.is_action_pressed("ui_cancel"):
		deactivate_current_camera()
	
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			var cameras = _cameras.keys()
			if cameras.size() >= 1:
				switch_camera(cameras[0])
		elif event.keycode == KEY_2:
			var cameras = _cameras.keys()
			if cameras.size() >= 2:
				switch_camera(cameras[1])
		elif event.keycode == KEY_3:
			var cameras = _cameras.keys()
			if cameras.size() >= 3:
				switch_camera(cameras[2])
		elif event.keycode == KEY_4:
			var cameras = _cameras.keys() 
			if cameras.size() >= 4:
				switch_camera(cameras[3]) 