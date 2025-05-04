extends CharacterBody2D

signal deal_started
signal deal_canceled
signal customer_left

@export_category("Movement")
@export var walk_speed: float = 70.0
@export var run_speed: float = 120.0
@export var acceleration: float = 300.0
@export var wander_distance: float = 100.0
@export var wander_pause_time: float = 3.0

@export_category("Appearance")
@export var customer_sprites: Array[Texture2D]
@export var colors: Array[Color] = [
    Color(1, 1, 1),
    Color(0.9, 0.9, 0.9),
    Color(0.8, 0.8, 0.8),
    Color(0.7, 0.7, 0.7)
]

@onready var sprite = $Sprite2D if has_node("Sprite2D") else null
@onready var animation_player = $AnimationPlayer if has_node("AnimationPlayer") else null
@onready var dialogue_label = $DialogueLabel if has_node("DialogueLabel") else null
@onready var detection_area = $DetectionArea if has_node("DetectionArea") else null
@onready var navigation_agent = $NavigationAgent2D if has_node("NavigationAgent2D") else null
@onready var timer = $Timer if has_node("Timer") else null

enum STATE {SPAWN, APPROACH, WANDER, INTERESTED, DEALING, LEAVING, FLEE}

var street_dealing = null
var customer_id = ""
var customer_data = {}
var current_state = STATE.SPAWN
var target_position = Vector2.ZERO
var wander_timer = 0.0
var player = null
var spawn_position = Vector2.ZERO
var deal_position = Vector2.ZERO
var patience_timer = 0.0
var dialogue_displayed = false
var signal_bus = null

func _ready():
    street_dealing = get_node_or_null("/root/StreetDealing")
    signal_bus = get_node_or_null("/root/SignalBus")
    
    if sprite && customer_sprites.size() > 0:
        sprite.texture = customer_sprites[randi() % customer_sprites.size()]
        if colors.size() > 0:
            sprite.modulate = colors[randi() % colors.size()]
    
    if !timer:
        timer = Timer.new()
        add_child(timer)
    timer.one_shot = true
    
    spawn_position = global_position
    
    if detection_area:
        detection_area.body_entered.connect(_on_detection_area_body_entered)
        detection_area.body_exited.connect(_on_detection_area_body_exited)
    
    await get_tree().process_frame
    player = get_tree().get_nodes_in_group("player").front()
    
    set_state(STATE.WANDER)

func initialize(id: String, data: Dictionary):
    customer_id = id
    customer_data = data
    
    if data.has("patience_timer"):
        patience_timer = data.patience_timer
    
    if dialogue_label && data.has("greeting"):
        dialogue_label.text = data.greeting
        dialogue_label.visible = false

func _process(delta):
    if current_state == STATE.INTERESTED || current_state == STATE.DEALING:
        patience_timer -= delta
        if patience_timer <= 0:
            set_state(STATE.LEAVING)
    
    if current_state == STATE.WANDER:
        wander_timer -= delta
        if wander_timer <= 0:
            set_new_wander_target()
    
    if dialogue_label:
        if current_state == STATE.INTERESTED && !dialogue_displayed:
            dialogue_label.visible = true
            dialogue_displayed = true
        elif current_state != STATE.INTERESTED && dialogue_displayed:
            dialogue_label.visible = false
            dialogue_displayed = false

func _physics_process(delta):
    match current_state:
        STATE.APPROACH:
            approach_player(delta)
        STATE.WANDER:
            wander(delta)
        STATE.INTERESTED:
            face_player()
            velocity = velocity.lerp(Vector2.ZERO, delta * 3.0)
        STATE.DEALING:
            face_player()
            velocity = Vector2.ZERO
        STATE.LEAVING:
            leave(delta)
        STATE.FLEE:
            flee(delta)
    
    move_and_slide()
    update_animation()

func set_state(new_state):
    if current_state == new_state:
        return
    
    var old_state = current_state
    current_state = new_state
    
    match current_state:
        STATE.SPAWN:
            if animation_player:
                animation_player.play("spawn")
            timer.start(1.0)
            await timer.timeout
            set_state(STATE.WANDER)
        
        STATE.APPROACH:
            if player:
                set_target_position(player.global_position)
        
        STATE.WANDER:
            set_new_wander_target()
        
        STATE.INTERESTED:
            if player:
                deal_position = global_position
                emit_signal("deal_started")
                
                patience_timer = customer_data.get("patience_timer", 10.0)
        
        STATE.DEALING:
            if animation_player:
                animation_player.play("idle")
            
            if dialogue_label:
                dialogue_label.visible = false
                dialogue_displayed = false
        
        STATE.LEAVING:
            if old_state == STATE.DEALING || old_state == STATE.INTERESTED:
                emit_signal("deal_canceled")
            
            set_target_position(spawn_position)
            
            if dialogue_label:
                dialogue_label.visible = false
                dialogue_displayed = false
        
        STATE.FLEE:
            if player:
                var flee_dir = global_position - player.global_position
                var flee_target = global_position + flee_dir.normalized() * 500.0
                set_target_position(flee_target)
            
            if dialogue_label:
                dialogue_label.visible = false
                dialogue_displayed = false

