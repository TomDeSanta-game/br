extends Node

signal deal_started(customer_data)
signal deal_completed(deal_data)
signal deal_failed(reason)
signal territory_status_changed(territory_name, status)

@export_category("Dealing Settings")
@export var enable_dealing: bool = true
@export var base_deal_time: float = 60.0
@export var max_customers_per_area: int = 5
@export var customer_spawn_frequency: float = 120.0
@export var price_fluctuation: float = 0.2

@export_category("Risk Settings")
@export var base_heat_per_deal: float = 0.1
@export var suspicion_threshold: float = 0.7
@export var territory_heat_multiplier: float = 0.5
@export var quality_risk_multiplier: float = 0.8

@export_category("Product Settings")
@export_enum("Low", "Medium", "High", "Very High") var methamphetamine_quality: int = 1
@export var methamphetamine_purity: float = 0.8
@export var meth_base_price: float = 1000.0
@export var meth_max_amount: float = 20.0
@export var current_meth_quantity: float = 0.0

@export_category("Territories")
@export var territories: Dictionary = {
    "suburbs": {
        "risk": 0.2,
        "price_modifier": 0.8,
        "customer_types": ["casual", "student"],
        "police_presence": 0.4,
    },
    "downtown": {
        "risk": 0.5,
        "price_modifier": 1.0,
        "customer_types": ["casual", "addict", "dealer"],
        "police_presence": 0.6,
    },
    "industrial": {
        "risk": 0.7,
        "price_modifier": 1.2,
        "customer_types": ["addict", "dealer", "gang"],
        "police_presence": 0.3,
    },
    "cartel_territory": {
        "risk": 0.9,
        "price_modifier": 1.5,
        "customer_types": ["dealer", "gang"],
        "police_presence": 0.1,
    }
}

var player = null
var signal_bus = null
var tension_manager = null
var police_response = null
var active_customers = {}
var active_territory = ""
var current_reputation = {
    "suburbs": 0.0,
    "downtown": 0.0,
    "industrial": 0.0,
    "cartel_territory": 0.0
}
var territory_heat = {
    "suburbs": 0.0,
    "downtown": 0.0,
    "industrial": 0.0,
    "cartel_territory": 0.0
}
var customer_timer = 0.0
var current_deal = null
var meth_price_modifier = 1.0
var dealing_allowed = true

var customer_types = {
    "casual": {
        "price_sensitivity": 0.7,
        "quantity_range": [0.1, 0.5],
        "risk": 0.2,
        "negotiation_difficulty": 0.3,
        "patience": 0.6
    },
    "student": {
        "price_sensitivity": 0.9,
        "quantity_range": [0.2, 0.7],
        "risk": 0.3,
        "negotiation_difficulty": 0.4,
        "patience": 0.5
    },
    "addict": {
        "price_sensitivity": 0.4,
        "quantity_range": [0.3, 1.0],
        "risk": 0.5,
        "negotiation_difficulty": 0.5,
        "patience": 0.3
    },
    "dealer": {
        "price_sensitivity": 0.6,
        "quantity_range": [1.0, 5.0],
        "risk": 0.7,
        "negotiation_difficulty": 0.7,
        "patience": 0.4
    },
    "gang": {
        "price_sensitivity": 0.3,
        "quantity_range": [3.0, 10.0],
        "risk": 0.9,
        "negotiation_difficulty": 0.9,
        "patience": 0.2
    }
}

