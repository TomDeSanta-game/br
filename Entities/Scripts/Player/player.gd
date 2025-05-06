extends CharacterBody2D
const ANIMATIONS: Dictionary = {
	"DOWN_IDLE": "Down_Idle",
	"RIGHT_IDLE": "Right_Idle",
	"UP_IDLE": "Up_Idle",
	"DOWN_RUN": "Down_Run",
	"RIGHT_RUN": "Right_Run",
	"UP_RUN": "Up_Run"
}
const ANIMATION_RUN: String = "run"
const ANIMATION_IDLE: String = "idle"
var speed: float = 100.0
@export var max_speed: float = 120.0
var current_max_speed: float = max_speed
var sprint_speed_multiplier: float = 1.6
var sprint_active: bool = false
var can_sprint: bool = true
var sprint_stamina: float = 100.0
var max_sprint_stamina: float = 100.0
var sprint_drain_rate: float = 25.0
var sprint_recovery_rate: float = 15.0
var sprint_recovery_delay: float = 1.0
var sprint_recovery_timer: float = 0.0
var min_sprint_stamina: float = 20.0
@export var acceleration: float = 600.0
@export var deceleration: float = 800.0
var wall_slide_factor: float = 0.85
var corner_correction_distance: float = 5.0
var input_deadzone: float = 0.2
var direction: Vector2 = Vector2.ZERO
var last_direction: Vector2 = Vector2.ZERO
var movement_epsilon: float = 0.2
var is_interact_mode = false
var ui_hidden = false
var is_running: bool = false
var direction_change_delay: float = 0.08
var direction_change_timer: float = 0.0
var direction_hysteresis: float = 0.3
var animation_stability_threshold: float = 0.4
var min_velocity_for_run: float = 30.0
var terrain_speed_modifier: float = 1.0
var context_speed_multiplier: float = 1.0
var speed_decay_rate: float = 0.25
var focused_walking: bool = false
var focus_target: Vector2 = Vector2.ZERO
var focus_object: Node2D = null
var focus_speed_factor: float = 0.7
var focus_strength: float = 0.0
var focus_fade_speed: float = 2.0
var current_mood: String = "neutral"
var mood_intensity: float = 0.0
var footstep_timer: float = 0.0
var footstep_threshold_run: float = 0.25
var footstep_threshold_walk: float = 0.45
var footstep_volume: float = 0.6
var footstep_environment: String = "normal"
var thought_active: bool = false
var thought_timer: float = 0.0
var thought_duration: float = 0.0
var last_thought_time: float = 0.0
var min_thought_interval: float = 20.0
var memory_trigger_radius: float = 150.0
var memories_discovered: Array = []
var input_buffer_time: float = 0.2
var interact_buffer_timer: float = 0.0
var last_interact_position: Vector2 = Vector2.ZERO
var last_collision_normal: Vector2 = Vector2.ZERO
var corner_ray_length: float = 16.0
var camera_offset = Vector2.ZERO
var camera_target_zoom = Vector2(4, 4)
var camera_shake_intensity: float = 0.0
var camera_shake_decay: float = 5.0
var camera_shake_time: float = 0.0
var camera_noise = FastNoiseLite.new()
var run_timer = 0.0
var idle_timer = 0.0
var can_zoom_in = true
var can_zoom_out = true
var current_animation: String = ""
var animation_locked: bool = false
var animation_lock_timer: float = 0.0
var animation_lock_duration: float = 0.15
var animation_transition_delay: float = 0.4
var animation_transition_timer: float = 0.0
var pending_animation: String = ""
var animation_switching_hysteresis: float = 20.0
var same_animation_cooldown: float = 0.6
var last_animation_change_time: float = 0.0
var smoothed_velocity: Vector2 = Vector2.ZERO
var smoothed_direction: Vector2 = Vector2.ZERO
var last_anim_direction: Vector2 = Vector2.DOWN
var velocity_history: Array[Vector2] = []
var velocity_history_size: int = 8
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D
@onready var objective_label: Control = $CanvasLayer/ObjectiveLabel if has_node("CanvasLayer/ObjectiveLabel") else null
@onready var objective_text: RichTextLabel = $CanvasLayer/ObjectiveLabel/ContentPanel/ObjectiveText if has_node("CanvasLayer/ObjectiveLabel/ContentPanel/ObjectiveText") else null
@onready var heat_bar: Control = $CanvasLayer/HeatBar if has_node("CanvasLayer/HeatBar") else null
@onready var debug_label: Label = $CanvasLayer/DebugLabel if has_node("CanvasLayer/DebugLabel") else null
var state_machine: PlayerStateMachine
var corner_ray_right: RayCast2D
var corner_ray_left: RayCast2D
var corner_ray_up: RayCast2D
var corner_ray_down: RayCast2D
var thought_bubble: Control
var thought_text: RichTextLabel
var footstep_audio: AudioStreamPlayer2D
var ambience_audio: AudioStreamPlayer
@export var debug_mode: bool = false
var signal_bus = null
var llm = null
const DEFAULT_PLAYER_LAYER = 2
const DEFAULT_WORLD_LAYER = 1
const DEFAULT_ENEMY_LAYER = 8
const DEFAULT_NPC_LAYER = 16
const DEFAULT_ASSISTANT_LAYER = 4
const DEFAULT_OBJECT_LAYER = 32
func _ready() -> void:
	signal_bus = get_node_or_null("/root/SignalBus")
	if signal_bus:
		signal_bus.max_tension_reached.connect(_on_max_tension_reached)
	llm = get_node_or_null("/root/LLM")
	setup_collision()
	setup_state_machine()
	setup_ui()
	setup_camera()
	configure_corner_rays()
	configure_thought_bubble()
	configure_audio()
	setup_animation()
	await get_tree().create_timer(0.2).timeout
	set_camera_zoom(4.0, 1.5)
