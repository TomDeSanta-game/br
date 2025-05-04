extends Node

signal tension_changed(new_value, old_value)
signal max_tension_reached
signal min_tension_reached
signal threshold_crossed(threshold_name, direction)

enum LEVEL {MINIMAL, LOW, MEDIUM, HIGH, CRITICAL}

const THRESHOLDS = {
	"MINIMAL": 0.0,
	"LOW": 0.25,
	"MEDIUM": 0.5,
	"HIGH": 0.75,
	"CRITICAL": 0.9
}

var current: float = 0.0
var target: float = 0.0
var max_value: float = 1.0
var min_value: float = 0.0
var decay_rate: float = 0.05
var rise_rate: float = 0.1
var decay_enabled: bool = true
var current_level: LEVEL = LEVEL.MINIMAL
var locked: bool = false
var modifiers = {}
var events = []

func _ready():
	set_process(true)

func _process(delta):
	if locked:
		return
		
	var old_tension = current
	
	if decay_enabled and target < current:
		current = move_toward(current, target, decay_rate * delta)
	elif target > current:
		current = move_toward(current, target, rise_rate * delta)
	
	current = clamp(current, min_value, max_value)
	
	if current != old_tension:
		tension_changed.emit(current, old_tension)
		check_threshold_crossing(old_tension)
		
	if current == max_value:
		max_tension_reached.emit()
	elif current == min_value:
		min_tension_reached.emit()
		
	process_events(delta)

func check_threshold_crossing(old_tension):
	var direction = 1 if current > old_tension else -1
	
	for threshold_name in THRESHOLDS:
		var threshold_value = THRESHOLDS[threshold_name]
		
		if (old_tension < threshold_value and current >= threshold_value) or \
		   (old_tension >= threshold_value and current < threshold_value):
			threshold_crossed.emit(threshold_name, direction)
			
			var new_level = get_level_from_value(current)	
			if new_level != current_level:
				current_level = new_level

func get_level_from_value(value: float) -> LEVEL:
	if value < THRESHOLDS["LOW"]:
		return LEVEL.MINIMAL
	elif value < THRESHOLDS["MEDIUM"]:
		return LEVEL.LOW
	elif value < THRESHOLDS["HIGH"]:
		return LEVEL.MEDIUM
	elif value < THRESHOLDS["CRITICAL"]:
		return LEVEL.HIGH
	else:
		return LEVEL.CRITICAL

func add(amount: float):
	if locked:
		return
		
	target = min(target + amount, max_value)

func reduce(amount: float):
	if locked:
		return
		
	target = max(target - amount, min_value)

func set_value(value: float):
	if locked:
		return
		
	target = clamp(value, min_value, max_value)

func set_immediate(value: float):
	if locked:
		return
		
	var old_tension = current
	current = clamp(value, min_value, max_value)
	target = current
	
	tension_changed.emit(current, old_tension)
	check_threshold_crossing(old_tension)

func lock():
	locked = true

func unlock():
	locked = false

func reset():
	var old_tension = current
	current = min_value
	target = min_value
	modifiers.clear()
	events.clear()
	
	tension_changed.emit(current, old_tension)
	check_threshold_crossing(old_tension)

func add_modifier(id: String, amount: float, duration: float = 0.0):
	modifiers[id] = {
		"amount": amount,
		"remaining": duration,
		"permanent": duration <= 0
	}
	
	add(amount)
	
	if duration > 0:
		await get_tree().create_timer(duration).timeout
		remove_modifier(id)

func remove_modifier(id: String):
	if modifiers.has(id):
		reduce(modifiers[id].amount)
		modifiers.erase(id)

func get_level() -> LEVEL:
	return current_level

func get_level_name() -> String:
	match current_level:
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
	return current / max_value

func add_event(event_data: Dictionary):
	events.append(event_data)

func process_events(delta: float):
	var i = events.size() - 1
	
	while i >= 0:
		var event = events[i]
		
		if event.has("duration"):
			event.elapsed = event.get("elapsed", 0.0) + delta
			
			if event.elapsed >= event.duration:
				if event.has("on_complete") and event.on_complete is Callable:
					event.on_complete.call()
				events.remove_at(i)
		
		if event.has("update") and event.update is Callable:
			event.update.call(delta, current)
			
		i -= 1
		
func get_percentage() -> float:
	return (current / max_value) * 100.0

func increase_rise_rate(multiplier: float, duration: float = 5.0):
	var original = rise_rate
	rise_rate *= multiplier
	
	get_tree().create_timer(duration).timeout.connect(func():
		rise_rate = original
	) 