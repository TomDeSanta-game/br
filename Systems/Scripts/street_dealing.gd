extends Node
enum PRODUCT_TYPE { BLUE, WHITE, SPECIAL }
enum CUSTOMER_TYPE { CASUAL, REGULAR, DEALER, JUNKIE, UNDERCOVER }
@export var enable_dealing: bool = true
@export var base_deal_time: float = 15.0
@export var max_customers_per_area: int = 3
@export var customer_spawn_frequency: float = 30.0
@export var territory_heat_decay: float = 0.01
@export var territory_reputation_decay: float = 0.005
var territories = {}
var current_territory = ""
var active_customers = {}
var active_deals = {}
var player_products = {}
var player_cash = 0.0
var player_reputation = 0.0
var territory_heat = {}
var territory_reputation = {}
var dealing_enabled = true
var signal_bus = null
var tension_manager = null
var customer_types = {
	CUSTOMER_TYPE.CASUAL: {
		"name": "casual",
		"price_sensitivity": 0.7,
		"quality_sensitivity": 0.5,
		"patience": 10.0,
		"risk": 0.2,
		"purchase_amount": [0.5, 1.5],
		"weight": 60
	},
	CUSTOMER_TYPE.REGULAR: {
		"name": "regular",
		"price_sensitivity": 0.5,
		"quality_sensitivity": 0.7,
		"patience": 15.0,
		"risk": 0.1,
		"purchase_amount": [1.0, 3.0],
		"weight": 25
	},
	CUSTOMER_TYPE.DEALER: {
		"name": "dealer",
		"price_sensitivity": 0.9,
		"quality_sensitivity": 0.8,
		"patience": 20.0,
		"risk": 0.15,
		"purchase_amount": [5.0, 10.0],
		"weight": 10
	},
	CUSTOMER_TYPE.JUNKIE: {
		"name": "junkie",
		"price_sensitivity": 0.3,
		"quality_sensitivity": 0.2,
		"patience": 5.0,
		"risk": 0.4,
		"purchase_amount": [0.25, 1.0],
		"weight": 20
	},
	CUSTOMER_TYPE.UNDERCOVER: {
		"name": "buyer",
		"price_sensitivity": 0.6,
		"quality_sensitivity": 0.6,
		"patience": 25.0,
		"risk": 0.8,
		"purchase_amount": [1.0, 2.0],
		"weight": 0,
		"is_undercover": true
	}
}
var dialog_options = {
	"greeting": [
		{"text": "Got any blue?", "product_type": "blue"},
		{"text": "Looking for white...", "product_type": "white"},
		{"text": "Got something special?", "product_type": "special"},
		{"text": "Never mind", "action": "leave"}
	]
}
var customer_responses = {
	"accept": [
		"Yeah, that works for me.",
		"Deal.",
		"That's what I'm talking about!",
		"Let's do it."
	],
	"reject": [
		"No way, that's too much.",
		"You think I'm stupid?",
		"I'll find someone else.",
		"Forget about it."
	],
	"negotiate": [
		"Can you do any better?",
		"That's steep... how about less?",
		"I was thinking something lower.",
		"That's not what I had in mind."
	]
}
var product_data = {
	"blue": {
		"name": "Blue Crystal",
		"base_price": 100,
		"quality": 1.0,
		"amount": 1.0,
		"heat_modifier": 1.5
	},
	"white": {
		"name": "White Crystal",
		"base_price": 80,
		"quality": 0.8,
		"amount": 1.0,
		"heat_modifier": 1.0
	},
	"special": {
		"name": "Special Batch",
		"base_price": 120,
		"quality": 0.9,
		"amount": 0.7,
		"heat_modifier": 2.0
	}
}
func _ready():
	signal_bus = get_node_or_null("/root/SignalBus")
	tension_manager = get_node_or_null("/root/TensionManager")
	player_products = {
		"blue": {"quantity": 10.0, "quality": 0.95},
		"white": {"quantity": 15.0, "quality": 0.7},
		"special": {"quantity": 5.0, "quality": 0.9}
	}
	player_cash = 500.0
func _process(delta):
	if !enable_dealing:
		return
	if tension_manager && tension_manager.tension_engine && tension_manager.tension_engine.get_level() >= tension_manager.tension_engine.LEVEL.HIGH:
		dealing_enabled = false
	else:
		dealing_enabled = true
	update_territory_heat(delta)
