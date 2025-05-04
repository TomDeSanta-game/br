extends Node

@export_category("Tension Settings")
@export var enable_tension: bool = true
@export var default_tension: float = 0.0
@export var tension_decay_rate: float = 0.05
@export var tension_rise_rate: float = 0.1
@export var min_tension: float = 0.0
@export var max_tension: float = 1.0

@export_category("Thresholds")
@export var minimal_threshold: float = 0.1
@export var low_threshold: float = 0.3
@export var medium_threshold: float = 0.5
@export var high_threshold: float = 0.7
@export var critical_threshold: float = 0.9

enum LEVEL {MINIMAL, LOW, MEDIUM, HIGH, CRITICAL}

var signal_bus = null
var current = 0.0
var target = 0.0
var locked = false
var active_modifiers = {}
var last_level = LEVEL.MINIMAL
var thresholds = {}

func _ready():
	signal_bus = get_node_or_null("/root/SignalBus")
	
	thresholds = {
		"MINIMAL": minimal_threshold,
		"LOW": low_threshold,
		"MEDIUM": medium_threshold,
		"HIGH": high_threshold,
		"CRITICAL": critical_threshold
	}
	
	current = default_tension
	target = default_tension
	
	if signal_bus:
		reset()

func _process(delta):
	if !enable_tension || locked:
		return
	
	var old_tension = current
	
	if current < target:
		current = min(current + tension_rise_rate * delta, target)
	elif current > target:
		current = max(current - tension_decay_rate * delta, target)
	
	current = clamp(current, min_tension, max_tension)
	
	if current != old_tension:
		check_tension_level()
		
		if signal_bus:
			signal_bus.emit_signal("tension_changed", current, old_tension)
		
		if current >= max_tension && old_tension < max_tension:
			if signal_bus:
				signal_bus.emit_signal("max_tension_reached")
		elif current <= min_tension && old_tension > min_tension:
			if signal_bus:
				signal_bus.emit_signal("min_tension_reached")

func add_tension(amount):
	if !enable_tension:
		return
	
	target = min(target + amount, max_tension)

func reduce_tension(amount):
	if !enable_tension:
		return
	
	target = max(target - amount, min_tension)

func set_tension(value):
	if !enable_tension:
		return
	
	target = clamp(value, min_tension, max_tension)

func lock_tension():
	locked = true

func unlock_tension():
	locked = false

func reset():
	current = default_tension
	target = default_tension
	active_modifiers.clear()
	last_level = get_level_from_value(current)
	
	if signal_bus:
		signal_bus.emit_signal("tension_changed", current, current)

func get_tension():
	return current

func get_level():
	return get_level_from_value(current)

func get_level_from_value(value):
	if value < minimal_threshold:
		return LEVEL.MINIMAL
	elif value < low_threshold:
		return LEVEL.LOW
	elif value < medium_threshold:
		return LEVEL.MEDIUM
	elif value < high_threshold:
		return LEVEL.HIGH
	else:
		return LEVEL.CRITICAL

func check_tension_level():
	var current_level = get_level()
	
	if current_level != last_level:
		check_threshold_crossed(current_level, last_level)
		last_level = current_level

func check_threshold_crossed(new_level, old_level):
	var direction = "up" if new_level > old_level else "down"
	var threshold_name = ""
	
	match new_level:
		LEVEL.MINIMAL:
			threshold_name = "MINIMAL"
		LEVEL.LOW:
			threshold_name = "LOW"
		LEVEL.MEDIUM:
			threshold_name = "MEDIUM"
		LEVEL.HIGH:
			threshold_name = "HIGH"
		LEVEL.CRITICAL:
			threshold_name = "CRITICAL"
	
	if signal_bus && threshold_name != "":
		signal_bus.emit_signal("threshold_crossed", threshold_name, direction)

func add_modifier(name, value):
	active_modifiers[name] = value
	update_modifiers()

func remove_modifier(name):
	if active_modifiers.has(name):
		active_modifiers.erase(name)
		update_modifiers()

func update_modifiers():
	var total_modifier = 0.0
	
	for modifier in active_modifiers.values():
		total_modifier += modifier
	
	add_tension(total_modifier)

func get_level_name() -> String:
	match get_level():
		LEVEL.MINIMAL:
			return "MINIMAL"
		LEVEL.LOW:
			return "LOW"
		LEVEL.MEDIUM:
			return "MEDIUM"
		LEVEL.HIGH:
			return "HIGH"
		LEVEL.CRITICAL:
			return "CRITICAL"
		_:
			return "UNKNOWN"

func get_normalized() -> float:
	return current / max_tension

func get_percentage() -> float:
	return (current / max_tension) * 100.0

func increase_rise_rate(multiplier: float, duration: float = 5.0):
	var original = tension_rise_rate
	tension_rise_rate *= multiplier
	
	get_tree().create_timer(duration).timeout.connect(func():
		tension_rise_rate = original
	) 