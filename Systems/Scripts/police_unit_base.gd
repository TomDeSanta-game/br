extends CharacterBody2D

enum STATE {PATROL, INVESTIGATE, CHASE, ATTACK, RETURN}

@export_category("Movement")
@export var speed: float = 120.0
@export var acceleration: float = 500.0
@export var rotation_speed: float = 5.0
@export var pursuit_speed_multiplier: float = 1.5
@export var navigation_update_time: float = 0.5

@export_category("Detection")
@export var vision_distance: float = 300.0
@export var vision_angle: float = 60.0
@export var memory_time: float = 20.0
@export var hearing_range: float = 150.0

@export_category("Combat")
@export var health: float = 100.0
@export var damage: float = 10.0
@export var attack_range: float = 50.0
@export var attack_cooldown: float = 1.0

@onready var navigation_agent = $NavigationAgent2D if has_node("NavigationAgent2D") else null
@onready var vision_raycast = $VisionRayCast if has_node("VisionRayCast") else null
@onready var animation_player = $AnimationPlayer if has_node("AnimationPlayer") else null
@onready var sprite = $Sprite2D if has_node("Sprite2D") else null
@onready var detection_area = $DetectionArea if has_node("DetectionArea") else null

var current_state = STATE.PATROL
var target = null
var last_target_position = null
var target_memory_timer = 0.0
var nav_update_timer = 0.0
var patrol_points = []
var current_patrol_index = 0
var current_patrol_wait_time = 0.0
var attack_timer = 0.0
var current_direction = Vector2.RIGHT
var home_position = null
var dead = false
var signal_bus = null
var police_response = null

func _ready():
	signal_bus = get_node_or_null("/root/SignalBus")
	police_response = get_node_or_null("/root/PoliceResponse")
	
	if navigation_agent:
		navigation_agent.path_desired_distance = 16.0
		navigation_agent.target_desired_distance = 32.0
	
	home_position = global_position
	

	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_body_entered)
	
	set_state(STATE.PATROL)
	update_patrol_route()

func _physics_process(delta):
	if dead:
		return
		

	if target_memory_timer > 0:
		target_memory_timer -= delta
	
	nav_update_timer -= delta
	
	if attack_timer > 0:
		attack_timer -= delta
	

	match current_state:
		STATE.PATROL:
			process_patrol(delta)
		STATE.INVESTIGATE:
			process_investigate(delta)
		STATE.CHASE:
			process_chase(delta)
		STATE.ATTACK:
			process_attack(delta)
		STATE.RETURN:
			process_return(delta)
	

	move_and_slide()
	

	check_vision()
	

	update_animation()

func process_patrol(delta):
	if patrol_points.size() == 0:
		velocity = Vector2.ZERO
		return
	
	if current_patrol_wait_time > 0:
		current_patrol_wait_time -= delta
		velocity = Vector2.ZERO
		return
	
	var target_point = patrol_points[current_patrol_index]
	
	if global_position.distance_to(target_point) < 20:

		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		current_patrol_wait_time = randf_range(1.0, 3.0)
		velocity = Vector2.ZERO
		return
	

	if nav_update_timer <= 0 && navigation_agent:
		navigation_agent.target_position = target_point
		nav_update_timer = navigation_update_time
	
	move_toward_point(target_point, delta, speed)

func process_investigate(delta):
	if !last_target_position:
		set_state(STATE.PATROL)
		return
	
	if global_position.distance_to(last_target_position) < 20:

		current_patrol_wait_time = randf_range(3.0, 5.0)
		
		if current_patrol_wait_time > 0:
			current_patrol_wait_time -= delta
			

			current_direction = current_direction.rotated(delta * rotation_speed * 0.5)
			
			if current_patrol_wait_time <= 0:
				set_state(STATE.PATROL)
				
			velocity = Vector2.ZERO
			return
	

	if nav_update_timer <= 0 && navigation_agent:
		navigation_agent.target_position = last_target_position
		nav_update_timer = navigation_update_time
	
	move_toward_point(last_target_position, delta, speed)

func process_chase(delta):
	if !target || !is_instance_valid(target):
		if target_memory_timer <= 0:
			set_state(STATE.INVESTIGATE)
			if signal_bus:
				signal_bus.emit_signal("game_event", "target_lost", {"position": last_target_position})
		return
	
	var target_pos = target.global_position
	last_target_position = target_pos
	target_memory_timer = memory_time
	

	if global_position.distance_to(target_pos) < attack_range:
		set_state(STATE.ATTACK)
		return
	

	if nav_update_timer <= 0 && navigation_agent:
		navigation_agent.target_position = target_pos
		nav_update_timer = navigation_update_time
	
	move_toward_point(target_pos, delta, speed * pursuit_speed_multiplier)

