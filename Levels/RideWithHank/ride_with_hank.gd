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
var raid_phase = 0
var breach_timer = 0.0
var breach_duration = 1.5
var escape_path = []
var jesse_escape_speed = 60.0
var jesse_escaping = false
var flash_effect_active = false
var flash_intensity = 0.0
var warning_effect_active = false
var warning_intensity = 0.0
var warning_flash_speed = 3.0
var camera_shake_intensity = 0.0
var door_broken = false
var time_to_meet_hank: float = 60.0
var timer_active: bool = false
var objective_initialized: bool = false
var in_passenger_seat: bool = false
var countdown_time: float = 0.0
var label_fade_time: float = 1.0
var timer_label_alpha: float = 0.0
var timer_label_target_alpha: float = 0.0
var timer_finished: bool = false
var hank_waiting: bool = false
var player_near_car: bool = false
var dialog_active: bool = false
var quest_started: bool = false
var tension_ramping: bool = false
var tension_target: float = 0.0
var tension_ramp_speed: float = 0.15
var on_main_road: bool = false
var police_response_level: int = 0
var police_scan_timer: float = 0.0
var meth_lab_panel_open: bool = false
var meth_lab_station_active: int = -1
var lab_step: int = 0
var ingredients_collected: int = 0
var meth_lab_success: bool = false
var player_hidden: bool = false
var hiding_spot_entered: bool = false
var hiding_cooldown: float = 0.0
var just_closed_door: bool = false
var can_open_door: bool = false
var siren_playing: bool = false
var quest_complete: bool = false
var signal_bus = null
var tension_manager = null
var police_response = null
var quest_manager = null
var current_quest = null
var player = null
var ui_manager = null
var quest_activated: bool = false
var timer_countdown_active: bool = false
var game_over_shown: bool = false
@onready var meth_lab_button = $MethLabButton
@onready var player_node = $Player
@onready var hank = $Hank
@onready var dialog_area = $DialogTrigger
@onready var meth_lab_entrance = $MethLabEntrance
@onready var jesse = $Jesse
var dialog_started = false
var entering_lab = false
@onready var objective_label: Control = $CanvasLayer/ObjectiveLabel
@onready var timer_label: Control = $CanvasLayer/TimerLabel
@onready var timer_time: Label = $CanvasLayer/TimerLabel/TimerTime
@onready var meth_lab_ui: Control = $CanvasLayer/MethLabGUI
@onready var game_over_screen: Control = $CanvasLayer/GameOverScreen
@onready var player_spawn_point: Node2D = $PlayerSpawnPoint
@onready var passenger_point: Node2D = $Map/HankCar/PassengerPoint
@onready var car: Node2D = $Map/HankCar
@onready var doors: Node = $Map/Doors
@onready var police_siren_audio: AudioStreamPlayer = $PoliceSiren
@onready var ambient_audio: AudioStreamPlayer = $AmbientAudio
@onready var tension_effects = $TensionEffects
@onready var map = $Map
@onready var nav_region = $Map/NavigationRegion2D
@onready var chase_trigger_area = $Map/ChaseTriggerArea
@onready var hiding_spot = $Map/HidingSpot
var hiding_spots = []
func _ready() -> void:
	$Jesse.speed = 30.0
	setup_jesse_escape_path()
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
	create_raid_effects()
	if meth_lab_button:
		meth_lab_button.hide_button()
	if dialog_area:
		dialog_area.body_entered.connect(_on_dialog_trigger_entered)
	if meth_lab_entrance:
		meth_lab_entrance.body_entered.connect(_on_meth_lab_entrance_entered)
	signal_bus = get_node("/root/SignalBus")
	tension_manager = get_node("/root/TensionManager")
	police_response = get_node("/root/PoliceResponse")
	quest_manager = get_node("/root/QuestManager")
	signal_bus.connect("game_over", _on_game_over)
	signal_bus.connect("quest_updated", _on_quest_updated)
	signal_bus.connect("meth_lab_step_complete", _on_meth_lab_step_complete)
	signal_bus.connect("ingredient_collected", _on_ingredient_collected)
	signal_bus.connect("meth_lab_success", _on_meth_lab_success)
	police_response.connect("police_response_changed", _on_police_response_changed)
	player = get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = player_spawn_point.global_position
		player.set_collision_layer_value(1, true)
		player.set_collision_mask_value(1, true)
	if objective_label:
		objective_label.visible = false
	if timer_label:
		timer_label.visible = false
		timer_label.modulate.a = 0.0
	if game_over_screen:
		game_over_screen.visible = false
	if meth_lab_ui:
		meth_lab_ui.visible = false
	find_hiding_spots()
	tension_manager.set_base_tension(0.0)
	tension_manager.set_tension(0.0)
	police_response.set_response_level(0)
	ambient_audio.play()
	get_tree().call_group("car_doors", "connect_signals", self)
	if not quest_activated:
		activate_quest()
