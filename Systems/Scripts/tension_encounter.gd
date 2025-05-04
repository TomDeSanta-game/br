extends Node

signal encounter_started(encounter_name)
signal encounter_completed(encounter_name, success)
signal encounter_failed(encounter_name)
signal time_updated(time_remaining, total_time)

@export_category("Encounter Settings")
@export var encounter_name: String = "Tension Encounter"
@export var description: String = "Complete the encounter before time runs out"
@export var auto_start: bool = false
@export var duration: float = 30.0
@export var initial_tension: float = 0.3
@export var failure_tension: float = 0.6
@export var success_tension_reduction: float = 0.3
@export var failure_tension_boost: float = 0.4

@export_category("HUD Settings")
@export var show_timer: bool = true
@export var show_objective: bool = true
@export var critical_time_threshold: float = 5.0
@export var warning_time_threshold: float = 10.0

@export_category("Mission Failure")
@export var fail_if_detected: bool = false
@export var fail_on_timeout: bool = true

var manager = null
var active: bool = false
var time_remaining: float = 0.0
var objectives_completed: int = 0
var total_objectives: int = 0
var success: bool = false

func _ready():
	manager = get_node_or_null("/root/TensionManager")
	
	if auto_start:
		call_deferred("start_encounter")

func _process(delta):
	if !active:
		return
		
	if time_remaining > 0:
		time_remaining -= delta
		
		# Update time display
		if show_timer:
			time_updated.emit(time_remaining, duration)
			
		# Handle critical time warning
		if time_remaining <= critical_time_threshold:
			if manager && manager.tension_engine.current < failure_tension:
				manager.add_tension(delta * 0.1)
				
		# Check for timeout failure
		if time_remaining <= 0 && fail_on_timeout:
			fail_encounter()
	
func start_encounter():
	if active:
		return
		
	active = true
	time_remaining = duration
	
	# Apply initial tension spike
	if manager && initial_tension > 0:
		manager.add_tension(initial_tension)
	
	# Signal that encounter has started
	encounter_started.emit(encounter_name)
	
	# Show HUD elements if needed
	if show_objective && get_node_or_null("/root/SignalBus"):
		get_node("/root/SignalBus").emit_signal("show_mission_text", description)

func complete_encounter():
	if !active:
		return
		
	active = false
	success = true
	
	# Reduce tension on success
	if manager && success_tension_reduction > 0:
		manager.reduce_tension(success_tension_reduction)
	
	# Signal completion
	encounter_completed.emit(encounter_name, true)
	
	# Hide HUD elements if needed
	if show_objective && get_node_or_null("/root/SignalBus"):
		get_node("/root/SignalBus").emit_signal("hide_mission_text")

func fail_encounter():
	if !active:
		return
		
	active = false
	success = false
	
	# Increase tension on failure
	if manager && failure_tension_boost > 0:
		manager.add_tension(failure_tension_boost)
	
	# Signal failure
	encounter_failed.emit(encounter_name)
	
	# Update HUD elements if needed
	if show_objective && get_node_or_null("/root/SignalBus"):
		get_node("/root/SignalBus").emit_signal("update_mission_text", description + " (FAILED)")
		
		# Hide after a delay
		var timer = get_tree().create_timer(3.0)
		timer.timeout.connect(func(): get_node("/root/SignalBus").emit_signal("hide_mission_text"))

func set_objective_count(count: int):
	total_objectives = count
	objectives_completed = 0

func complete_objective():
	objectives_completed += 1
	
	# Check if all objectives are complete
	if objectives_completed >= total_objectives && total_objectives > 0:
		complete_encounter()
		
	# Update HUD if needed
	if show_objective && get_node_or_null("/root/SignalBus"):
		get_node("/root/SignalBus").emit_signal("update_mission_progress", objectives_completed, total_objectives)

func on_player_detected():
	if active && fail_if_detected:
		fail_encounter()

func reset():
	active = false
	time_remaining = 0.0
	objectives_completed = 0
	success = false 