func process_attack(delta):
	if !target || !is_instance_valid(target):
		if target_memory_timer <= 0:
			set_state(STATE.INVESTIGATE)
			if signal_bus:
				signal_bus.emit_signal("game_event", "target_lost", {"position": last_target_position})
		return
	
	var target_pos = target.global_position
	last_target_position = target_pos
	target_memory_timer = memory_time
	

	var direction = global_position.direction_to(target_pos)
	current_direction = direction
	

	if global_position.distance_to(target_pos) < attack_range:
		if attack_timer <= 0:
			attack()
			attack_timer = attack_cooldown
			

		velocity = velocity.lerp(Vector2.ZERO, delta * 3.0)
	else:

		set_state(STATE.CHASE)

func process_return(delta):
	if !home_position:
		set_state(STATE.PATROL)
		return
	
	if global_position.distance_to(home_position) < 20:
		queue_free()
		return
	

	if nav_update_timer <= 0 && navigation_agent:
		navigation_agent.target_position = home_position
		nav_update_timer = navigation_update_time
	
	move_toward_point(home_position, delta, speed * 0.8)

func move_toward_point(point: Vector2, delta: float, move_speed: float):
	var direction: Vector2
	
	if navigation_agent && navigation_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		return
	
	if navigation_agent:
		var next_path_position = navigation_agent.get_next_path_position()
		direction = global_position.direction_to(next_path_position)
	else:
		direction = global_position.direction_to(point)
	
	current_direction = direction
	

	var target_velocity = direction * move_speed
	velocity = velocity.lerp(target_velocity, delta * acceleration / move_speed)

func check_vision():
	if vision_raycast && target && is_instance_valid(target):

		var to_target = target.global_position - global_position
		var distance = to_target.length()
		
		if distance > vision_distance:
			return
		
		var angle = abs(current_direction.angle_to(to_target.normalized()))
		
		if angle > deg_to_rad(vision_angle):
			return
		

		vision_raycast.target_position = to_target
		vision_raycast.force_raycast_update()
		
		if !vision_raycast.is_colliding() || vision_raycast.get_collider() == target:
			if current_state != STATE.CHASE && current_state != STATE.ATTACK:
				if signal_bus:
					signal_bus.emit_signal("game_event", "player_spotted", {"player": target, "position": target.global_position})
				set_state(STATE.CHASE)

func update_patrol_route():
	patrol_points.clear()
	

	var points = get_tree().get_nodes_in_group("patrol_point")
	
	if points.size() > 0:

		for point in points:
			patrol_points.append(point.global_position)
	else:

		var radius = 200.0
		for i in range(4):
			var angle = i * TAU / 4.0 + randf_range(-0.5, 0.5)
			var distance = radius * randf_range(0.5, 1.0)
			var point = home_position + Vector2(cos(angle), sin(angle)) * distance
			patrol_points.append(point)

func set_state(new_state):
	if current_state == new_state:
		return
	
	current_state = new_state
	
	match current_state:
		STATE.PATROL:
			update_patrol_route()
		STATE.INVESTIGATE:
			pass
		STATE.CHASE:
			if target && is_instance_valid(target) && signal_bus:
				signal_bus.emit_signal("game_event", "player_spotted", {"player": target, "position": target.global_position})
				if police_response:
					police_response._on_player_detected("police")
		STATE.ATTACK:
			pass
		STATE.RETURN:
			target = null
			last_target_position = null

func attack():
	if !target || !is_instance_valid(target):
		return
	

	if animation_player && animation_player.has_animation("attack"):
		animation_player.play("attack")
	

	if target.has_method("take_damage"):
		target.take_damage(damage, self)
	elif target.get("health") != null:
		target.health -= damage

func take_damage(amount: float, attacker = null):
	health -= amount
	
	if health <= 0 && !dead:
		die()
	

	if attacker && !dead:
		target = attacker
		set_state(STATE.CHASE)

func die():
	dead = true
	

	if animation_player && animation_player.has_animation("death"):
		animation_player.play("death")
		await animation_player.animation_finished
	
	if signal_bus:
		signal_bus.emit_signal("game_event", "unit_destroyed", {"unit": self})
	queue_free()

func update_animation():
	if dead:
		return
	
	var anim = "idle"
	
	if velocity.length() > 10:
		anim = "walk"
		

		if sprite:
			if current_direction.x < 0:
				sprite.flip_h = true
			else:
				sprite.flip_h = false
	
	match current_state:
		STATE.ATTACK:
			if attack_timer > attack_cooldown * 0.8:
				anim = "attack"
		STATE.CHASE:
			anim = "run" if animation_player && animation_player.has_animation("run") else "walk"
	
	if animation_player && animation_player.has_animation(anim) && animation_player.current_animation != anim:
		animation_player.play(anim)

func set_target(new_target):
	target = new_target
	
	if target:
		last_target_position = target.global_position
		target_memory_timer = memory_time
		set_state(STATE.CHASE)

func return_to_station():
	set_state(STATE.RETURN)

func _on_detection_area_body_entered(body):
	if body.is_in_group("player") && current_state != STATE.ATTACK && current_state != STATE.CHASE:
		target = body
		last_target_position = body.global_position
		target_memory_timer = memory_time
		
		if signal_bus:
			signal_bus.emit_signal("game_event", "player_spotted", {"player": target, "position": target.global_position})
		set_state(STATE.CHASE) 