func setup_jesse_escape_path():
	escape_path = [
		house_position + Vector2(20, 20),
		house_position + Vector2(40, 30),
		house_position + Vector2(60, 20),
		house_position + Vector2(100, 10),
		house_position + Vector2(140, 15),
		car_position + Vector2(-10, 0),
		car_position
	]
func create_raid_effects():
	var flash_rect = ColorRect.new()
	flash_rect.name = "BreachFlash"
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_rect.color = Color(1, 1, 1, 0)
	flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_rect.z_index = 100
	var flash_canvas = CanvasLayer.new()
	flash_canvas.name = "FlashCanvas"
	flash_canvas.add_child(flash_rect)
	add_child(flash_canvas)
	var warning_rect = ColorRect.new()
	warning_rect.name = "WarningEffect"
	warning_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	warning_rect.color = Color(0.9, 0.1, 0.1, 0)
	warning_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	warning_rect.z_index = 99
	var warning_canvas = CanvasLayer.new()
	warning_canvas.name = "WarningCanvas"
	warning_canvas.add_child(warning_rect)
	add_child(warning_canvas)
	var raid_text = Label.new()
	raid_text.name = "RaidText"
	raid_text.text = "POLICE RAID!"
	raid_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	raid_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	raid_text.add_theme_font_size_override("font_size", 32)
	raid_text.modulate = Color(1, 1, 1, 0)
	raid_text.set_anchors_preset(Control.PRESET_CENTER)
	var text_canvas = CanvasLayer.new()
	text_canvas.name = "TextCanvas"
	text_canvas.add_child(raid_text)
	add_child(text_canvas)
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
				raid_phase = 1
			surround_house(delta)
			if house_focus_complete:
				if raid_phase == 1:
					breach_timer += delta
					if breach_timer >= 2.0:
						initiate_breach()
						raid_phase = 2
				elif raid_phase == 2:
					update_breach(delta)
				elif raid_phase == 3:
					update_jesse_escape(delta)
				elif raid_phase == 4:
					update_car_focus(delta)
		update_camera(delta)
		update_particles_intensity()
		update_visual_effects(delta)
func initiate_breach():
	flash_effect_active = true
	camera_shake_intensity = 0.2
	door_broken = true
	if has_node("House/Door"):
		var door = get_node("House/Door")
		door.rotation = 0.4
		door.position.x += 5
	var smoke = CPUParticles2D.new()
	smoke.name = "DoorBreachSmoke"
	smoke.position = house_position + Vector2(-15, 15)
	smoke.amount = 30
	smoke.lifetime = 2.0
	smoke.explosiveness = 0.8
	smoke.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT
	smoke.direction = Vector2(0, -1)
	smoke.spread = 50
	smoke.gravity = Vector2(0, -10)
	smoke.initial_velocity_min = 20.0
	smoke.initial_velocity_max = 40.0
	smoke.scale_amount_min = 2.0
	smoke.scale_amount_max = 5.0
	smoke.color = Color(0.8, 0.8, 0.8, 0.6)
	add_child(smoke)
	warning_effect_active = true
	if has_node("TextCanvas/RaidText"):
		var raid_text = get_node("TextCanvas/RaidText")
		var tween = create_tween()
		tween.tween_property(raid_text, "modulate", Color(1, 0, 0, 1), 0.5)
		tween.tween_property(raid_text, "modulate", Color(1, 0, 0, 1), 1.0)
		tween.tween_property(raid_text, "modulate", Color(1, 0, 0, 0), 0.5)
	var escape_timer = Timer.new()
	escape_timer.wait_time = 1.5
	escape_timer.one_shot = true
	escape_timer.timeout.connect(start_jesse_escape)
	add_child(escape_timer)
	escape_timer.start()
