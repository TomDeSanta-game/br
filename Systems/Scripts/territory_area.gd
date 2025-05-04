extends Area3D

@export var territory_id: String = "default"
@export var is_active: bool = true
@export var debug_color: Color = Color(0.0, 1.0, 0.0, 0.3)

var street_dealing = null
var tension_manager = null
var active_customers = []
var max_customers = 3
var spawn_timer = null
var heat_decay_timer = null

func _ready():
    street_dealing = get_node_or_null("/root/StreetDealing")
    tension_manager = get_node_or_null("/root/TensionManager")
    
    if street_dealing and street_dealing.has_method("register_territory"):
        street_dealing.register_territory(self)
    
    var collision_shape = get_node_or_null("CollisionShape3D")
    if collision_shape and collision_shape.shape:
        var debug_mesh = create_debug_mesh(collision_shape.shape)
        if debug_mesh:
            add_child(debug_mesh)
    
    setup_timers()
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func setup_timers():
    spawn_timer = Timer.new()
    spawn_timer.wait_time = 5.0
    spawn_timer.one_shot = false
    spawn_timer.autostart = true
    spawn_timer.timeout.connect(_on_spawn_timer_timeout)
    add_child(spawn_timer)
    
    heat_decay_timer = Timer.new()
    heat_decay_timer.wait_time = 10.0
    heat_decay_timer.one_shot = false
    heat_decay_timer.autostart = true
    heat_decay_timer.timeout.connect(_on_heat_decay_timer_timeout)
    add_child(heat_decay_timer)

func create_debug_mesh(shape):
    if not OS.is_debug_build() or not shape:
        return null
    
    var mesh_instance = MeshInstance3D.new()
    var material = StandardMaterial3D.new()
    material.transparency = StandardMaterial3D.TRANSPARENCY_ALPHA
    material.albedo_color = debug_color
    
    if shape is BoxShape3D:
        var cube_mesh = BoxMesh.new()
        cube_mesh.size = shape.size
        mesh_instance.mesh = cube_mesh
        mesh_instance.material_override = material
    
    return mesh_instance

func _on_body_entered(body):
    if body.is_in_group("player") and street_dealing:
        street_dealing.player_entered_territory(territory_id)

func _on_body_exited(body):
    if body.is_in_group("player") and street_dealing:
        street_dealing.player_exited_territory(territory_id)

func _on_spawn_timer_timeout():
    if not is_active or not street_dealing:
        return
    
    if active_customers.size() < max_customers and street_dealing.can_spawn_customer():
        street_dealing.spawn_customer_in_territory(territory_id, global_position)

func _on_heat_decay_timer_timeout():
    if not street_dealing or not territory_id or not street_dealing.has_method("decay_territory_heat"):
        return
        
    street_dealing.decay_territory_heat(territory_id)

func add_customer(customer_id):
    if not active_customers.has(customer_id):
        active_customers.append(customer_id)

func remove_customer(customer_id):
    active_customers.erase(customer_id)

func has_capacity_for_customers():
    return active_customers.size() < max_customers

func _exit_tree():
    if street_dealing and street_dealing.has_method("unregister_territory"):
        street_dealing.unregister_territory(self) 