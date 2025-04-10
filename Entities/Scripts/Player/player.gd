extends CharacterBody2D

# Constants
const ANIMATIONS: Dictionary = {
	"DOWN_IDLE": "Down_Idle",
	"RIGHT_IDLE": "Right_Idle",
	"UP_IDLE": "Up_Idle",
	"DOWN_RUN": "Down_Run",
	"RIGHT_RUN": "Right_Run",
	"UP_RUN": "Up_Run"
}

# Variables
var speed: float = 100.0
var can_toggle_inventory: bool = true
var inventory_toggled: bool = false
var direction: Vector2 = Vector2.ZERO
var is_interact_mode = false
var ui_hidden = false
var is_running = false

# References
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var assistant: Node2D = get_tree().get_first_node_in_group("Assistant")
@onready var inventory: Control = $CanvasLayer/InventoryUI
@onready var objective_label: Control = $CanvasLayer/ObjectiveLabel
@onready var objective_text: RichTextLabel = $CanvasLayer/ObjectiveLabel/ContentPanel/ObjectiveText
@onready var heat_bar: Control = $CanvasLayer/HeatBar
@onready var debug_label: Label = $CanvasLayer/DebugLabel
@onready var state_machine: PlayerStateMachine

# Exports
@export var debug_mode: bool = false

func _ready() -> void:
	Grok.register_player(self)
	setup_collision()
	setup_state_machine()
	setup_ui()

func setup_collision() -> void:
	collision_layer = LLM.player_layer
	collision_mask = LLM.world_layer | LLM.enemy_layer | LLM.npc_layer | LLM.assistant_layer | LLM.object_layer

func setup_state_machine() -> void:
	state_machine = PlayerStateMachine.new()
	add_child(state_machine)
	state_machine.init(self)
	state_machine.set_active(true)

func setup_ui() -> void:
	IdManager.add_item("01", inventory)
	$CanvasLayer.visible = true
	heat_bar.visible = true

func _process(_delta: float) -> void:
	check_heat()
	if debug_mode:
		_setup_debug_label()
	debug_label.visible = debug_mode

func _physics_process(_delta: float) -> void:
	handle_movement()

func handle_movement() -> void:
	var input_vector = get_input_vector()
	
	if input_vector != Vector2.ZERO:
		velocity = input_vector * speed
		direction = input_vector
		handle_running(input_vector)
	else:
		velocity = Vector2.ZERO
		direction = Vector2.ZERO
		handle_idle()
		
	if not is_interact_mode:
		move_and_slide()

func get_input_vector() -> Vector2:
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("RIGHT") - Input.get_action_strength("LEFT")
	input_vector.y = Input.get_action_strength("DOWN") - Input.get_action_strength("UP")
	return input_vector.normalized()

func handle_running(_input_vector: Vector2) -> void:
	is_running = true
	SoundManager.set_music_volume(0.05)
	SoundManager.play_music(load("res://assets/SFX/Run/run.wav"))
	heat_bar.fill_anisprotic(5.0)
	state_machine.update(get_process_delta_time())

func handle_idle() -> void:
	is_running = false
	SoundManager.stop_music()
	heat_bar.stop_fill_anisprotic()
	state_machine.update(get_process_delta_time())

func check_heat() -> void:
	if heat_bar._current_heat == heat_bar.max_heat:
		die()

func die() -> void:
	SceneManager.reload_scene()

func _setup_debug_label() -> void:
	var position_text = "Position: (" + str(int(global_position.x)) + ", " + str(int(global_position.y)) + ")"
	var velocity_text = "Velocity: (" + str(int(velocity.x)) + ", " + str(int(velocity.y)) + ")"
	var direction_text = "Direction: (" + str(direction.x) + ", " + str(direction.y) + ")"
	
	debug_label.text = (
		"FPS: " + str(Engine.get_frames_per_second()) + "\n" +
		"Current Heat: " + str(heat_bar._current_heat) + "/" + str(heat_bar.max_heat) + "\n" +
		"Current Objective: " + "\n" +
		position_text + "\n" +
		velocity_text + "\n" +
		direction_text
	)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("INTERACT") and can_toggle_inventory:
		inventory_toggled = !inventory_toggled
		inventory.toggle_inventory()
	elif event.is_action_released("reload_scene"):
		die()
	elif event.is_action_released("DEBUG"):
		debug_mode = !debug_mode
	elif event.is_action_released("HUI"):
		hide_ui(true)

func show_objective(text: String, duration: float = 5.0) -> void:
	objective_text.text = text
	
	var animation_player = objective_label.get_node("AnimationPlayer")
	animation_player.stop()
	animation_player.play("appear")
	
	var pulse_player = objective_label.get_node("PulseAnimationPlayer")
	pulse_player.stop()
	pulse_player.play("pulse")
	
	if duration > 0:
		await get_tree().create_timer(duration).timeout
		hide_objective()
		
func hide_objective() -> void:
	var animation_player = objective_label.get_node("AnimationPlayer")
	animation_player.stop()
	animation_player.play("disappear")
	
	var pulse_player = objective_label.get_node("PulseAnimationPlayer")
	pulse_player.stop()

func show_styled_objective(title: String, content: String, duration: float = 5.0) -> void:
	var bbcode_text = "[color=#ffdd44]" + title + "[/color]\n" + content
	show_objective(bbcode_text, duration)
	
func complete_objective(hide_after: float = 3.0) -> void:
	var pulse_player = objective_label.get_node("PulseAnimationPlayer")
	pulse_player.stop()
	
	var animation_player = objective_label.get_node("AnimationPlayer")
	animation_player.stop()
	animation_player.play("complete")

	$CanvasLayer/ObjectiveLabel/IconContainer/Icon.text = "✓"
	$CanvasLayer/ObjectiveLabel/TitleLabel.text = "OBJECTIVE COMPLETED"
	
	if hide_after > 0:
		await get_tree().create_timer(hide_after).timeout
		hide_objective()
		$CanvasLayer/ObjectiveLabel/IconContainer/Icon.text = "!"
		$CanvasLayer/ObjectiveLabel/TitleLabel.text = "OBJECTIVE TO COMPLETE"

func hide_ui(boolean: bool) -> void:
	ui_hidden = boolean
	if boolean:
		objective_label.hide()
		objective_text.hide()
		heat_bar.hide()
		debug_label.hide()
		if inventory.visible:
			inventory.hide()
	else:
		objective_label.show()
		objective_text.show()
		heat_bar.show()
		if debug_mode:
			debug_label.show()

func is_player_running() -> bool:
	return is_running

func update_animation(input_vector: Vector2) -> void:
	direction = input_vector
	handle_running(input_vector)

func update_idle_animation() -> void:
	direction = Vector2.ZERO
	handle_idle()