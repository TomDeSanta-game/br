extends Node2D

var formation_offsets = [
	Vector2(-10, -5),
	Vector2(10, -5),
	Vector2(-5, 0),
	Vector2(5, 0),
	Vector2(-10, 5),
	Vector2(10, 5)
]
var raid_speed = 50.0
var officers = []
var raiding = true
var formation_center
var move_direction = Vector2(-1, 0)
var rotation_speed = 4.0
var time_passed = 0.0
var camera_target = Vector2(0, 0)
var daylight_intensity = 0.06
var daylight_direction = 1
var house_position = Vector2(-150, 80)
var target_reached = false
var camera_smoothness = 0.8
var camera_transition_time = 0.0
var camera_transition_duration = 2.0

func _ready() -> void:
	$Jesse.speed = 30.0
	
	for i in range(1, 7):
		officers.append(get_node("PoliceOfficers/PoliceOfficer" + str(i)))
	
	formation_center = calculate_formation_center()
	camera_target = formation_center
	$Camera2D.position = formation_center
	
	toggle_dust_particles(false)

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		raiding = !raiding
		toggle_dust_particles(raiding)
	
	time_passed += delta
	update_daylight_cycle(delta)
	
	if raiding:
		if !target_reached:
			move_officers_towards_house(delta)
		else:
			surround_house(delta)
			
		update_camera(delta)
		update_particles_intensity()

func calculate_formation_center() -> Vector2:
	var center = Vector2(0, 0)
	for officer in officers:
		center += officer.position
	return center / officers.size()

func move_officers_towards_house(delta: float) -> void:
	var direction_to_house = (house_position - formation_center).normalized()
	formation_center += direction_to_house * raid_speed * delta
	
	for i in range(officers.size()):
		var officer = officers[i]
		var target_position = formation_center + formation_offsets[i]
		
		officer.velocity = (target_position - officer.position) * 5
		
		var collision = officer.move_and_slide()
		if collision:
			handle_collision(officer)
		
		var polygon = officer.get_node("Polygon2D")
		polygon.rotation += sin(time_passed * 10 + i) * rotation_speed * delta
		
		var officer_details = officer.get_node("OfficerDetails")
		officer_details.rotation = polygon.rotation
		
	if formation_center.distance_to(house_position) < 60:
		if !target_reached:
			target_reached = true
			camera_transition_time = 0.0

func surround_house(delta: float) -> void:
	var house_surround_offsets = [
		Vector2(-60, -20), 
		Vector2(-20, -40),
		Vector2(20, -40),
		Vector2(60, -20),
		Vector2(60, 20),
		Vector2(-60, 20)
	]
	
	for i in range(officers.size()):
		var officer = officers[i]
		var target_position = house_position + house_surround_offsets[i]
		
		officer.velocity = (target_position - officer.position) * 3
		
		var collision = officer.move_and_slide()
		if collision:
			handle_collision(officer)
		
		var polygon = officer.get_node("Polygon2D")
		
		var direction_to_house = (house_position - officer.position).normalized()
		var target_angle = direction_to_house.angle() + PI/2
		polygon.rotation = lerp_angle(polygon.rotation, target_angle, delta * 2)
		
		var officer_details = officer.get_node("OfficerDetails")
		officer_details.rotation = polygon.rotation

func handle_collision(officer: CharacterBody2D) -> void:
	var push_direction = Vector2.ZERO
	
	for i in officer.get_slide_collision_count():
		var collision = officer.get_slide_collision(i)
		push_direction += collision.get_normal()
	
	if push_direction != Vector2.ZERO:
		formation_center += push_direction.normalized() * 10.0

func update_camera(delta: float) -> void:
	var prev_target = camera_target
	
	if target_reached:
		camera_transition_time += delta
		var transition_progress = min(camera_transition_time / camera_transition_duration, 1.0)
		var weight = smooth_transition(transition_progress)
		
		var center_target = formation_center
		var house_target = house_position
		
		camera_target = center_target.lerp(house_target, weight)
	else:
		camera_target = formation_center
	
	var camera_speed = delta * (1.0 - camera_smoothness)
	$Camera2D.position = $Camera2D.position.lerp(camera_target, camera_speed * 10.0)

func smooth_transition(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)

func toggle_dust_particles(enabled: bool) -> void:
	for officer in officers:
		var particles = officer.get_node("CPUParticles2D")
		particles.emitting = enabled

func update_particles_intensity() -> void:
	for officer in officers:
		var particles = officer.get_node("CPUParticles2D")
		var speed = officer.velocity.length()
		particles.amount = int(20 * (speed / 100.0)) + 10
		particles.initial_velocity_max = speed * 0.8
		
		if speed > 10:
			particles.emitting = true
		else:
			particles.emitting = false

func update_daylight_cycle(delta: float) -> void:
	daylight_intensity += daylight_direction * 0.001 * delta
	
	if daylight_intensity > 0.12:
		daylight_direction = -1
	elif daylight_intensity < 0.02:
		daylight_direction = 1
		
	if has_node("DynamicDaylight"):
		$DynamicDaylight.color.a = daylight_intensity