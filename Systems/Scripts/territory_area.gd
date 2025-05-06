extends Area2D
@export var territory_id: String = ""
@export var territory_name: String = "Unknown Territory"
@export_range(0, 1.0) var base_risk: float = 0.2
@export_range(0, 2.0) var price_modifier: float = 1.0
@export var limit_customer_types: bool = false
@export var allowed_customer_types: Array[String] = []
@export_range(0, 1.0) var police_presence: float = 0.2
@export var active: bool = true
var player_inside: bool = false
var street_dealing = null
var tension_manager = null
var signal_bus = null
var active_customers = []
var max_customers = 3
var spawn_timer = null
var heat_decay_timer = null
func _ready():
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)
    street_dealing = get_node_or_null("/root/StreetDealing")
    tension_manager = get_node_or_null("/root/TensionManager")
    signal_bus = get_node_or_null("/root/SignalBus")
    await get_tree().process_frame
    if street_dealing && territory_id != "":
        street_dealing.register_territory(self)
    var collision_shape = get_node_or_null("CollisionShape3D")
    if collision_shape and collision_shape.shape:
        var debug_mesh = create_debug_mesh(collision_shape.shape)
        if debug_mesh:
            add_child(debug_mesh)
    setup_timers()
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
    material.albedo_color = Color(0.0, 1.0, 0.0, 0.3)
    if shape is BoxShape3D:
        var cube_mesh = BoxMesh.new()
        cube_mesh.size = shape.size
        mesh_instance.mesh = cube_mesh
        mesh_instance.material_override = material
    return mesh_instance
func _on_body_entered(body):
    if body.is_in_group("player"):
        player_inside = true
        if street_dealing:
            street_dealing.set_current_territory(territory_id)
        if signal_bus:
            signal_bus.emit_signal("territory_entered", territory_id, territory_name)
        if tension_manager && police_presence > 0:
            tension_manager.police_presence_level = police_presence
func _on_body_exited(body):
    if body.is_in_group("player"):
        player_inside = false
        if street_dealing:
            street_dealing.set_current_territory("")
        if signal_bus:
            signal_bus.emit_signal("territory_exited", territory_id)
        if tension_manager:
            tension_manager.police_presence_level = 0.0
func is_player_inside() -> bool:
    return player_inside
func get_territory_data() -> Dictionary:
    return {
        "id": territory_id,
        "name": territory_name,
        "base_risk": base_risk,
        "price_modifier": price_modifier,
        "limit_customer_types": limit_customer_types,
        "allowed_customer_types": allowed_customer_types,
        "police_presence": police_presence,
        "active": active
    }
func _on_spawn_timer_timeout():
    if not active or not street_dealing:
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