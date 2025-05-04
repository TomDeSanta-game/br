extends Node

var manager
var camera
var environment
var audio_bus = "Master"

var base_env_settings = {}
var current_effects = []
var transition_tween

func _ready():
	await get_tree().process_frame
	manager = get_node_or_null("/root/TensionManager")
	if manager:
		manager.tension_engine.threshold_crossed.connect(_on_threshold_crossed)
		
	find_camera()
	setup_base_environment()

func _process(delta):
	if !manager:
		return
		
	update_effects_intensity(manager.tension_engine.get_normalized())

func find_camera():
	await get_tree().process_frame
	var viewport = get_viewport()
	if viewport:
		camera = viewport.get_camera_2d()
		
	if !camera:
		push_warning("TensionEffects: No camera found")

func setup_base_environment():
	if !camera:
		return
		
	environment = camera.get_node_or_null("WorldEnvironment")
	if environment && environment.environment:
		base_env_settings = {
			"brightness": environment.environment.adjustment_brightness,
			"contrast": environment.environment.adjustment_contrast,
			"saturation": environment.environment.adjustment_saturation,
			"glow_intensity": environment.environment.glow_intensity,
			"glow_bloom": environment.environment.glow_bloom,
			"vignette_intensity": environment.environment.adjustment_color_correction.get_curve_texture_intensity()
		}

func _on_threshold_crossed(threshold, direction):
	var sound_manager = get_node_or_null("/root/SoundManager")
	
	match threshold:
		"MINIMAL":
			if direction < 0:
				remove_all_effects()
				if sound_manager:
					sound_manager.play_music("ambient", true, 1.0)
		"LOW":
			if direction > 0:
				add_effect("slight_desaturation")
				add_effect("light_vignette")
				if sound_manager:
					sound_manager.play_music("tense_low", true, 0.8)
		"MEDIUM":
			if direction > 0:
				add_effect("medium_desaturation")
				add_effect("medium_vignette")
				add_effect("camera_shake", 0.3)
				if sound_manager:
					sound_manager.play_music("tense_medium", true, 0.9)
		"HIGH":
			if direction > 0:
				add_effect("heavy_desaturation")
				add_effect("heavy_vignette")
				add_effect("camera_shake", 0.7)
				add_effect("heartbeat_sound")
				if sound_manager:
					sound_manager.play_music("tense_high", true, 1.0)
		"CRITICAL":
			if direction > 0:
				add_effect("extreme_desaturation")
				add_effect("extreme_vignette")
				add_effect("camera_shake", 1.0)
				add_effect("glow_effect")
				add_effect("heartbeat_sound", 1.5)
				if sound_manager:
					sound_manager.play_music("danger", true, 1.0)

func add_effect(effect_name, intensity = 1.0):
	if current_effects.has(effect_name):
		for effect in current_effects:
			if effect.name == effect_name:
				effect.intensity = intensity
				return
	
	current_effects.append({
		"name": effect_name,
		"intensity": intensity
	})
	
	apply_effect(effect_name, intensity)

func remove_effect(effect_name):
	for i in range(current_effects.size() - 1, -1, -1):
		if current_effects[i].name == effect_name:
			current_effects.remove_at(i)
			
	reset_effect(effect_name)

func remove_all_effects():
	current_effects.clear()
	reset_all_effects()

func apply_effect(effect_name, intensity):
	match effect_name:
		"slight_desaturation", "medium_desaturation", "heavy_desaturation", "extreme_desaturation":
			apply_desaturation(effect_name, intensity)
		"light_vignette", "medium_vignette", "heavy_vignette", "extreme_vignette":
			apply_vignette(effect_name, intensity)
		"camera_shake":
			apply_camera_shake(intensity)
		"glow_effect":
			apply_glow(intensity)
		"heartbeat_sound":
			apply_heartbeat(intensity)

