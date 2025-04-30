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
var daylight_intensity = 0.06
var daylight_direction = 1
var house_position = Vector2(-150, 80)
var car_position = Vector2(24, 58)
var target_reached = false
var house_focus_complete = false
var car_focus_timer = 0.0
var house_focus_timer = 3.0
var camera_transition_time = 0.0
var camera_transition_duration = 3.5
var car_transition_duration = 2.5
var formation_center_smoothed = Vector2.ZERO
var camera_target_position = Vector2.ZERO
var camera_offset = Vector2(0, -15)
var initial_zoom = Vector2(5, 5)
var target_zoom = Vector2(4, 4)
var car_focus_zoom = Vector2(4.5, 4.5)
var current_zoom = Vector2(5, 5)
var zoom_speed = 0.5
var dust_particles = []
var dialogic_started = false
var meth_lab_unlocked = false

@onready var meth_lab_button = $MethLabButton
@onready var player = $Player
@onready var hank = $Hank
@onready var dialog_area = $DialogTrigger
@onready var meth_lab_entrance = $MethLabEntrance

var dialog_started = false
var entering_lab = false

func _ready() -> void:
	$Jesse.speed = 30.0
	
	for i in range(1, 7):
		officers.append(get_node("PoliceOfficers/PoliceOfficer" + str(i)))
		var particles = get_node("PoliceOfficers/PoliceOfficer" + str(i) + "/CPUParticles2D")
		dust_particles.append(particles)
	
	formation_center = calculate_formation_center()
	formation_center_smoothed = formation_center
	camera_target_position = formation_center
	
	$Camera2D.global_position = formation_center
	$Camera2D.zoom = initial_zoom
	current_zoom = initial_zoom
	
	toggle_dust_particles(false)
	
	$Camera2D.position_smoothing_enabled = true
	$Camera2D.position_smoothing_speed = 3.0
	
	if has_node("Background"):
		$Background.color = Color(0.95, 0.87, 0.73, 1.0)
		
	if has_node("AmbientVignette"):
		$AmbientVignette.color = Color(0.1, 0.05, 0.0, 0.4)
	
	if has_node("House/HouseBase"):
		$House/HouseBase.color = Color(0.8, 0.65, 0.45, 1.0)
	
	if has_node("House/HouseRoof"):
		$House/HouseRoof.color = Color(0.5, 0.3, 0.15, 1.0)
	
	create_desert_dust()
	
	if meth_lab_button:
		meth_lab_button.hide_button()

	if dialog_area:
		dialog_area.body_entered.connect(_on_dialog_trigger_entered)
		
	if meth_lab_entrance:
		meth_lab_entrance.body_entered.connect(_on_meth_lab_entrance_entered)

func create_desert_dust() -> void:
	var desert_dust = CPUParticles2D.new()
	desert_dust.name = "DesertDust"
	desert_dust.amount = 30
	desert_dust.lifetime = 6.0
	desert_dust.preprocess = 3.0
	desert_dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	desert_dust.emission_rect_extents = Vector2(400, 200)
	desert_dust.gravity = Vector2(10, -5)
	desert_dust.initial_velocity_min = 3.0
	desert_dust.initial_velocity_max = 8.0
	desert_dust.scale_amount_min = 0.5
	desert_dust.scale_amount_max = 2.0
	desert_dust.color = Color(0.9, 0.8, 0.6, 0.1)
	add_child(desert_dust)

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		raiding = !raiding
		toggle_dust_particles(raiding)
	
	if Input.is_action_just_pressed("DEBUG") and meth_lab_unlocked:
		open_meth_lab()
	
	time_passed += delta
	update_daylight_cycle(delta)
	
	if raiding:
		if !target_reached:
			move_officers_towards_house(delta)
		else:
			house_focus_timer -= delta
			if house_focus_timer <= 0 && !house_focus_complete:
				house_focus_complete = true
				camera_transition_time = 0.0
			
			surround_house(delta)
			
			if house_focus_complete:
				update_car_focus(delta)
			
		update_camera(delta)
		update_particles_intensity()