func set_target_position(pos):
    target_position = pos
    if navigation_agent:
        navigation_agent.target_position = pos

func approach_player(delta):
    if !player:
        set_state(STATE.WANDER)
        return
    
    var direction
    var distance = global_position.distance_to(player.global_position)
    
    if distance < 60:
        set_state(STATE.INTERESTED)
        return
    
    if navigation_agent:
        if navigation_agent.is_navigation_finished():
            set_state(STATE.INTERESTED)
            return
            
        direction = global_position.direction_to(navigation_agent.get_next_path_position())
    else:
        direction = global_position.direction_to(player.global_position)
    
    var target_velocity = direction * walk_speed
    velocity = velocity.lerp(target_velocity, delta * acceleration / walk_speed)

func wander(delta):
    if !target_position:
        set_new_wander_target()
        return
    
    var direction
    var distance = global_position.distance_to(target_position)
    
    if distance < 20:
        velocity = velocity.lerp(Vector2.ZERO, delta * 3.0)
        if wander_timer <= 0:
            wander_timer = wander_pause_time
        return
    
    if navigation_agent:
        if navigation_agent.is_navigation_finished():
            wander_timer = wander_pause_time
            return
            
        direction = global_position.direction_to(navigation_agent.get_next_path_position())
    else:
        direction = global_position.direction_to(target_position)
    
    var target_velocity = direction * walk_speed * 0.7
    velocity = velocity.lerp(target_velocity, delta * acceleration / walk_speed)

func leave(delta):
    if !target_position:
        set_target_position(spawn_position)
    
    var direction
    var distance = global_position.distance_to(target_position)
    
    if distance < 20:
        emit_signal("customer_left")
        queue_free()
        return
    
    if navigation_agent:
        if navigation_agent.is_navigation_finished():
            emit_signal("customer_left")
            queue_free()
            return
            
        direction = global_position.direction_to(navigation_agent.get_next_path_position())
    else:
        direction = global_position.direction_to(target_position)
    
    var target_velocity = direction * walk_speed
    velocity = velocity.lerp(target_velocity, delta * acceleration / walk_speed)

func flee(delta):
    if !target_position:
        if player:
            var flee_dir = global_position - player.global_position
            var flee_target = global_position + flee_dir.normalized() * 500.0
            set_target_position(flee_target)
        else:
            set_target_position(spawn_position + Vector2(randf_range(-300, 300), randf_range(-300, 300)))
    
    var direction
    var distance = global_position.distance_to(target_position)
    
    if distance < 30:
        emit_signal("customer_left")
        queue_free()
        return
    
    if navigation_agent:
        if navigation_agent.is_navigation_finished():
            emit_signal("customer_left")
            queue_free()
            return
            
        direction = global_position.direction_to(navigation_agent.get_next_path_position())
    else:
        direction = global_position.direction_to(target_position)
    
    var target_velocity = direction * run_speed
    velocity = velocity.lerp(target_velocity, delta * acceleration / run_speed)

func set_new_wander_target():
    var angle = randf() * TAU
    var distance = randf_range(wander_distance * 0.5, wander_distance)
    var target = spawn_position + Vector2(cos(angle), sin(angle)) * distance
    
    set_target_position(target)
    wander_timer = wander_pause_time + randf_range(-1.0, 1.0)

func update_animation():
    if !animation_player:
        return
    
    var speed = velocity.length()
    
    if speed > walk_speed * 0.8:
        if current_state == STATE.FLEE && animation_player.has_animation("run"):
            animation_player.play("run")
        elif animation_player.has_animation("walk"):
            animation_player.play("walk")
    else:
        if animation_player.has_animation("idle"):
            animation_player.play("idle")
    
    if sprite && velocity.x != 0:
        sprite.flip_h = velocity.x < 0

func face_player():
    if !player || !sprite:
        return
    
    sprite.flip_h = global_position.x > player.global_position.x

func show_dialogue(text):
    if dialogue_label:
        dialogue_label.text = text
        dialogue_label.visible = true
        dialogue_displayed = true

func hide_dialogue():
    if dialogue_label:
        dialogue_label.visible = false
        dialogue_displayed = false

func start_deal():
    if current_state == STATE.INTERESTED:
        set_state(STATE.DEALING)
        return true
    return false

func end_deal(success: bool):
    if current_state == STATE.DEALING:
        if success:
            hide_dialogue()
            set_state(STATE.LEAVING)
        else:
            set_state(STATE.FLEE)
        return true
    return false

func _on_detection_area_body_entered(body):
    if body.is_in_group("player") && current_state == STATE.WANDER:
        player = body
        set_state(STATE.APPROACH)

func _on_detection_area_body_exited(body):
    if body.is_in_group("player") && (current_state == STATE.INTERESTED || current_state == STATE.APPROACH):
        set_state(STATE.WANDER)

func _on_police_alert():
    set_state(STATE.FLEE)

func _on_player_detected():
    if customer_data.has("is_undercover") && customer_data.is_undercover:
        if current_state != STATE.FLEE:
            set_state(STATE.LEAVING) 