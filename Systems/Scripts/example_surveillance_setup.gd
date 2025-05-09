extends Node2D

var interaction_prompt_label = null

func _ready():
    var player = get_tree().get_first_node_in_group("player")
    if player and player.has_node("Camera2D"):
        var player_camera = player.get_node("Camera2D")
        if SurveillanceCameraSystem:
            SurveillanceCameraSystem.register_player_camera(player_camera)
        else:
            push_error("SurveillanceCameraSystem not found - autoload missing?")
    else:
        push_warning("Player or Camera2D not found - camera system may not work correctly")
    
    add_interaction_prompt_ui()

func add_interaction_prompt_ui():
    var canvas_layer = CanvasLayer.new()
    canvas_layer.name = "InteractionPromptLayer"
    add_child(canvas_layer)
    
    var prompt_label = Label.new()
    prompt_label.name = "InteractionPrompt"
    prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    prompt_label.anchor_top = 0.8
    prompt_label.anchor_right = 1.0
    prompt_label.anchor_bottom = 0.9
    prompt_label.visible = false
    canvas_layer.add_child(prompt_label)
    
    interaction_prompt_label = prompt_label
    
    if SignalBus:
        SignalBus.show_interaction_prompt.connect(_on_show_interaction_prompt.bind(prompt_label))
        SignalBus.hide_interaction_prompt.connect(_on_hide_interaction_prompt.bind(prompt_label))
    else:
        push_error("SignalBus not found - autoload missing?")

func _on_show_interaction_prompt(text: String, label: Label):
    if label:
        label.text = text
        label.visible = true

func _on_hide_interaction_prompt(label: Label):
    if label:
        label.visible = false

func _input(event):
    # Check for multiple possible input mappings
    if (event.is_action_pressed("ui_home") or 
        event.is_action_pressed("Interact") or 
        event.is_action_pressed("INTERACT") or 
        event.is_action_pressed("interact")):
            
        var cameras = get_tree().get_nodes_in_group("surveillance_camera")
        if cameras.size() > 0:
            if SurveillanceCameraSystem and SurveillanceCameraSystem.is_active():
                SurveillanceCameraSystem.deactivate_current_camera()
            elif cameras[0].has_method("activate_camera"):
                cameras[0].activate_camera() 