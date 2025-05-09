extends CharacterBody2D

signal interact

const ANIMATIONS: Dictionary = {
	"idle_down": "Idle_Down",
	"idle_up": "Idle_Up",
	"idle_left": "Idle_Left",
	"idle_right": "Idle_Right",
	"run_down": "Run_Down",
	"run_up": "Run_Up",
	"run_left": "Run_Left",
	"run_right": "Run_Right"
}

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
var is_interact_mode: bool = false
var ui_hidden: bool = false
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
var thought_timer: float = 0.0
var thought_duration: float = 5.0
var last_thought_time: float = 0.0
var min_thought_interval: float = 20.0
var memory_trigger_radius: float = 150.0
var memories_discovered: Array = []
var input_buffer_time: float = 0.2
var interact_buffer: float = 0.0
var last_interact_position: Vector2 = Vector2.ZERO
var last_collision_normal: Vector2 = Vector2.ZERO
var corner_ray_length: float = 16.0
var camera_offset: Vector2 = Vector2.ZERO
var camera_target_zoom: Vector2 = Vector2.ONE
var footstep_threshold_run: float = 0.25
var footstep_threshold_walk: float = 0.45
var footstep_volume: float = 0.6
var footstep_environment: String = "default"
var debug_mode: bool = false

@export var max_health: float = 100.0
var current_health: float = 100.0
var health_percentage: float = 1.0
var stress_level: float = 0.0
var status_marker: Node2D

@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var camera = $Camera2D
@onready var rays = $Rays
@onready var interaction_area = $InteractionArea
@onready var thought_bubble = $ThoughtBubble
@onready var objective_label = $CanvasLayer/ObjectiveLabel
@onready var objective_text = $CanvasLayer/ObjectiveLabel/TextLabel
@onready var heat_bar = $CanvasLayer/HeatBar
@onready var debug_label = $CanvasLayer/DebugLabel

var signal_bus: Node
var tension_manager: Node
var drug_effects_controller: Node

func _ready() -> void:
	tension_manager = get_node_or_null("/root/TensionManager")
	signal_bus = get_node_or_null("/root/SignalBus")
	drug_effects_controller = get_node_or_null("/root/DrugEffectsController")
	
	var status_marker_scene = load("res://UI/Scenes/CharacterStatusMarker.tscn")
	if status_marker_scene:
		status_marker = status_marker_scene.instantiate()
		add_child(status_marker)
	
	if signal_bus:
		signal_bus.connect("max_tension_reached", _on_max_tension_reached)
		signal_bus.connect("min_tension_reached", _on_min_tension_reached)
		signal_bus.connect("tension_changed", _on_tension_changed)
		
	if debug_label:
		debug_label.visible = false
		
	objective_label.visible = false
	
	animation_player.play("Idle_Down")
	current_max_speed = max_speed
	update_sprint(0.0)
	
	set_health(max_health)

func _physics_process(delta: float) -> void:
	var input_vector = Vector2.ZERO
	
	input_vector.x = Input.get_axis("move_left", "move_right")
	input_vector.y = Input.get_axis("move_up", "move_down")
	
	input_vector = input_vector.normalized()
	
	update_sprint(delta)
	
	if input_vector.length() > input_deadzone:
		update_animation(input_vector)
		
		var target_speed = current_max_speed
		if sprint_active:
			target_speed *= sprint_speed_multiplier
			
		target_speed *= context_speed_multiplier * terrain_speed_modifier
		
		if focused_walking:
			target_speed *= focus_speed_factor
			
		var target_velocity = input_vector * target_speed
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
	else:
		update_idle_animation()
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
	
	if velocity.length() > min_velocity_for_run:
		is_running = true
	else:
		is_running = false
		
	handle_wall_sliding()
	handle_corner_correction()
	
	move_and_slide()
	
	handle_footsteps(delta)
	update_debug_info()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug"):
		debug_mode = !debug_mode
		if debug_mode:
			debug_label.show()
		else:
			debug_label.hide()
	elif event.is_action_pressed("interact"):
		handle_interaction()
	elif event.is_action_pressed("toggle_ui"):
		hide_ui(!ui_hidden)
		
	if event.is_action_pressed("ui_home") and debug_mode:
		take_damage(10.0)
		
	if event.is_action_pressed("ui_end") and debug_mode:
		heal(10.0)

