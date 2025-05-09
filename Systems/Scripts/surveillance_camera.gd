extends Node2D

@export var camera_id: String = "camera_1"
@export var camera_label: String = "Surveillance Camera 1"
@export var initial_zoom: Vector2 = Vector2(1, 1)
@export var restricted_area: bool = false

@onready var camera = $Camera2D
@onready var label = $Label if has_node("Label") else null
@onready var interaction_area = $InteractionArea if has_node("InteractionArea") else null

var surveillance_system = null

func _ready():
    if label:
        label.text = camera_label
    
    if camera:
        camera.zoom = initial_zoom
        camera.enabled = false
    else:
        push_error("Camera2D not found as child of surveillance camera node")
        return
    
    add_to_group("surveillance_camera")
    
    await get_tree().process_frame
    surveillance_system = get_node_or_null("/root/SurveillanceCameraSystem")
    
    if surveillance_system:
        surveillance_system.register_camera(camera, camera_id)
    else:
        push_error("SurveillanceCameraSystem not found. Make sure it's added as an autoload.")
    
    if interaction_area and interaction_area.has_signal("body_entered"):
        interaction_area.body_entered.connect(_on_interaction_area_body_entered)
        interaction_area.body_exited.connect(_on_interaction_area_body_exited)

func _on_interaction_area_body_entered(body):
    if body.is_in_group("player"):
        SignalBus.emit_signal("show_interaction_prompt", "Press E to access camera")

func _on_interaction_area_body_exited(body):
    if body.is_in_group("player"):
        SignalBus.emit_signal("hide_interaction_prompt")

func _unhandled_input(event):
    # Try all forms of the interaction action to ensure compatibility
    if event.is_action_pressed("Interact") or event.is_action_pressed("INTERACT") or event.is_action_pressed("interact"):
        var player = get_tree().get_first_node_in_group("player")
        if player and interaction_area:
            var bodies = interaction_area.get_overlapping_bodies()
            if bodies.has(player):
                activate_camera()

func activate_camera():
    if surveillance_system:
        SignalBus.surveillance_activate_camera.emit(camera_id)

func get_camera_data():
    return {
        "camera_node": camera,
        "camera_id": camera_id,
        "label": camera_label,
        "restricted": restricted_area,
        "position": global_position
    } 