var dialog_options = {
    "greeting": [
        "Hey, heard you might have something I need.",
        "Someone told me to talk to you.",
        "You holding?",
        "Got any crystal?",
        "Need to score, you got the good stuff?"
    ],
    "negotiation": [
        "That's way too steep for me.",
        "Can you do any better on the price?",
        "I was thinking something more like {price}.",
        "Come on, I'm a regular. Hook me up.",
        "That's not what I heard it was going for."
    ],
    "accept": [
        "Alright, deal.",
        "I'll take it.",
        "Sounds fair enough.",
        "That works for me.",
        "Fine, let's do this quick."
    ],
    "reject": [
        "Forget it, that's too much.",
        "Nah, I'll find someone else.",
        "You're trying to rip me off.",
        "I'm out of here.",
        "Not worth it."
    ],
    "police": [
        "Hey, I think I saw a cop over there.",
        "We need to be careful, police are patrolling today.",
        "Let's keep this quick, I don't like the look of that car.",
        "Cops have been busting people around here lately."
    ]
}

var player_responses = {
    "greeting": [
        "What are you looking for?",
        "I might have what you need.",
        "Depends what you want.",
        "Yeah, I got product. What's your price range?",
        "Keep it down. What do you need?"
    ],
    "negotiation": [
        "This is high quality stuff, worth every penny.",
        "I can do {price}, but that's my final offer.",
        "The price is the price, take it or leave it.",
        "I might be able to work something out.",
        "I have expenses too, you know."
    ],
    "deal_complete": [
        "Pleasure doing business.",
        "Stay safe.",
        "Don't use it all at once.",
        "Come find me if you need more.",
        "Don't tell anyone where you got it."
    ],
    "deal_reject": [
        "Your loss.",
        "I'm not desperate to sell.",
        "Find someone else then.",
        "No skin off my back.",
        "Whatever, I've got other customers."
    ],
    "sketch": [
        "Let's move somewhere less visible.",
        "You a cop? You seem sketchy.",
        "I don't like this. Let's postpone.",
        "Hold up, something doesn't feel right.",
        "We should bail, this feels off."
    ]
}

func _ready():
    signal_bus = get_node_or_null("/root/SignalBus")
    tension_manager = get_node_or_null("/root/TensionManager")
    police_response = get_node_or_null("/root/PoliceResponse")
    
    if signal_bus:
        signal_bus.game_event.connect(_on_game_event)
    
    await get_tree().process_frame
    player = get_tree().get_nodes_in_group("player").front()
    
    update_price_modifiers()
    current_meth_quantity = 5.0

func _process(delta):
    if !enable_dealing || !player:
        return
    
    update_customer_spawn(delta)
    update_territory_heat(delta)
    check_player_territory()

func update_customer_spawn(delta):
    if !active_territory || !territories.has(active_territory):
        return
    
    customer_timer -= delta
    
    if customer_timer <= 0 && active_customers.size() < max_customers_per_area:
        customer_timer = customer_spawn_frequency * (1.0 + randf_range(-0.3, 0.3))
        
        var rep_bonus = current_reputation[active_territory] * 0.5
        if randf() < 0.3 + rep_bonus:
            spawn_customer()

func update_territory_heat(delta):
    for territory in territories.keys():
        if territory_heat[territory] > 0:
            var decay_rate = 0.01 * (1.0 - territories[territory].police_presence)
            territory_heat[territory] = max(0.0, territory_heat[territory] - decay_rate * delta)

func check_player_territory():
    if !player:
        active_territory = ""
        return
    
    var player_pos = player.global_position
    var found_territory = false
    
    for territory in territories.keys():
        if area_contains_point(territory, player_pos):
            if active_territory != territory:
                active_territory = territory
                found_territory = true
                if signal_bus:
                    signal_bus.emit_signal("game_event", "territory_entered", {"territory": territory})
            break
    
    if !found_territory:
        active_territory = ""

func area_contains_point(territory_name, point):
    return false

func set_active_territory(territory_name: String):
    if territory_name == active_territory:
        return
    
    var old_territory = active_territory
    active_territory = territory_name
    
    if signal_bus:
        signal_bus.emit_signal("territory_status_changed", territory_name, old_territory)
    
    if territories.has(active_territory):
        update_price_modifiers()