func handle_wall_sliding() -> void:
	if !is_on_wall():
		return
		
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		last_collision_normal = collision.get_normal()
		
		var slide_velocity = velocity.slide(last_collision_normal)
		velocity = slide_velocity * wall_slide_factor

func handle_corner_correction() -> void:
	if !is_on_wall() || velocity.length() < 10.0:
		return
		
	for ray in rays.get_children():
		if ray is RayCast2D:
			ray.target_position = last_direction * corner_ray_length
			ray.force_raycast_update()
			
			if !ray.is_colliding():
				var correction = ray.global_position - global_position
				global_position += correction.normalized() * corner_correction_distance * get_physics_process_delta_time()
				break

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
	apply_camera_shake(1.0, 0.3)
	
func _on_min_tension_reached() -> void:
	pass
	
func _on_tension_changed(new_value: float, old_value: float) -> void:
	stress_level = new_value
	if signal_bus:
		signal_bus.emit_signal("stress_changed", stress_level, old_value)

func handle_running(input_direction: Vector2) -> void:
	var animation_prefix = "run"
	
	if abs(input_direction.x) > abs(input_direction.y) + direction_hysteresis:
		if input_direction.x > 0:
			animation_player.play(ANIMATIONS[animation_prefix + "_right"])
			last_direction = Vector2.RIGHT
		else:
			animation_player.play(ANIMATIONS[animation_prefix + "_left"])
			last_direction = Vector2.LEFT
	else:
		if input_direction.y > 0:
			animation_player.play(ANIMATIONS[animation_prefix + "_down"])
			last_direction = Vector2.DOWN
		else:
			animation_player.play(ANIMATIONS[animation_prefix + "_up"])
			last_direction = Vector2.UP

func handle_idle() -> void:
	var animation_prefix = "idle"
	var direction_suffix = "_down"
	
	if last_direction == Vector2.RIGHT:
		direction_suffix = "_right"
	elif last_direction == Vector2.LEFT:
		direction_suffix = "_left"
	elif last_direction == Vector2.UP:
		direction_suffix = "_up"
		
	animation_player.play(ANIMATIONS[animation_prefix + direction_suffix])

func handle_footsteps(delta: float) -> void:
	if !is_running:
		return
		
	var current_animation = animation_player.current_animation
	var position = animation_player.current_animation_position
	var length = animation_player.current_animation_length
	
	var normalized_pos = fmod(position, length) / length
	var threshold = footstep_threshold_run if sprint_active else footstep_threshold_walk
	
	if normalized_pos < threshold || normalized_pos > (1.0 - threshold):
		play_footstep()

func play_footstep() -> void:
	var sound_manager = get_node_or_null("/root/SoundManager")
	if sound_manager && sound_manager.has_method("play_footstep"):
		sound_manager.play_footstep(footstep_environment, footstep_volume)

func handle_interaction() -> void:
	var closest_interactable = null
	var min_distance = INF
	
	for body in interaction_area.get_overlapping_bodies():
		if body.has_method("interact"):
			var distance = global_position.distance_to(body.global_position)
			if distance < min_distance:
				min_distance = distance
				closest_interactable = body
	
	for area in interaction_area.get_overlapping_areas():
		if area.has_method("interact"):
			var distance = global_position.distance_to(area.global_position)
			if distance < min_distance:
				min_distance = distance
				closest_interactable = area
	
	if closest_interactable:
		closest_interactable.interact(self)