func setup_collision() -> void:
	var player_layer = DEFAULT_PLAYER_LAYER
	var world_layer = DEFAULT_WORLD_LAYER
	var enemy_layer = DEFAULT_ENEMY_LAYER
	var npc_layer = DEFAULT_NPC_LAYER
	var assistant_layer = DEFAULT_ASSISTANT_LAYER
	var object_layer = DEFAULT_OBJECT_LAYER
	if llm:
		player_layer = llm.player_layer
		world_layer = llm.world_layer
		enemy_layer = llm.enemy_layer
		npc_layer = llm.npc_layer
		assistant_layer = llm.assistant_layer
		object_layer = llm.object_layer
	collision_layer = player_layer
	collision_mask = world_layer | enemy_layer | npc_layer | assistant_layer | object_layer
func setup_state_machine() -> void:
	state_machine = PlayerStateMachine.new()
	add_child(state_machine)
	state_machine.init(self)
	state_machine.set_active(true)
func setup_animation() -> void:
	if animated_sprite:
		current_animation = ANIMATIONS.DOWN_IDLE
		animated_sprite.play(current_animation)
		last_anim_direction = Vector2.DOWN
		smoothed_direction = Vector2.DOWN
		animated_sprite.speed_scale = 1.0
func configure_thought_bubble() -> void:
	if thought_bubble == null:
		thought_bubble = Control.new()
		thought_bubble.name = "ThoughtBubble"
		var panel = Panel.new()
		panel.size = Vector2(200, 60)
		panel.position = Vector2(-100, -100)
		thought_text = RichTextLabel.new()
		thought_text.name = "ThoughtText"
		thought_text.size = Vector2(180, 50)
		thought_text.position = Vector2(-90, -95)
		thought_text.bbcode_enabled = true
		thought_bubble.add_child(panel)
		thought_bubble.add_child(thought_text)
		var canvas_layer = get_node_or_null("CanvasLayer")
		if canvas_layer:
			canvas_layer.add_child(thought_bubble)
		else:
			var new_canvas = CanvasLayer.new()
			new_canvas.name = "CanvasLayer"
			add_child(new_canvas)
			new_canvas.add_child(thought_bubble)
	thought_bubble.visible = false
	thought_bubble.modulate.a = 0.0
func configure_audio() -> void:
	if footstep_audio == null:
		footstep_audio = AudioStreamPlayer2D.new()
		footstep_audio.name = "FootstepAudio"
		add_child(footstep_audio)
	if ambience_audio == null:
		ambience_audio = AudioStreamPlayer.new()
		ambience_audio.name = "AmbienceAudio"
		add_child(ambience_audio)
	footstep_audio.volume_db = -15
	footstep_audio.max_distance = 300
	ambience_audio.volume_db = -20
	ambience_audio.bus = "Ambient"