func spawn_customer():
    if !active_territory || !territories.has(active_territory):
        return
    
    var available_types = territories[active_territory].customer_types
    if available_types.size() == 0:
        return
    
    var customer_type = available_types[randi() % available_types.size()]
    var customer_data = generate_customer(customer_type)
    
    var customer_id = Time.get_unix_time_from_system() + randf()
    active_customers[customer_id] = customer_data
    
    if signal_bus:
        signal_bus.emit_signal("game_event", "customer_appeared", {"customer_id": customer_id, "customer": customer_data})
    
    return customer_id

func generate_customer(type):
    if !customer_types.has(type):
        type = "casual"
    
    var base = customer_types[type]
    
    var customer = {
        "type": type,
        "price_sensitivity": base.price_sensitivity * randf_range(0.8, 1.2),
        "quantity_wanted": randf_range(base.quantity_range[0], base.quantity_range[1]),
        "risk": base.risk * randf_range(0.8, 1.2),
        "negotiation_difficulty": base.negotiation_difficulty * randf_range(0.8, 1.2),
        "patience": base.patience * randf_range(0.8, 1.2),
        "max_price": get_meth_price() * randf_range(0.7 / base.price_sensitivity, 1.2 / base.price_sensitivity),
        "min_price": get_meth_price() * randf_range(0.5, 0.8),
        "patience_timer": base_deal_time * base.patience,
        "greeting": dialog_options.greeting[randi() % dialog_options.greeting.size()],
        "suspicion": randf_range(0.1, 0.4) * base.risk,
        "offer_count": 0,
        "is_undercover": randf() < 0.05 * base.risk
    }
    
    customer.quantity_wanted = min(customer.quantity_wanted, current_meth_quantity)
    
    return customer

func start_deal(customer_id):
    if !active_customers.has(customer_id) || current_deal != null:
        return false
    
    current_deal = {
        "customer_id": customer_id,
        "customer": active_customers[customer_id],
        "stage": "greeting",
        "offered_price": 0,
        "offered_quantity": 0,
        "suspicion": active_customers[customer_id].suspicion,
        "territory": active_territory
    }
    
    if signal_bus:
        signal_bus.emit_signal("deal_started", current_deal)
    
    return true

func offer_deal(price_per_gram, quantity):
    if current_deal == null:
        return false
    
    var customer = current_deal.customer
    current_deal.offered_price = price_per_gram
    current_deal.offered_quantity = quantity
    current_deal.stage = "negotiation"
    
    var fair_price = get_meth_price()
    var price_ratio = price_per_gram / fair_price
    
    var acceptance_chance = 1.0 - (price_ratio * customer.price_sensitivity)
    
    acceptance_chance += methamphetamine_quality * 0.1
    acceptance_chance += methamphetamine_purity * 0.2
    
    if active_territory && current_reputation.has(active_territory):
        acceptance_chance += current_reputation[active_territory] * 0.2
    
    acceptance_chance -= customer.negotiation_difficulty * 0.3
    
    customer.offer_count += 1
    acceptance_chance -= customer.offer_count * 0.1
    
    current_deal.suspicion += 0.05 + randf_range(0, 0.1) * territories[active_territory].risk
    
    if acceptance_chance > randf():
        return complete_deal()
    elif current_deal.suspicion >= suspicion_threshold:
        return fail_deal("suspicion")
    else:
        var counter_price = fair_price * randf_range(0.7, 0.9) / customer.price_sensitivity
        current_deal.counter_price = counter_price
        
        if signal_bus:
            signal_bus.emit_signal("game_event", "counter_offer", {
                "price": counter_price,
                "customer": customer
            })
        
        return false