func apply_camera_shake(amount: float, duration: float = 0.5) -> void:
	if camera && camera.has_method("add_trauma"):
		camera.add_trauma(amount)
		
	if amount > 0.5 && tension_manager:
		tension_manager.add_tension(0.05)

func set_camera_zoom(zoom_level: float, duration: float = 1.0) -> void:
	if !camera:
		return
		
	var target_zoom = Vector2(zoom_level, zoom_level)
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(camera, "zoom", target_zoom, duration)

func show_objective(text: String, duration: float = 5.0) -> void:
	objective_text.text = text
	var animation_player = objective_label.get_node("AnimationPlayer")
	animation_player.stop()
	animation_player.play("show")
	
	var pulse_player = objective_label.get_node("PulseAnimation")
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
	animation_player.play("hide")
	
	var pulse_player = objective_label.get_node("PulseAnimation")
	pulse_player.stop()

func show_styled_objective(title: String, text: String, icon: String = "", hide_after: float = 5.0) -> void:
	objective_text.text = text
	
	var animation_player = objective_label.get_node("AnimationPlayer")
	animation_player.stop()
	animation_player.play("show_styled")
	
	$CanvasLayer/ObjectiveLabel/IconContainer/Icon.text = icon
	$CanvasLayer/ObjectiveLabel/TitleLabel.text = title
	
	await get_tree().create_timer(0.15).timeout
	apply_camera_shake(1.0, 0.3)
	
	await get_tree().create_timer(0.2).timeout
	set_camera_zoom(3.5, 0.7)
	
	if hide_after > 0:
		await get_tree().create_timer(hide_after).timeout
		hide_objective()

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

func update_debug_info() -> void:
	if !debug_mode || !debug_label:
		return
		
	var debug_text = "FPS: %d\n" % Engine.get_frames_per_second()
	debug_text += "POS: %s\n" % global_position
	debug_text += "VEL: %.2f\n" % velocity.length()
	debug_text += "SPRINT: %.1f%%\n" % (sprint_stamina / max_sprint_stamina * 100.0)
	debug_text += "HEALTH: %.1f%%\n" % (health_percentage * 100.0)
	debug_text += "STRESS: %.2f\n" % stress_level
	
	if tension_manager:
		debug_text += "TENSION: %.2f\n" % tension_manager.get_tension()
		debug_text += "LEVEL: %s\n" % tension_manager.get_level_name()
		
	debug_label.text = debug_text

func die() -> void:
	set_physics_process(false)
	
	if signal_bus:
		signal_bus.emit_signal("game_over", "Walter has died!")
	
	velocity = Vector2.ZERO
	animation_player.play("Death")
	
	await animation_player.animation_finished
	queue_free()

func apply_drug_effect(effect_type: String, duration: float = 30.0, intensity: float = 0.8) -> void:
	if not drug_effects_controller:
		return
		
	match effect_type.to_lower():
		"meth":
			drug_effects_controller.apply_meth_effect(duration, intensity)
		"weed":
			drug_effects_controller.apply_weed_effect(duration, intensity)
		"pills":
			drug_effects_controller.apply_pill_effect(duration, intensity)
		"withdrawal":
			drug_effects_controller.apply_withdrawal_effect(duration, intensity)
		_:
			drug_effects_controller.stop_current_effect()

func set_health(value: float) -> void:
	var old_health = current_health
	current_health = clamp(value, 0.0, max_health)
	health_percentage = current_health / max_health
	
	if signal_bus:
		signal_bus.emit_signal("health_changed", health_percentage, old_health / max_health)
	
	if current_health <= 0:
		die()

func take_damage(amount: float) -> void:
	set_health(current_health - amount)
	
	if signal_bus:
		signal_bus.emit_signal("damaged", amount, Vector2.ZERO)
	
	apply_camera_shake(min(amount / 20.0, 0.5))

func heal(amount: float) -> void:
	set_health(current_health + amount)
