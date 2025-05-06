extends Control
var hover_sound: AudioStreamPlayer
var menu_tween: Tween
var is_transitioning = false
func _ready():
	setup_audio()
	setup_buttons()
	animate_entrance()
func setup_audio():
	hover_sound = AudioStreamPlayer.new()
	add_child(hover_sound)
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 44100
	hover_sound.stream = stream
	hover_sound.volume_db = -10
func setup_buttons():
	for button in get_all_buttons():
		button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
func get_all_buttons():
	return $MenuPanel/VBoxContainer/ButtonsContainer.get_children()
func animate_entrance():
	$MenuPanel.modulate.a = 0
	$MenuPanel.position.y += 50
	menu_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	menu_tween.tween_property($MenuPanel, "modulate:a", 1.0, 0.4)
	menu_tween.parallel().tween_property($MenuPanel, "position:y", $MenuPanel.position.y - 50, 0.4)
	var buttons = get_all_buttons()
	for i in range(buttons.size()):
		buttons[i].modulate.a = 0
		menu_tween.parallel().tween_property(buttons[i], "modulate:a", 1.0, 0.2).set_delay(0.1)
func _on_button_mouse_entered(button):
	if hover_sound and hover_sound.stream:
		hover_sound.play()
	var button_tween = create_tween().set_ease(Tween.EASE_OUT)
	button_tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1)
	button_tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)
func transition_to_scene(scene_path):
	if is_transitioning:
		return
	
	var fixed_path = scene_path
	if !ResourceLoader.exists(fixed_path):
		if scene_path.contains("Door.tscn"):
			fixed_path = "res://Objects/Scenes/Doors/Door.tscn"
		elif scene_path.contains("PatchedDoors.tscn"):
			fixed_path = "res://Objects/Scenes/Doors/PatchedDoors.tscn"
	
	if !ResourceLoader.exists(fixed_path):
		Log.err("Scene file not found: " + scene_path)
		return
	
	is_transitioning = true
	menu_tween = create_tween().set_ease(Tween.EASE_IN)
	menu_tween.tween_property($MenuPanel, "modulate:a", 0.0, 0.3)
	await menu_tween.finished
	get_tree().change_scene_to_file(fixed_path)
func _on_start_button_pressed():
	transition_to_scene("res://Levels/House/House.tscn")
func _on_methlab_button_pressed():
	transition_to_scene("res://UI/Scenes/MethLab/MethhLab.tscn")
func _on_options_button_pressed():
	transition_to_scene("res://UI/Scenes/OptionsMenu.tscn")
func _on_quit_button_pressed():
	get_tree().quit()