extends Control

@onready var heat_progress = $HeatProgress
@onready var heat_label = $HeatLabel
@onready var detection_progress = $DetectionProgress
@onready var animation_player = $AnimationPlayer

var manager
var displayed_heat = 0
var heat_colors = {
	0: Color(0.2, 0.8, 0.2),
	1: Color(0.8, 0.8, 0.2),
	2: Color(0.9, 0.6, 0.1),
	3: Color(0.9, 0.2, 0.2),
	4: Color(0.9, 0.1, 0.1)
}

func _ready() -> void:
	modulate.a = 0
	
	await get_tree().process_frame
	
	manager = get_node_or_null("/root/TensionManager")
	if manager:
		manager.heat_level_changed.connect(_on_heat_changed)
		manager.player_detected.connect(_on_player_detected)
		manager.police_alerted.connect(_on_police_alerted)
		
		show_bar()
		update_display()

func _process(delta: float) -> void:
	if !manager:
		return
		
	heat_progress.value = manager.tension_engine.get_normalized()
	detection_progress.value = manager.detection_meter
	
	if manager.suspicion_active && !animation_player.is_playing():
		animation_player.play("detection_pulse")
	elif !manager.suspicion_active && animation_player.is_playing() && animation_player.current_animation == "detection_pulse":
		animation_player.stop()
		detection_progress.modulate = Color(1, 1, 1, 1)

func update_display() -> void:
	if !manager:
		return
		
	var heat_level = manager.current_heat
	var heat_name = manager.get_heat_name()
	
	heat_label.text = heat_name
	heat_progress.modulate = heat_colors[heat_level]
	
	if displayed_heat != heat_level:
		displayed_heat = heat_level
		if heat_level > 0:
			animation_player.play("heat_change")

func _on_heat_changed(new_level, old_level) -> void:
	update_display()
	
	if new_level > old_level:
		animation_player.play("heat_increase")
	else:
		animation_player.play("heat_decrease")

func _on_player_detected(detector_type) -> void:
	animation_player.play("detected")
	
func _on_police_alerted() -> void:
	animation_player.play("police_alerted")

func show_bar() -> void:
	show()
	animation_player.play("fade_in")
	
func hide_bar() -> void:
	animation_player.play("fade_out")
	await animation_player.animation_finished
	hide() 