func update_territory_heat(delta):
	for territory_id in territory_heat:
		if territory_heat[territory_id] > 0:
			territory_heat[territory_id] = max(0, territory_heat[territory_id] - territory_heat_decay * delta)
			if signal_bus && territory_heat[territory_id] <= 0.1:
				signal_bus.emit_signal("territory_cooled_down", territory_id)
func get_current_territory_data():
	if current_territory == "" || !territories.has(current_territory):
		return null
	return territories[current_territory].get_territory_data()
func is_dealing_allowed() -> bool:
	if !enable_dealing || !dealing_enabled:
		return false
	var territory_data = get_current_territory_data()
	if !territory_data || !territory_data.active:
		return false
	return true
func is_in_territory() -> bool:
	return current_territory != "" && territories.has(current_territory)
func register_territory(territory_node):
	var territory_id = territory_node.territory_id
	if territory_id == "":
		return
	territories[territory_id] = territory_node
	if !territory_heat.has(territory_id):
		territory_heat[territory_id] = 0.0
	if !territory_reputation.has(territory_id):
		territory_reputation[territory_id] = 0.5
func set_current_territory(territory_id):
	current_territory = territory_id
func generate_customer(territory_id = ""):
	if !dealing_enabled:
		return null
	var territory = null
	if territory_id == "":
		if current_territory != "" && territories.has(current_territory):
			territory_id = current_territory
			territory = territories[current_territory]
		else:
			return null
	elif territories.has(territory_id):
		territory = territories[territory_id]
	else:
		return null
	var territory_data = territory.get_territory_data()
	if !territory_data.active:
		return null
	var customer_id = "customer_" + str(randi())
	while active_customers.has(customer_id):
		customer_id = "customer_" + str(randi())
	var customer_type = _select_customer_type(territory_data)
	var type_data = customer_types[customer_type].duplicate()
	var greetings = [
		"Hey, you holding?",
		"Heard you might have something for me.",
		"You got the stuff?",
		"Looking to score."
	]
	var greeting = greetings[randi() % greetings.size()]
	var customer_data = {
		"id": customer_id,
		"type": type_data.name,
		"type_enum": customer_type,
		"greeting": greeting,
		"greeting_options": dialog_options.greeting,
		"negotiation_dialogue": "How much?",
		"success_dialogue": "Thanks, pleasure doing business.",
		"failure_dialogue": "No way, that's too much.",
		"patience_timer": type_data.patience,
		"price_sensitivity": type_data.price_sensitivity,
		"quality_sensitivity": type_data.quality_sensitivity,
		"is_undercover": type_data.get("is_undercover", false)
	}
	active_customers[customer_id] = {
		"data": customer_data
	}
	return customer_data
func _select_customer_type(territory_data):
	var allowed_types = []
	var weights = []
	var total_weight = 0
	for type in customer_types:
		var weight = customer_types[type].weight
		if weight <= 0:
			continue
		if territory_data.limit_customer_types && territory_data.allowed_customer_types.size() > 0:
			if !territory_data.allowed_customer_types.has(customer_types[type].name):
				continue
		allowed_types.append(type)
		var risk_modifier = 1.0
		var reputation_mod = 1.0
		if territory_reputation.has(territory_data.id):
			reputation_mod = lerp(0.5, 1.5, territory_reputation[territory_data.id])
		if type == CUSTOMER_TYPE.DEALER:
			risk_modifier = lerp(0.5, 1.5, 1.0 - territory_data.base_risk)
		elif type == CUSTOMER_TYPE.UNDERCOVER:
			if !territory_heat.has(territory_data.id) || territory_heat[territory_data.id] < 0.5:
				continue
			risk_modifier = lerp(0.1, 3.0, territory_heat[territory_data.id])
		var adjusted_weight = weight * risk_modifier * reputation_mod
		weights.append(adjusted_weight)
		total_weight += adjusted_weight
	if allowed_types.size() == 0:
		return CUSTOMER_TYPE.CASUAL
	var random_val = randf() * total_weight
	var running_total = 0
	for i in range(weights.size()):
		running_total += weights[i]
		if random_val <= running_total:
			return allowed_types[i]
	return allowed_types[0]
func get_product_data(product_type):
	if product_data.has(product_type):
		return product_data[product_type]
	return null