func setup_ui() -> void:
	var canvas_layer = get_node_or_null("CanvasLayer")
	if canvas_layer:
		canvas_layer.visible = true
	if heat_bar:
		heat_bar.visible = true
func setup_camera() -> void:
	if !camera:
		return
	camera_noise.seed = randi()
	camera_noise.frequency = 0.5
	camera.drag_horizontal_enabled = true
	camera.drag_vertical_enabled = true
	camera.drag_left_margin = 0.1
	camera.drag_top_margin = 0.1
	camera.drag_right_margin = 0.1
	camera.drag_bottom_margin = 0.1
func configure_corner_rays() -> void:
	var offset = 2.0
	if corner_ray_right == null:
		corner_ray_right = RayCast2D.new()
		corner_ray_right.name = "CornerRayRight"
		add_child(corner_ray_right)
	if corner_ray_left == null:
		corner_ray_left = RayCast2D.new()
		corner_ray_left.name = "CornerRayLeft"
		add_child(corner_ray_left)
	if corner_ray_up == null:
		corner_ray_up = RayCast2D.new()
		corner_ray_up.name = "CornerRayUp"
		add_child(corner_ray_up)
	if corner_ray_down == null:
		corner_ray_down = RayCast2D.new()
		corner_ray_down.name = "CornerRayDown"
		add_child(corner_ray_down)
	var world_layer = DEFAULT_WORLD_LAYER
	if llm:
		world_layer = llm.world_layer
	for ray in [corner_ray_right, corner_ray_left, corner_ray_up, corner_ray_down]:
		ray.collision_mask = world_layer
		ray.enabled = true
	corner_ray_right.target_position = Vector2(corner_ray_length, 0)
	corner_ray_left.target_position = Vector2(-corner_ray_length, 0)
	corner_ray_up.target_position = Vector2(0, -corner_ray_length)
	corner_ray_down.target_position = Vector2(0, corner_ray_length)
	corner_ray_right.position = Vector2(offset, 0)
	corner_ray_left.position = Vector2(-offset, 0)
	corner_ray_up.position = Vector2(0, -offset)
	corner_ray_down.position = Vector2(0, offset)
func _process(delta: float) -> void:
	check_heat()
	update_camera(delta)
	update_camera_timers(delta)
	update_input_buffers(delta)
	update_focus_state(delta)
	update_thought_system(delta)
	update_footsteps(delta)
	update_animation_state(delta)
	update_sprint(delta)
	check_for_memories()
	if direction_change_timer > 0:
		direction_change_timer -= delta
	last_animation_change_time += delta
	if debug_mode:
		_setup_debug_label()
	debug_label.visible = debug_mode
func update_animation_state(_delta: float) -> void:
	if animation_locked:
		return
	var moving = velocity.length() > 5.0
	if moving:
		var direction_name = "Down"
		if abs(direction.y) > abs(direction.x):
			direction_name = "Up" if direction.y < 0 else "Down"
		else:
			direction_name = "Right"
			animated_sprite.flip_h = direction.x < 0
		current_animation = direction_name + "_Run"
		animated_sprite.play(current_animation)
	else:
		var idle_direction = "Down"
		if current_animation.ends_with("_Run"):
			idle_direction = current_animation.split("_")[0]
		current_animation = idle_direction + "_Idle"
		animated_sprite.play(current_animation)
func update_focus_state(_delta: float) -> void:
	if focused_walking:
		if focus_object != null and is_instance_valid(focus_object):
			focus_target = focus_object.global_position
		var to_target = focus_target - global_position
		var distance = to_target.length()
		focus_strength = 1.0
		if distance < 10:
			focused_walking = false
			focus_strength = 0.0
	else:
		focus_strength = 0.0
func update_footsteps(delta: float) -> void:
	if velocity.length() > movement_epsilon:
		footstep_timer += delta
		var threshold = footstep_threshold_walk
		if velocity.length() > max_speed * 0.7:
			threshold = footstep_threshold_run
		if footstep_timer > threshold:
			footstep_timer = 0
			play_footstep()
