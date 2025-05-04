extends Area2D

@export var one_shot: bool = true
@export var auto_trigger: bool = false
@export var tension_amount: float = 0.2
@export var alert_police: bool = false
@export var trigger_group: String = ""
@export var trigger_message: String = ""

var triggered: bool = false
var manager = null

func _ready():
	collision_layer = 0
	collision_mask = 2
	
	body_entered.connect(_on_body_entered)
	
	manager = get_node_or_null("/root/TensionManager")
	
	if auto_trigger:
		call_deferred("trigger")

func _on_body_entered(body: Node2D):
	if body.is_in_group("player") and (!triggered or !one_shot):
		trigger()

func trigger():
	if one_shot and triggered:
		return
		
	triggered = true
	
	if manager:
		if tension_amount > 0:
			manager.add_tension(tension_amount)
			
		if alert_police:
			manager.alert_police()
	
	if trigger_message != "" and get_node_or_null("/root/SignalBus"):
		get_node("/root/SignalBus").emit_signal("show_alert_message", trigger_message)
	
	if trigger_group != "":
		get_tree().call_group(trigger_group, "on_tension_trigger", self)
	
	if one_shot:
		monitoring = false

func reset():
	triggered = false
	monitoring = true 