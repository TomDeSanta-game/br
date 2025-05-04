extends Control
@export var heat_gradient: Gradient
@export var min_heat: float = 0.0
@export var max_heat: float = 100.0
@export var initial_heat: float = 0.0
@export var danger_threshold: float = 70.0
@export var caution_threshold: float = 40.0
@export var low_threshold: float = 10.0
var _current_heat: float = 0.0
var _is_filling_anisprotic: bool = false
var _fill_rate: float = 0.0
var _last_heat_state: String = "normal"
@onready var heat_bar_fill: ProgressBar = $MainContainer/HeatBarOutline/MarginContainer/HeatBarFill
@onready var shader_overlay: ColorRect = $MainContainer/HeatBarOutline/MarginContainer/ShaderOverlay
@onready var value_display: Label = $MainContainer/HeaderContainer/ValueDisplay
@onready var particles_top: CPUParticles2D = $GlowParticlesTop
@onready var particles_bottom: CPUParticles2D = $GlowParticlesBottom
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var cold_indicator: Panel = $MainContainer/StateIndicators/ColdIndicator
@onready var caution_indicator: Panel = $MainContainer/StateIndicators/CautionIndicator
@onready var danger_indicator: Panel = $MainContainer/StateIndicators/DangerIndicator
@onready var heat_progress = $HeatProgress
@onready var heat_label = $HeatLabel
@onready var detection_progress = $DetectionProgress

var heat_bar_colors = {
	"NONE": Color(0.2, 0.8, 0.2, 1.0),    # Green
	"LOW": Color(0.8, 0.8, 0.2, 1.0),     # Yellow
	"MEDIUM": Color(0.9, 0.6, 0.1, 1.0),  # Orange
	"HIGH": Color(0.9, 0.3, 0.1, 1.0),    # Orange-Red
	"WANTED": Color(0.9, 0.1, 0.1, 1.0)   # Red
}

func _ready() -> void:
	modulate.a = 0
	
	# Wait one frame to ensure TensionManager is initialized
	await get_tree().process_frame
	
	if get_node("/root/TensionManager"):
		get_node("/root/TensionManager").heat_level_changed.connect(_on_heat_level_changed)
		get_node("/root/TensionManager").player_detected.connect(_on_player_detected)
		get_node("/root/TensionManager").police_alerted.connect(_on_police_alerted)
		
		show_heat_bar()
		update_heat_display()

func _process(delta: float) -> void:
	if _is_filling_anisprotic:
		var new_heat = _current_heat + (_fill_rate * delta)
		fill(new_heat)
		_current_heat = new_heat
		
		if _current_heat >= max_heat:
			stop_fill_anisprotic()
	
	if get_node_or_null("/root/TensionManager"):
		# Update the heat progress bar based on current tension
		var tension = get_node("/root/TensionManager").tension_engine.get_normalized_tension()
		heat_progress.value = tension
		
		# Update the detection progress based on the detection meter
		detection_progress.value = get_node("/root/TensionManager").detection_meter

func fill(value: float) -> void:
	var clamped_value = clamp(value, min_heat, max_heat)
	_current_heat = clamped_value
	
	heat_bar_fill.value = clamped_value
	
	var normalized_value = clamped_value / max_heat
	if shader_overlay.material:
		shader_overlay.material.set_shader_parameter("progress", normalized_value)
	
	value_display.text = str(int(clamped_value)) + "%"
	
	_update_heat_visual_state(clamped_value)

func _update_heat_visual_state(heat_value: float) -> void:
	cold_indicator.modulate.a = 0.4
	caution_indicator.modulate.a = 0.4
	danger_indicator.modulate.a = 0.4
	
	var current_state = "normal"
	
	if heat_value > danger_threshold:
		current_state = "danger"
		danger_indicator.modulate.a = 1.0
		
		particles_top.emitting = true
		particles_bottom.emitting = true
		
		if not animation_player.is_playing() or _last_heat_state != "danger":
			animation_player.play("high_heat_pulse")
			
		if shader_overlay.material:
			shader_overlay.material.set_shader_parameter("pulse_intensity", 0.2)
			shader_overlay.material.set_shader_parameter("speed", 2.0)
		
	elif heat_value > caution_threshold:
		current_state = "caution"
		caution_indicator.modulate.a = 1.0
		
		particles_top.emitting = false
		particles_bottom.emitting = false
		animation_player.stop()
		
		if shader_overlay.material:
			shader_overlay.material.set_shader_parameter("pulse_intensity", 0.1)
			shader_overlay.material.set_shader_parameter("speed", 1.5)
		
	elif heat_value > low_threshold:
		current_state = "low"
		cold_indicator.modulate.a = 1.0
		
		particles_top.emitting = false
		particles_bottom.emitting = false
		animation_player.stop()
		
		if shader_overlay.material:
			shader_overlay.material.set_shader_parameter("pulse_intensity", 0.05)
			shader_overlay.material.set_shader_parameter("speed", 1.0)
	else:
		particles_top.emitting = false
		particles_bottom.emitting = false
		animation_player.stop()
		
		if shader_overlay.material:
			shader_overlay.material.set_shader_parameter("pulse_intensity", 0.0)
			shader_overlay.material.set_shader_parameter("speed", 0.5)
	
	_last_heat_state = current_state

func fill_anisprotic(rate_per_second: float) -> void:
	_fill_rate = rate_per_second
	_is_filling_anisprotic = true

func stop_fill_anisprotic() -> void:
	_is_filling_anisprotic = false
	_fill_rate = 0.0

func update_heat_display():
	if get_node_or_null("/root/TensionManager"):
		var tension_manager = get_node("/root/TensionManager")
		var heat_level = tension_manager.current_heat_level
		var heat_name = tension_manager.get_heat_level_name()
		
		heat_label.text = heat_name
		heat_progress.modulate = heat_bar_colors[heat_name]
		
		if heat_level >= tension_manager.HEAT_LEVEL.MEDIUM:
			detection_progress.modulate = heat_bar_colors[heat_name]
		else:
			detection_progress.modulate = heat_bar_colors["NONE"]

func _on_heat_level_changed(new_level, old_level):
	update_heat_display()
	
	if new_level > old_level:
		animation_player.play("heat_increase")
	
	var tension_manager = get_node("/root/TensionManager")
	if new_level >= tension_manager.HEAT_LEVEL.HIGH:
		if !animation_player.is_playing() or animation_player.current_animation != "detection_pulse":
			animation_player.play("detection_pulse")

func _on_player_detected(detector_type):
	animation_player.stop()
	animation_player.play("detected")
	await animation_player.animation_finished
	
	var tension_manager = get_node("/root/TensionManager")
	if tension_manager.current_heat_level >= tension_manager.HEAT_LEVEL.HIGH:
		animation_player.play("detection_pulse")

func _on_police_alerted():
	animation_player.stop()
	animation_player.play("detected")
	await animation_player.animation_finished
	
	var tension_manager = get_node("/root/TensionManager")
	if tension_manager.current_heat_level >= tension_manager.HEAT_LEVEL.HIGH:
		animation_player.play("detection_pulse")

func show_heat_bar():
	animation_player.play("fade_in")

func hide_heat_bar():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished 