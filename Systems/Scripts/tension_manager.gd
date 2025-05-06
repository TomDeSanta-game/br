extends Node
signal player_detected(detector_type)
signal police_alerted
signal heat_level_changed(new_level, old_level)
enum HEAT {NONE, LOW, MEDIUM, HIGH, WANTED}
var tension_engine
var current_heat: int = HEAT.NONE
var suspicion_active: bool = false
var detection_meter: float = 0.0
var detection_threshold: float = 0.9
var police_cooldown: float = 0.0
var police_cooldown_duration: float = 120.0
var wanted_timer: float = 0.0
var wanted_duration: float = 300.0
var suspicion_zones = []
func _ready():
	tension_engine = load("res:
	add_child(tension_engine)
	var signal_bus = get_node_or_null("/root/SignalBus")
	if signal_bus:
		signal_bus.tension_changed.connect(_on_tension_changed)
		signal_bus.threshold_crossed.connect(_on_threshold_crossed)
func _process(delta):
	_update_timers(delta)
	_update_detection(delta)
func _update_timers(delta):
	if police_cooldown > 0:
		police_cooldown -= delta
	if wanted_timer > 0:
		wanted_timer -= delta
		if wanted_timer <= 0:
			reduce_heat()
func _update_detection(delta):
	if suspicion_active:
		var detection_speed = 0.1 * (1.0 + tension_engine.get_normalized())
		detection_meter = min(detection_meter + detection_speed * delta, 1.0)
		if detection_meter >= detection_threshold:
			alert_police()
	else:
		detection_meter = max(detection_meter - 0.2 * delta, 0.0)
func add_tension(amount):
	tension_engine.add(amount)
func reduce_tension(amount):
	tension_engine.reduce(amount)
func set_suspicion_active(active):
	suspicion_active = active
	if !active:
		detection_meter = 0.0
func register_suspicion_zone(zone):
	if !suspicion_zones.has(zone):
		suspicion_zones.append(zone)
func unregister_suspicion_zone(zone):
	suspicion_zones.erase(zone)
func alert_police():
	if current_heat < HEAT.WANTED and police_cooldown <= 0:
		police_alerted.emit()
		increase_heat()
		add_tension(0.2)
		police_cooldown = police_cooldown_duration
		if current_heat == HEAT.HIGH:
			current_heat = HEAT.WANTED
			wanted_timer = wanted_duration
func increase_heat():
	var old_level = current_heat
	current_heat = min(current_heat + 1, HEAT.WANTED)
	if old_level != current_heat:
		heat_level_changed.emit(current_heat, old_level)
func reduce_heat():
	var old_level = current_heat
	current_heat = max(current_heat - 1, HEAT.NONE)
	if old_level != current_heat:
		heat_level_changed.emit(current_heat, old_level)
func get_heat_name() -> String:
	match current_heat:
		HEAT.NONE:
			return "NONE"
		HEAT.LOW:
			return "LOW"
		HEAT.MEDIUM:
			return "MEDIUM"
		HEAT.HIGH:
			return "HIGH"
		HEAT.WANTED:
			return "WANTED"
		_:
			return "UNKNOWN"
func is_wanted() -> bool:
	return current_heat == HEAT.WANTED
func reset():
	var old_level = current_heat
	current_heat = HEAT.NONE
	police_cooldown = 0.0
	wanted_timer = 0.0
	detection_meter = 0.0
	tension_engine.reset()
	if old_level != current_heat:
		heat_level_changed.emit(current_heat, old_level)
func _on_tension_changed(new_value, old_value):
	if new_value > 0.7 and old_value <= 0.7:
		_add_environment_effects()
	elif new_value <= 0.7 and old_value > 0.7:
		_remove_environment_effects()
func _on_threshold_crossed(threshold_name, direction):
	if threshold_name == "HIGH" or threshold_name == "CRITICAL":
		if direction > 0:
			_add_environment_effects()
		else:
			_remove_environment_effects()
func _add_environment_effects():
	var sound_manager = get_node_or_null("/root/SoundManager")
	if sound_manager:
		sound_manager.play_music("tense", true)
func _remove_environment_effects():
	var sound_manager = get_node_or_null("/root/SoundManager")
	if sound_manager:
		sound_manager.fade_music_out()
		sound_manager.play_music("normal", true)
func player_detected_by_npc(npc_type):
	player_detected.emit(npc_type)
	match npc_type:
		"civilian":
			add_tension(0.05)
		"guard":
			add_tension(0.15)
		"police":
			add_tension(0.25)
			alert_police()
		"cartel":
			add_tension(0.4)
			alert_police()
	if npc_type in ["police", "cartel"]:
		increase_heat()