func play_footstep() -> void:
	if is_instance_valid(footstep_audio):
		var pitch_scale = randf_range(0.8, 1.2)
		var volume = footstep_volume
		if current_mood == "afraid" or current_mood == "sneaking":
			volume *= 0.5
			pitch_scale = randf_range(0.7, 0.9)
		elif current_mood == "determined":
			volume *= 1.2
			pitch_scale = randf_range(1.0, 1.3)
		footstep_audio.pitch_scale = pitch_scale
		footstep_audio.volume_db = linear_to_db(volume)
		footstep_audio.play()
func update_thought_system(delta: float) -> void:
	if thought_active:
		thought_timer -= delta
		if thought_timer <= 0:
			hide_thought()
	else:
		last_thought_time += delta
		if last_thought_time > min_thought_interval:
			check_for_random_thought()
func check_for_random_thought() -> void:
	if not thought_active and randf() < 0.01:
		var thoughts = [
			"I wonder how much longer I need to keep going.",
			"Something doesn't feel right about this place.",
			"I should check my objectives again.",
			"That last interaction was... strange.",
			"I need to find a way out of here.",
			"This heat is unbearable.",
			"I miss the way things used to be."
		]
		if current_mood == "afraid":
			thoughts = [
				"I need to get out of here!",
				"What was that sound?",
				"I don't like this...",
				"Something is watching me.",
				"Stay calm. Just stay calm."
			]
		elif current_mood == "determined":
			thoughts = [
				"I can do this.",
				"Just a little further.",
				"I won't give up now.",
				"I need to keep moving.",
				"There has to be a way."
			]
		var thought = thoughts[randi() % thoughts.size()]
		show_thought(thought, 4.0)
func show_thought(text: String, duration: float) -> void:
	thought_text.text = "[i]" + text + "[/i]"
	thought_bubble.visible = true
	thought_active = true
	thought_timer = duration
	thought_duration = duration
	last_thought_time = 0
	var tween = create_tween()
	tween.tween_property(thought_bubble, "modulate:a", 1.0, 0.5)
func hide_thought() -> void:
	var tween = create_tween()
	tween.tween_property(thought_bubble, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): thought_bubble.visible = false)
	thought_active = false
func check_for_memories() -> void:
	var memory_spots = get_tree().get_nodes_in_group("MemorySpot")
	for spot in memory_spots:
		if global_position.distance_to(spot.global_position) < memory_trigger_radius:
			if not memories_discovered.has(spot.name):
				discover_memory(spot)
func discover_memory(memory_spot: Node2D) -> void:
	memories_discovered.append(memory_spot.name)
	if memory_spot.has_method("get_memory_text"):
		var memory_text = memory_spot.get_memory_text()
		show_memory(memory_text)
		if memory_spot.has_method("trigger_memory_effect"):
			memory_spot.trigger_memory_effect(self)
func show_memory(text: String) -> void:
	apply_camera_shake(0.5, 0.3)
	set_camera_zoom(3.6, 0.5)
	show_thought("Memory:\n" + text, 7.0)
	var fade_color = ColorRect.new()
	fade_color.color = Color(1, 1, 1, 0)
	fade_color.size = Vector2(1920, 1080)
	fade_color.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$CanvasLayer.add_child(fade_color)
	var tween = create_tween()
	tween.tween_property(fade_color, "color:a", 0.4, 0.2)
	tween.tween_property(fade_color, "color:a", 0.0, 0.7)
	tween.tween_callback(func(): fade_color.queue_free())
	set_mood("reflective", 0.8)
	set_movement_context_multiplier(0.7, 3.0)
	await get_tree().create_timer(4.0).timeout
	set_camera_zoom(4.0, 1.5)
func set_mood(mood: String, intensity: float = 1.0) -> void:
	current_mood = mood
	mood_intensity = intensity
	if mood == "afraid":
		set_movement_context_multiplier(1.25, 8.0)
		if randf() < 0.5:
			apply_camera_shake(0.3, 0.5)
	elif mood == "determined":
		set_movement_context_multiplier(1.1, 15.0)
	elif mood == "reflective":
		set_movement_context_multiplier(0.8, 5.0)
	elif mood == "sneaking":
		set_movement_context_multiplier(0.6, 10.0)