func start_jesse_escape():
	raid_phase = 3
	jesse_escaping = true
	jesse.speed = jesse_escape_speed
	jesse.rotation = 0
	var jesse_dust = CPUParticles2D.new()
	jesse_dust.name = "JesseRunDust"
	jesse_dust.amount = 20
	jesse_dust.lifetime = 0.5
	jesse_dust.local_coords = false
	jesse_dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT
	jesse_dust.gravity = Vector2(0, 0)
	jesse_dust.initial_velocity_min = 5.0
	jesse_dust.initial_velocity_max = 10.0
	jesse_dust.scale_amount_min = 1.0
	jesse_dust.scale_amount_max = 2.0
	jesse_dust.color = Color(0.9, 0.8, 0.6, 0.4)
	jesse.add_child(jesse_dust)
func update_breach(delta):
	breach_timer += delta
	if flash_effect_active:
		flash_intensity = max(0, flash_intensity - delta * 2.0)
		if has_node("FlashCanvas/BreachFlash"):
			get_node("FlashCanvas/BreachFlash").color.a = flash_intensity
		if flash_intensity <= 0:
			flash_effect_active = false
	camera_shake_intensity = max(0, camera_shake_intensity - delta * 0.4)
	for i in range(officers.size()):
		var officer = officers[i]
		var target_pos = house_position + Vector2(randi_range(-30, 30), randi_range(-20, 20))
		officer.velocity = (target_pos - officer.position) * 4
		officer.move_and_slide()
func update_jesse_escape(delta):
	if jesse_escaping and escape_path.size() > 0:
		var target_point = escape_path[0]
		var direction = (target_point - jesse.position).normalized()
		jesse.velocity = direction * jesse.speed
		jesse.move_and_slide()
		jesse.rotation = direction.angle() + PI/2
		if jesse.position.distance_to(target_point) < 5:
			escape_path.remove_at(0)
			if escape_path.size() == 0:
				jesse_escaping = false
				raid_phase = 4
				car_focus_timer = 0
		if has_node("Jesse/JesseRunDust"):
			get_node("Jesse/JesseRunDust").emitting = true
	else:
		if has_node("Jesse/JesseRunDust"):
			get_node("Jesse/JesseRunDust").emitting = false