func apply_desaturation(level, intensity):
	if !environment || !environment.environment:
		return
		
	var target_saturation = 1.0
	match level:
		"slight_desaturation":
			target_saturation = 0.8
		"medium_desaturation":
			target_saturation = 0.6
		"heavy_desaturation":
			target_saturation = 0.4
		"extreme_desaturation":
			target_saturation = 0.2
	
	target_saturation = lerp(1.0, target_saturation, intensity)
	
	if transition_tween && transition_tween.is_valid():
		transition_tween.kill()
		
	transition_tween = create_tween()
	transition_tween.tween_property(environment.environment, "adjustment_saturation", 
		target_saturation, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

func apply_vignette(level, intensity):
	if !environment || !environment.environment:
		return
		
	var target_intensity = 0.0
	match level:
		"light_vignette":
			target_intensity = 0.2
		"medium_vignette":
			target_intensity = 0.4
		"heavy_vignette":
			target_intensity = 0.6
		"extreme_vignette":
			target_intensity = 0.8
	
	target_intensity = lerp(0.0, target_intensity, intensity)
	
	if transition_tween && transition_tween.is_valid():
		transition_tween.kill()
		
	transition_tween = create_tween()
	# This assumes your environment has a color correction curve set up
	transition_tween.tween_method(func(value): 
		environment.environment.adjustment_color_correction.set_curve_texture_intensity(value), 
		environment.environment.adjustment_color_correction.get_curve_texture_intensity(), 
		target_intensity, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

func apply_camera_shake(intensity):
	if !camera:
		return
		
	if camera.has_method("add_trauma"):
		camera.add_trauma(intensity)
	else:
		# If no custom shake method, try direct shake
		var shake_strength = 4.0 * intensity
		var shake_duration = 0.3
		
		if transition_tween && transition_tween.is_valid():
			transition_tween.kill()
			
		transition_tween = create_tween()
		transition_tween.tween_property(camera, "offset", Vector2(randf_range(-shake_strength, shake_strength), 
			randf_range(-shake_strength, shake_strength)), shake_duration * 0.5)
		transition_tween.tween_property(camera, "offset", Vector2.ZERO, shake_duration * 0.5)

func apply_glow(intensity):
	if !environment || !environment.environment:
		return
		
	var target_glow = lerp(0.0, 1.5, intensity)
	var target_bloom = lerp(0.0, 0.8, intensity)
	
	if transition_tween && transition_tween.is_valid():
		transition_tween.kill()
		
	transition_tween = create_tween()
	transition_tween.tween_property(environment.environment, "glow_intensity", 
		target_glow, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	transition_tween.parallel().tween_property(environment.environment, "glow_bloom", 
		target_bloom, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

func apply_heartbeat(intensity):
	var sound_manager = get_node_or_null("/root/SoundManager")
	if !sound_manager:
		return
		
	if sound_manager.has_method("play_heartbeat"):
		sound_manager.play_heartbeat(intensity)
	elif sound_manager.has_method("play_sfx"):
		sound_manager.play_sfx("heartbeat", audio_bus, -10.0 + (5.0 * intensity), false)

func reset_effect(effect_name):
	var base = base_env_settings
	if !environment || !environment.environment || !base:
		return
		
	if effect_name.begins_with("camera_shake"):
		if camera:
			camera.offset = Vector2.ZERO
	elif effect_name.begins_with("heartbeat"):
		var sound_manager = get_node_or_null("/root/SoundManager")
		if sound_manager && sound_manager.has_method("stop_heartbeat"):
			sound_manager.stop_heartbeat()
	
	reset_environment_effects()

func reset_all_effects():
	if camera:
		camera.offset = Vector2.ZERO
		
	var sound_manager = get_node_or_null("/root/SoundManager")
	if sound_manager && sound_manager.has_method("stop_heartbeat"):
		sound_manager.stop_heartbeat()
	
	reset_environment_effects()

func reset_environment_effects():
	var base = base_env_settings
	if !environment || !environment.environment || !base:
		return
		
	if transition_tween && transition_tween.is_valid():
		transition_tween.kill()
		
	transition_tween = create_tween()
	transition_tween.tween_property(environment.environment, "adjustment_saturation", 
		base.saturation, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	transition_tween.parallel().tween_property(environment.environment, "adjustment_brightness", 
		base.brightness, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	transition_tween.parallel().tween_property(environment.environment, "adjustment_contrast", 
		base.contrast, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	transition_tween.parallel().tween_property(environment.environment, "glow_intensity", 
		base.glow_intensity, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	transition_tween.parallel().tween_property(environment.environment, "glow_bloom", 
		base.glow_bloom, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	
	# This assumes your environment has a color correction curve set up
	transition_tween.parallel().tween_method(func(value): 
		environment.environment.adjustment_color_correction.set_curve_texture_intensity(value), 
		environment.environment.adjustment_color_correction.get_curve_texture_intensity(), 
		base.vignette_intensity, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)

func update_effects_intensity(tension_value):
	for effect in current_effects:
		var name = effect.name
		var base_intensity = effect.intensity
		var current_intensity = base_intensity * tension_value
		
		apply_effect(name, current_intensity) 