func update_input_buffers(delta: float) -> void:
	if interact_buffer_timer > 0:
		interact_buffer_timer -= delta
func update_camera_timers(delta: float) -> void:
	if is_running:
		run_timer += delta
		idle_timer = 0.0
		if run_timer > 0.85 and can_zoom_out:
			can_zoom_out = false
			set_camera_zoom(3.5, 1.5)
			await get_tree().create_timer(2.0).timeout
			can_zoom_out = true
	else:
		idle_timer += delta
		run_timer = 0.0
		if idle_timer > 1.2 and can_zoom_in and camera_target_zoom.x < 3.9:
			can_zoom_in = false
			set_camera_zoom(4.0, 2.0)
			await get_tree().create_timer(2.0).timeout
			can_zoom_in = true
func _physics_process(delta: float) -> void:
	handle_movement(delta)
	update_smoothed_values(delta)
func update_smoothed_values(_delta: float) -> void:
	velocity_history.push_back(velocity)
	if velocity_history.size() > velocity_history_size:
		velocity_history.pop_front()
	smoothed_velocity = velocity
	smoothed_direction = direction
	if direction.length() > 0.3 and last_anim_direction.dot(direction) < -0.5:
		animation_locked = true
		animation_lock_timer = animation_lock_duration
func handle_movement(_delta: float) -> void:
	var input_vector: Vector2 = get_input_vector()
	if input_vector.length() > 0:
		direction = input_vector.normalized()
		var target_speed = current_max_speed
		if sprint_active:
			target_speed *= sprint_speed_multiplier
			heat_bar.fill_anisprotic(7.0)
		velocity = direction * target_speed
		is_running = true
	else:
		direction = Vector2.ZERO
		velocity = Vector2.ZERO
		is_running = false
	move_and_slide()
	var collision = get_last_slide_collision()
	if collision:
		handle_collision(collision.get_position())
func handle_collision(_previous_position: Vector2) -> void:
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		last_collision_normal = collision.get_normal()
		if velocity.length() > 20:
			var slide_velocity = velocity.slide(last_collision_normal)
			velocity = slide_velocity * wall_slide_factor
			if not try_corner_correction() and velocity.length() < 8.0:
				var recovery_direction = last_collision_normal.normalized()
				global_position += recovery_direction * 2.0
				velocity = velocity.bounce(last_collision_normal) * 0.3
func get_input_vector() -> Vector2:
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	if input_vector.length() < input_deadzone:
		return Vector2.ZERO
	if input_vector.length() < 0.5:
		input_vector = input_vector.normalized() * (0.3 + input_vector.length()) * 0.8
	return input_vector
func try_corner_correction() -> bool:
	var motion_dir = velocity.normalized()
	if motion_dir.length() < 0.5:
		return false
	var correction = Vector2.ZERO
	var primary_axis = abs(motion_dir.x) > abs(motion_dir.y)
	if primary_axis:
		if motion_dir.x > 0 and corner_ray_right.is_colliding():
			if !corner_ray_up.is_colliding():
				correction = Vector2(0, -corner_correction_distance)
			elif !corner_ray_down.is_colliding():
				correction = Vector2(0, corner_correction_distance)
		elif motion_dir.x < 0 and corner_ray_left.is_colliding():
			if !corner_ray_up.is_colliding():
				correction = Vector2(0, -corner_correction_distance)
			elif !corner_ray_down.is_colliding():
				correction = Vector2(0, corner_correction_distance)
	else:
		if motion_dir.y > 0 and corner_ray_down.is_colliding():
			if !corner_ray_right.is_colliding():
				correction = Vector2(corner_correction_distance, 0)
			elif !corner_ray_left.is_colliding():
				correction = Vector2(-corner_correction_distance, 0)
		elif motion_dir.y < 0 and corner_ray_up.is_colliding():
			if !corner_ray_right.is_colliding():
				correction = Vector2(corner_correction_distance, 0)
			elif !corner_ray_left.is_colliding():
				correction = Vector2(-corner_correction_distance, 0)
	if correction != Vector2.ZERO:
		global_position += correction
		if correction.x != 0:
			velocity.y *= 0.8
		else:
			velocity.x *= 0.8
		return true
	return false