func update_visual_effects(delta):
	if warning_effect_active:
		warning_intensity = (sin(time_passed * warning_flash_speed) + 1) * 0.5 * 0.3
		if has_node("WarningCanvas/WarningEffect"):
			get_node("WarningCanvas/WarningEffect").color.a = warning_intensity
	if camera_shake_intensity > 0:
		var shake_offset = Vector2(
			randf_range(-1, 1) * camera_shake_intensity * 10,
			randf_range(-1, 1) * camera_shake_intensity * 10
		)
		$Camera2D.offset = shake_offset
	else:
		$Camera2D.offset = Vector2.ZERO
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
		get_tree().change_scene_to_file("res:
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
		get_tree().change_scene_to_file("res:
		SignalBus.player_entered_meth_lab.emit()
func find_hiding_spots():
	hiding_spots = get_tree().get_nodes_in_group("hiding_spot")
	for spot in hiding_spots:
		if spot.has_method("connect_signals"):
			spot.connect_signals(self)
func activate_quest():
	quest_activated = true
	current_quest = quest_manager.get_quest_by_id("GetToCar")
	if current_quest:
		quest_manager.activate_quest(current_quest)
		quest_manager.mark_objective_active(current_quest, "GetToTheRV")
		show_objective("Find and get to the RV.")
		start_timer()
func _process(delta):
	if timer_countdown_active and countdown_time > 0:
		countdown_time -= delta
		if countdown_time <= 0:
			countdown_time = 0
			timer_finished = true
			timer_countdown_active = false
			_on_time_expired()
		if timer_time:
			var minutes = int(countdown_time) / 60
			var seconds = int(countdown_time) % 60
			timer_time.text = "%02d:%02d" % [minutes, seconds]
	if timer_label:
		if timer_label.modulate.a != timer_label_target_alpha:
			timer_label.modulate.a = lerp(timer_label.modulate.a, timer_label_target_alpha, delta * label_fade_time)
	if tension_ramping:
		tension_manager.set_tension(lerp(tension_manager.get_tension(), tension_target, delta * tension_ramp_speed))
	if police_response_level > 0 and on_main_road:
		police_scan_timer += delta
		if police_scan_timer >= police_response.get_scan_interval():
			police_scan_timer = 0
			police_response.perform_scan(player)
	if player and hiding_spot and not player_hidden:
		var distance_to_spot = player.global_position.distance_to(hiding_spot.global_position)
		if distance_to_spot < 70 and police_response_level > 0:
			signal_bus.emit_signal("player_can_hide", true)
		else:
			signal_bus.emit_signal("player_can_hide", false)
	if hiding_cooldown > 0:
		hiding_cooldown -= delta
	if just_closed_door:
		just_closed_door = false
		can_open_door = false
		hiding_cooldown = 1.0
	if police_response_level > 0 and not siren_playing:
		start_police_siren()
	elif police_response_level == 0 and siren_playing:
		stop_police_siren()
func _on_game_over(reason: String):
	if game_over_shown:
		return
	game_over_shown = true
	if game_over_screen:
		game_over_screen.visible = true
		var reason_label = game_over_screen.get_node_or_null("ReasonLabel")
		if reason_label:
			reason_label.text = reason
		if player:
			player.set_process_input(false)
			player.set_physics_process(false)
func show_objective(text: String):
	if objective_label and not objective_label.visible:
		objective_label.visible = true
	var objective_text = objective_label.get_node_or_null("ContentPanel/ObjectiveText")
	if objective_text:
		objective_text.text = text
func start_timer():
	countdown_time = time_to_meet_hank
	timer_active = true
	timer_countdown_active = true
	timer_finished = false
	if timer_label:
		timer_label.visible = true
		timer_label_target_alpha = 1.0
func _on_time_expired():
	if not in_passenger_seat:
		signal_bus.emit_signal("game_over", "You did not reach the RV in time.")
	else:
		timer_label_target_alpha = 0.0
func _on_quest_updated(quest_id: String, objective_id: String, status: int):
	if quest_id == "GetToCar" and objective_id == "GetToTheRV" and status == quest_manager.OBJECTIVE_COMPLETED:
		quest_manager.mark_objective_active(current_quest, "HideFromCops")
		show_objective("Make it to the lab and cook some meth without getting caught.")
func _on_car_interaction_area_body_entered(body):
	if body.is_in_group("player"):
		player_near_car = true
		signal_bus.emit_signal("player_near_car", true)
func _on_car_interaction_area_body_exited(body):
	if body.is_in_group("player"):
		player_near_car = false
		signal_bus.emit_signal("player_near_car", false)
func _on_passenger_point_entered():
	if not in_passenger_seat and player:
		in_passenger_seat = true
		player.global_position = passenger_point.global_position
		player.visible = false
		player.set_physics_process(false)
		if current_quest:
			quest_manager.complete_objective(current_quest, "GetToTheRV")
		map.position.x -= 2000
		tension_target = 0.6
		tension_ramping = true
		on_main_road = true
		get_tree().create_timer(20.0).timeout.connect(func():
			if on_main_road:
				on_main_road = false
				map.position.x -= 1000
				player.global_position = map.get_node("LabEntrancePoint").global_position
				player.visible = true
				player.set_physics_process(true)
				show_objective("Enter the lab and cook some meth.")
		)
func _on_meth_lab_entrance_body_entered(body):
	if body.is_in_group("player") and not meth_lab_panel_open:
		show_meth_lab_gui()
func _on_meth_lab_entrance_body_exited(body):
	if body.is_in_group("player") and meth_lab_panel_open:
		hide_meth_lab_gui()
func show_meth_lab_gui():
	meth_lab_panel_open = true
	if meth_lab_ui:
		meth_lab_ui.visible = true
	if player:
		player.set_physics_process(false)
func hide_meth_lab_gui():
	meth_lab_panel_open = false
	if meth_lab_ui:
		meth_lab_ui.visible = false
	if player:
		player.set_physics_process(true)
func _on_meth_lab_step_complete(step: int):
	lab_step = step
	if tension_manager:
		tension_manager.add_tension(0.1)
func _on_ingredient_collected(ingredient_id: int):
	ingredients_collected += 1
func _on_meth_lab_success():
	meth_lab_success = true
	hide_meth_lab_gui()
	if player:
		player.set_physics_process(true)
	show_objective("Return to the RV with the meth.")
	tension_target = 0.9
	tension_ramping = true
	police_response.set_response_level(2)
	police_scan_timer = 0
	if current_quest:
		quest_manager.mark_objective_active(current_quest, "ReturnToRV")
	var meth_batch = load("res:
	call_deferred("add_child", meth_batch)
	meth_batch.global_position = player.global_position + Vector2(0, 40)
	chase_trigger_area.monitoring = true
func _on_chase_trigger_area_body_entered(body):
	if body.is_in_group("player") and meth_lab_success and not quest_complete:
		police_response.set_response_level(3)
		show_objective("ESCAPE! The police are in pursuit!")
func _on_police_response_changed(new_level: int):
	police_response_level = new_level
	police_scan_timer = 0
	if new_level > 0 and not tension_ramping:
		tension_target = 0.4 + (new_level * 0.2)
		tension_ramping = true
	elif new_level == 0:
		tension_target = 0.0
		tension_ramping = true
	signal_bus.emit_signal("police_response_changed", new_level)
func start_police_siren():
	siren_playing = true
	police_siren_audio.play()
func stop_police_siren():
	siren_playing = false
	police_siren_audio.stop()
func _on_exit_trigger_area_body_entered(body):
	if body.is_in_group("player") and meth_lab_success and not quest_complete:
		quest_complete = true
		if current_quest:
			quest_manager.complete_objective(current_quest, "ReturnToRV")
			quest_manager.complete_quest(current_quest)
		police_response.set_response_level(0)
		get_tree().change_scene_to_file("res:
func _on_hiding_spot_entered():
	if police_response_level > 0 and not player_hidden and hiding_cooldown <= 0:
		player_hidden = true
		hiding_spot_entered = true
		if player:
			player.visible = false
			player.set_physics_process(false)
		tension_target = max(0.3, tension_manager.get_tension() - 0.3)
		tension_ramping = true
func _on_hiding_spot_exited():
	if player_hidden and hiding_spot_entered:
		player_hidden = false
		hiding_spot_entered = false
		if player:
			player.visible = true
			player.set_physics_process(true)
			player.global_position = hiding_spot.global_position
		hiding_cooldown = 1.0
		tension_target = min(1.0, tension_manager.get_tension() + 0.2)
		tension_ramping = true
func _on_door_opened():
	if hiding_cooldown <= 0:
		can_open_door = true
func _on_door_closed():
	just_closed_door = true
func _on_main_road_area_body_entered(body):
	if body.is_in_group("player"):
		on_main_road = true
func _on_main_road_area_body_exited(body):
	if body.is_in_group("player"):
		on_main_road = false