func update_car_focus(delta: float) -> void:
	car_focus_timer += delta
	
	if car_focus_timer >= 1.0 && !dialogic_started:
		dialogic_started = true
		meth_lab_unlocked = true
		if Engine.has_singleton("Dialogic"):
			var Dialogic = Engine.get_singleton("Dialogic")
			Dialogic.start("ridewithhank")
			Dialogic.timeline_ended.connect(_on_dialogic_timeline_ended)
		elif has_node("/root/Dialogic"):
			var Dialogic = get_node("/root/Dialogic")
			Dialogic.start("ridewithhank")
			Dialogic.timeline_ended.connect(_on_dialogic_timeline_ended)

func open_meth_lab() -> void:
	if meth_lab_unlocked:
		get_tree().change_scene_to_file("res://UI/Scenes/MethLab/MethLabGame.tscn")

func _on_dialogic_timeline_ended():
	meth_lab_unlocked = true
	if meth_lab_button:
		meth_lab_button.show_button()

func calculate_formation_center() -> Vector2:
	var center = Vector2(0, 0)
	for officer in officers:
		center += officer.position
	return center / officers.size()

func move_officers_towards_house(delta: float) -> void:
	var direction_to_house = (house_position - formation_center).normalized()
	formation_center += direction_to_house * raid_speed * delta
	
	formation_center_smoothed = formation_center_smoothed.lerp(formation_center, delta * 1.5)
	
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
	var approach_vector = Vector2.ZERO
	
	if target_reached:
		if !house_focus_complete:
			camera_transition_time += delta
			var transition_progress = min(camera_transition_time / camera_transition_duration, 1.0)
			var weight = ease_out_cubic(transition_progress)
			
			var direction_to_house = (house_position - formation_center_smoothed).normalized()
			approach_vector = direction_to_house * 20.0 * (1.0 - weight)
			
			var target_pos = house_position + Vector2(0, -10)
			
			camera_target_position = lerp(
				formation_center_smoothed + approach_vector + camera_offset,
				target_pos,
				weight
			)
			
			current_zoom = current_zoom.lerp(target_zoom, delta * zoom_speed)
		else:
			camera_transition_time += delta
			var car_transition_progress = min(camera_transition_time / car_transition_duration, 1.0)
			var car_weight = ease_out_cubic(car_transition_progress)
			
			var target_pos = car_position + Vector2(0, -5)
			
			camera_target_position = lerp(
				camera_target_position,
				target_pos,
				car_weight * delta * 3.0
			)
			
			current_zoom = current_zoom.lerp(car_focus_zoom, delta * 3.0)
	else:
		var direction_to_house = (house_position - formation_center_smoothed).normalized()
		approach_vector = direction_to_house * 20.0
		camera_target_position = formation_center_smoothed + approach_vector + camera_offset
	
	$Camera2D.global_position = camera_target_position
	$Camera2D.zoom = current_zoom

func ease_out_cubic(t: float) -> float:
	return 1.0 - pow(1.0 - t, 3)
		
func toggle_dust_particles(enabled: bool) -> void:
	for particles in dust_particles:
		particles.emitting = enabled

func update_particles_intensity() -> void:
	for i in range(officers.size()):
		var officer = officers[i]
		var particles = dust_particles[i]
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

func _on_dialog_trigger_entered(body):
	if body.is_in_group("Player") and not dialog_started:
		dialog_started = true
		Dialogic.start_timeline("ridewithhank")

func _on_meth_lab_entrance_entered(body):
	if body.is_in_group("Player") and not entering_lab:
		entering_lab = true
		get_tree().change_scene_to_file("res://UI/Scenes/MethLab/MethLabGame.tscn")
		SignalBus.player_entered_meth_lab.emit()