func handle_running(_dir: Vector2) -> void:
	if velocity.length() > min_velocity_for_run * 0.7:
		is_running = true
		heat_bar.fill_anisprotic(5.0)
		state_machine.update(get_process_delta_time())
		var effective_direction = velocity.normalized() * min(1.0, velocity.length() / (max_speed * 0.5))
		apply_camera_forward_focus(0.3, effective_direction)
	else:
		handle_idle()
func handle_idle() -> void:
	is_running = false
	heat_bar.stop_fill_anisprotic()
	state_machine.update(get_process_delta_time())
	apply_camera_forward_focus(0.0, Vector2.ZERO)
func update_camera(delta: float) -> void:
	if camera_shake_time > 0:
		camera_shake_time -= delta
		var intensity = camera_shake_intensity * (camera_shake_time / camera_shake_decay)
		camera.offset = Vector2(
			camera_noise.get_noise_2d(Time.get_ticks_msec() * 0.1, 0) * intensity,
			camera_noise.get_noise_2d(0, Time.get_ticks_msec() * 0.1) * intensity
		)
	else:
		camera.offset = camera_offset
	camera.zoom = camera_target_zoom
func apply_camera_shake(intensity: float, time: float) -> void:
	camera_shake_intensity = intensity
	camera_shake_time = time
	camera_shake_decay = time
func apply_camera_forward_focus(strength: float, d: Vector2) -> void:
	camera_offset = d * 20.0 * strength
func set_camera_zoom(zoom_level: float, _duration: float = 0.5) -> void:
	camera_target_zoom = Vector2(zoom_level, zoom_level)
	camera.zoom = camera_target_zoom
func set_movement_context_multiplier(multiplier: float, duration: float = 2.0) -> void:
	context_speed_multiplier = multiplier
	speed_decay_rate = 1.0 / duration
func set_terrain_speed_modifier(modifier: float) -> void:
	terrain_speed_modifier = modifier
func focus_on_point(target_position: Vector2) -> void:
	focused_walking = true
	focus_target = target_position
	focus_object = null
func focus_on_object(target_object: Node2D) -> void:
	if is_instance_valid(target_object):
		focused_walking = true
		focus_target = target_object.global_position
		focus_object = target_object
func clear_focus() -> void:
	focused_walking = false
	focus_object = null
	focus_strength = 0.0
func check_heat() -> void:
	pass
func die() -> void:
	apply_camera_shake(10.0, 0.5)
	SceneManager.reload_scene()
func _setup_debug_label() -> void:
	var position_text = "Position: (" + str(int(global_position.x)) + ", " + str(int(global_position.y)) + ")"
	var velocity_text = "Velocity: (" + str(int(velocity.x)) + ", " + str(int(velocity.y)) + ")"
	var smoothed_vel_text = "Smoothed Vel: (" + str(int(smoothed_velocity.x)) + ", " + str(int(smoothed_velocity.y)) + ")"
	var direction_text = "Direction: (" + str(direction.x).pad_decimals(2) + ", " + str(direction.y).pad_decimals(2) + ")"
	var smoothed_dir_text = "Smoothed Dir: (" + str(smoothed_direction.x).pad_decimals(2) + ", " + str(smoothed_direction.y).pad_decimals(2) + ")"
	var anim_text = "Animation: " + current_animation
	var speed_text = "Speed: " + str(int(velocity.length()))
	var collision_text = "Last Collision: " + str(last_collision_normal)
	var mood_text = "Mood: " + current_mood + " (" + str(mood_intensity).pad_decimals(1) + ")"
	var focus_text = "Focus: " + str(focused_walking) + " (" + str(focus_strength).pad_decimals(1) + ")"
	var memories_text = "Memories: " + str(memories_discovered.size())
	var sprint_text = "Sprint: " + str(sprint_active) + " (" + str(int(sprint_stamina)) + "/" + str(int(max_sprint_stamina)) + ")"
	var current_heat_text = "Current Heat: Heat monitoring via SignalBus"
	debug_label.text = (
		"FPS: " + str(Engine.get_frames_per_second()) + "\n" +
		current_heat_text + "\n" +
		"Current Objective: " + "\n" +
		position_text + "\n" +
		velocity_text + "\n" +
		smoothed_vel_text + "\n" +
		direction_text + "\n" +
		smoothed_dir_text + "\n" +
		anim_text + "\n" +
		speed_text + "\n" +
		collision_text + "\n" +
		mood_text + "\n" +
		focus_text + "\n" +
		memories_text + "\n" +
		sprint_text
	)
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Interact"):
		last_interact_position = global_position
		interact_buffer_timer = input_buffer_time
	if event.is_action_released("Interact"):
		interact_buffer_timer = 0
	elif event.is_action_released("Pause"):
		die()
	elif event.is_action_released("DEBUG"):
		debug_mode = !debug_mode
	elif event.is_action_released("HUI"):
		hide_ui(true)
		await get_tree().create_timer(0.1).timeout
		apply_camera_shake(0.7, 0.2)
