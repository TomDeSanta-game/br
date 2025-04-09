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

func _ready() -> void:
	cold_indicator.modulate.a = 0.4
	caution_indicator.modulate.a = 0.4
	danger_indicator.modulate.a = 0.4
	
	fill(initial_heat)
	_current_heat = initial_heat

func _process(delta: float) -> void:
	if _is_filling_anisprotic:
		var new_heat = _current_heat + (_fill_rate * delta)
		fill(new_heat)
		_current_heat = new_heat
		
		if _current_heat >= max_heat:
			stop_fill_anisprotic()

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