func complete_deal():
    if current_deal == null:
        return false
    
    var deal_data = {
        "customer": current_deal.customer,
        "price": current_deal.offered_price,
        "quantity": current_deal.offered_quantity,
        "total_value": current_deal.offered_price * current_deal.offered_quantity,
        "territory": current_deal.territory
    }
    
    current_meth_quantity -= current_deal.offered_quantity
    
    var deal_heat = base_heat_per_deal
    deal_heat *= 1.0 + (current_deal.offered_quantity / meth_max_amount) * 3.0
    deal_heat *= 1.0 + methamphetamine_quality * quality_risk_multiplier
    deal_heat *= 1.0 + territories[active_territory].risk * territory_heat_multiplier
    
    if territory_heat.has(active_territory):
        territory_heat[active_territory] += deal_heat
    
    if current_reputation.has(active_territory):
        current_reputation[active_territory] = min(1.0, current_reputation[active_territory] + 0.02)
    
    if tension_manager && deal_heat > 0.2:
        tension_manager.add_tension(deal_heat * 0.5)
    
    if police_response && randf() < deal_heat * territories[active_territory].police_presence:
        police_response.add_crime_points(deal_heat, player.global_position)
    
    active_customers.erase(current_deal.customer_id)
    
    if signal_bus:
        signal_bus.emit_signal("deal_completed", deal_data)
    
    current_deal = null
    
    return true

func fail_deal(reason):
    if current_deal == null:
        return false
    
    var fail_data = {
        "customer": current_deal.customer,
        "territory": current_deal.territory,
        "reason": reason,
        "suspicion": current_deal.suspicion
    }
    
    if current_deal.customer.is_undercover:
        if police_response:
            police_response.add_crime_points(1.5, player.global_position)
        
        if tension_manager:
            tension_manager.add_tension(0.5)
    
    if current_reputation.has(active_territory):
        current_reputation[active_territory] = max(0.0, current_reputation[active_territory] - 0.05)
    
    active_customers.erase(current_deal.customer_id)
    
    if signal_bus:
        signal_bus.emit_signal("deal_failed", fail_data)
    
    current_deal = null
    
    return true

func cancel_deal():
    if current_deal == null:
        return false
    
    var fail_data = {
        "customer": current_deal.customer,
        "territory": current_deal.territory,
        "reason": "player_cancelled",
        "suspicion": current_deal.suspicion
    }
    
    if current_reputation.has(active_territory):
        current_reputation[active_territory] = max(0.0, current_reputation[active_territory] - 0.02)
    
    active_customers.erase(current_deal.customer_id)
    
    if signal_bus:
        signal_bus.emit_signal("deal_failed", fail_data)
    
    current_deal = null
    
    return true

func get_meth_price():
    var base_price = meth_base_price
    
    base_price *= 1.0 + (methamphetamine_quality * 0.2)
    base_price *= 1.0 + ((methamphetamine_purity - 0.5) * 2.0)
    
    if active_territory && territories.has(active_territory):
        base_price *= territories[active_territory].price_modifier
    
    base_price *= meth_price_modifier
    
    return base_price

func update_price_modifiers():
    meth_price_modifier = 1.0 + randf_range(-price_fluctuation, price_fluctuation)

func set_product_quality(quality, purity):
    methamphetamine_quality = clamp(quality, 0, 3)
    methamphetamine_purity = clamp(purity, 0.1, 1.0)

func get_territory_risk(territory_name):
    if territories.has(territory_name):
        var base_risk = territories[territory_name].risk
        var heat_factor = territory_heat[territory_name]
        
        return base_risk * (1.0 + heat_factor)
    
    return 0.0

func add_product(amount):
    current_meth_quantity = min(current_meth_quantity + amount, meth_max_amount)

func _on_game_event(event_name, data):
    match event_name:
        "meth_cooked":
            if data.has("amount") && data.has("quality") && data.has("purity"):
                add_product(data.amount)
                set_product_quality(data.quality, data.purity)
        "police_raid":
            if current_deal:
                cancel_deal()
            active_customers.clear()
            dealing_allowed = false
        "police_left":
            dealing_allowed = true

func reset():
    active_customers.clear()
    current_deal = null
    
    for territory in current_reputation.keys():
        current_reputation[territory] = 0.0
    
    for territory in territory_heat.keys():
        territory_heat[territory] = 0.0 