func show_objective(text: String, duration: float = 5.0) -> void:
	objective_text.text = text
	var animation_player = objective_label.get_node("AnimationPlayer")
	animation_player.stop()
	animation_player.play("appear")
	var pulse_player = objective_label.get_node("PulseAnimationPlayer")
	pulse_player.stop()
	pulse_player.play("pulse")
	await get_tree().create_timer(0.2).timeout
	apply_camera_shake(0.4, 0.2)
	if duration > 0:
		await get_tree().create_timer(duration).timeout
		hide_objective()
func hide_objective() -> void:
	var animation_player = objective_label.get_node("AnimationPlayer")
	animation_player.stop()
	animation_player.play("disappear")
	var pulse_player = objective_label.get_node("PulseAnimationPlayer")
	pulse_player.stop()
func show_styled_objective(title: String, content: String, duration: float = 5.0) -> void:
	var formatted_text = title + "\n" + content
	show_objective(formatted_text, duration)
func complete_objective(hide_after: float = 3.0) -> void:
	var pulse_player = objective_label.get_node("PulseAnimationPlayer")
	pulse_player.stop()
	var animation_player = objective_label.get_node("AnimationPlayer")
	animation_player.stop()
	animation_player.play("complete")
	$CanvasLayer/ObjectiveLabel/IconContainer/Icon.text = "✓"
	$CanvasLayer/ObjectiveLabel/TitleLabel.text = "OBJECTIVE COMPLETED"
	await get_tree().create_timer(0.15).timeout
	apply_camera_shake(1.0, 0.3)
	await get_tree().create_timer(0.2).timeout
	set_camera_zoom(3.5, 0.7)
	if hide_after > 0:
		await get_tree().create_timer(hide_after).timeout
		hide_objective()
		$CanvasLayer/ObjectiveLabel/IconContainer/Icon.text = "!"
		$CanvasLayer/ObjectiveLabel/TitleLabel.text = "OBJECTIVE TO COMPLETE"
		await get_tree().create_timer(0.3).timeout
		set_camera_zoom(4.0, 1.5)
func hide_ui(boolean: bool) -> void:
	ui_hidden = boolean
	if boolean:
		objective_label.hide()
		objective_text.hide()
		heat_bar.hide()
		debug_label.hide()
	else:
		objective_label.show()
		objective_text.show()
		heat_bar.show()
		if debug_mode:
			debug_label.show()
func is_player_running() -> bool:
	return is_running
func update_animation(input_vector: Vector2) -> void:
	direction = input_vector
	handle_running(input_vector)
func update_idle_animation() -> void:
	direction = Vector2.ZERO
	handle_idle()
func update_sprint(delta: float) -> void:
	sprint_active = false
	if can_sprint and sprint_stamina > min_sprint_stamina:
		if Input.is_key_pressed(KEY_SHIFT):
			sprint_active = true
	if sprint_active:
		sprint_stamina = max(0.0, sprint_stamina - sprint_drain_rate * delta)
		sprint_recovery_timer = 0.0
		if sprint_stamina <= 0:
			can_sprint = false
	else:
		sprint_recovery_timer += delta
		if sprint_recovery_timer > sprint_recovery_delay:
			sprint_stamina = min(max_sprint_stamina, sprint_stamina + sprint_recovery_rate * delta)
			if sprint_stamina > min_sprint_stamina * 1.5:
				can_sprint = true
func _on_max_tension_reached() -> void:
	Log.info("Max tension reached - player death triggered")
	die()