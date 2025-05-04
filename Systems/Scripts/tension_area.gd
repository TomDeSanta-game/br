extends Area2D

signal player_entered_area(area_name)
signal player_exited_area(area_name)

@export var area_name: String = "Tension Area"
@export var base_tension: float = 0.2
@export var tension_multiplier: float = 1.0
@export var heat_modifier: float = 0.2
@export var tension_buildup_rate: float = 0.05
@export var apply_visual_effects: bool = true
@export var entry_message: String = ""

var player_in_area: bool = false
var original_tension_rate: float = 0.0
var current_tension: float = 0.0
var manager = null
var effects = null

func _ready():
	collision_layer = 0
	collision_mask = 2
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	manager = get_node_or_null("/root/TensionManager")
	if manager:
		original_tension_rate = manager.tension_engine.rise_rate
		
	effects = get_node_or_null("/root/TensionEffects")

func _process(delta):
	if !player_in_area || !manager:
		return
		
	if base_tension > 0:
		current_tension += tension_buildup_rate * delta
		current_tension = min(current_tension, base_tension)
		
		manager.add_tension(current_tension * tension_multiplier * delta)

func _on_body_entered(body: Node2D):
	if !body.is_in_group("player"):
		return
		
	player_in_area = true
	player_entered_area.emit(area_name)
	
	if manager:
		manager.add_tension(base_tension * 0.25)
		
		if manager.tension_engine.rise_rate != original_tension_rate:
			original_tension_rate = manager.tension_engine.rise_rate
			
		manager.tension_engine.rise_rate = original_tension_rate * (1.0 + heat_modifier)
	
	if entry_message != "" and get_node_or_null("/root/SignalBus"):
		get_node("/root/SignalBus").emit_signal("show_alert_message", entry_message)
		
	if apply_visual_effects && effects:
		add_visual_effects()

func _on_body_exited(body: Node2D):
	if !body.is_in_group("player"):
		return
		
	player_in_area = false
	player_exited_area.emit(area_name)
	
	if manager:
		current_tension = 0.0
		manager.tension_engine.rise_rate = original_tension_rate
		
	if apply_visual_effects && effects:
		clear_visual_effects()

func add_visual_effects():
	if !effects:
		effects = get_node_or_null("/root/TensionEffects")
		
	if !effects:
		return
		
	var effect_level = get_effect_level()
	
	match effect_level:
		0:
			effects.add_effect("slight_desaturation", 0.5)
		1:
			effects.add_effect("medium_desaturation", 0.6)
			effects.add_effect("light_vignette", 0.4)
		2:
			effects.add_effect("heavy_desaturation", 0.8)
			effects.add_effect("medium_vignette", 0.7)

func clear_visual_effects():
	if !effects:
		effects = get_node_or_null("/root/TensionEffects")
		
	if !effects:
		return
		
	effects.remove_effect("slight_desaturation")
	effects.remove_effect("medium_desaturation")
	effects.remove_effect("heavy_desaturation")
	effects.remove_effect("light_vignette")
	effects.remove_effect("medium_vignette")

func get_effect_level() -> int:
	if base_tension < 0.3:
		return 0
	elif base_tension < 0.6:
		return 1
	else:
		return 2

func _exit_tree() -> void:
	if player_in_area && manager:
		manager.tension_engine.rise_rate = original_tension_rate 