func calculate_base_price(product_type, customer_data):
	var product = get_product_data(product_type)
	if !product:
		return 0
	var territory_data = get_current_territory_data()
	var price_mod = 1.0
	if territory_data && territory_data.has("price_modifier"):
		price_mod = territory_data.price_modifier
	var base_price = product.base_price * price_mod
	if customer_data.has("type_enum"):
		var type = customer_data.type_enum
		if type == CUSTOMER_TYPE.DEALER:
			base_price *= 0.85
		elif type == CUSTOMER_TYPE.JUNKIE:
			base_price *= 1.2
	return int(base_price)
func calculate_success_chance(price, base_price, quality, customer_data):
	var price_ratio = base_price / float(max(1, price))
	var quality_bonus = quality * 0.5
	var price_weight = 0.6
	var quality_weight = 0.4
	if customer_data.has("price_sensitivity") && customer_data.has("quality_sensitivity"):
		price_weight = customer_data.price_sensitivity
		quality_weight = customer_data.quality_sensitivity
	var price_score = lerp(0.0, 1.0, clamp(price_ratio, 0.5, 1.5))
	var final_score = (price_score * price_weight) + (quality_bonus * quality_weight)
	return clamp(final_score, 0.0, 1.0)
func start_deal(customer_id):
	if !active_customers.has(customer_id):
		return false
	active_deals[customer_id] = active_customers[customer_id]
	if signal_bus:
		signal_bus.emit_signal("deal_started", active_customers[customer_id].data)
	return true
func attempt_deal(customer_id, price, quality):
	if !active_customers.has(customer_id) || !active_deals.has(customer_id):
		return false
	var customer_data = active_customers[customer_id].data
	var success_chance = calculate_success_chance(price, price, quality, customer_data)
	var roll = randf()
	var success = roll <= success_chance
	if success:
		complete_deal(customer_id, price, "blue")
	else:
		if signal_bus:
			signal_bus.emit_signal("deal_failed", customer_data.type)
		if customer_data.has("is_undercover") && customer_data.is_undercover:
			if tension_manager:
				tension_manager.add_heat(25.0)
			if signal_bus:
				signal_bus.emit_signal("busted_by_undercover")
	if active_deals.has(customer_id):
		active_deals.erase(customer_id)
	return success
func complete_deal(customer_id, price, product_type):
	if !active_customers.has(customer_id):
		return false
	var customer_data = active_customers[customer_id].data
	player_cash += price
	var territory_data = get_current_territory_data()
	if territory_data:
		var heat_increase = 0.05
		var reputation_increase = 0.02
		if product_data.has(product_type) && product_data[product_type].has("heat_modifier"):
			heat_increase *= product_data[product_type].heat_modifier
		add_territory_heat(territory_data.id, heat_increase)
		add_territory_reputation(territory_data.id, reputation_increase)
	if signal_bus:
		signal_bus.emit_signal("deal_completed", price, customer_data.type)
		signal_bus.emit_signal("cash_updated", player_cash)
	return true
func add_territory_heat(territory_id, amount):
	if !territory_heat.has(territory_id):
		territory_heat[territory_id] = 0.0
	territory_heat[territory_id] = clamp(territory_heat[territory_id] + amount, 0.0, 1.0)
	if territory_heat[territory_id] >= 0.8 && signal_bus:
		signal_bus.emit_signal("territory_heat_critical", territory_id)
	if tension_manager && territory_heat[territory_id] > 0.5:
		tension_manager.add_heat(amount * 10.0)
func add_territory_reputation(territory_id, amount):
	if !territory_reputation.has(territory_id):
		territory_reputation[territory_id] = 0.5
	territory_reputation[territory_id] = clamp(territory_reputation[territory_id] + amount, 0.0, 1.0)
	if signal_bus && territory_reputation[territory_id] >= 0.8:
		signal_bus.emit_signal("high_reputation_reached", territory_id)
func get_territory_heat(territory_id):
	if !territory_heat.has(territory_id):
		return 0.0
	return territory_heat[territory_id]
func get_territory_reputation(territory_id):
	if !territory_reputation.has(territory_id):
		return 0.5
	return territory_reputation[territory_id]
func get_customer_data(customer_id):
	if !active_customers.has(customer_id):
		return {}
	return active_customers[customer_id].data
func get_customer_patience(customer_id):
	if !active_customers.has(customer_id):
		return 0.0
	var customer_data = active_customers[customer_id].data
	return customer_data.get("current_patience", customer_data.get("patience_timer", 10.0)) / customer_data.get("patience_timer", 10.0)