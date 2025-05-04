extends Control

@export_category("UI References")
@export var customer_label: Label
@export var dialogue_label: RichTextLabel
@export var response_container: VBoxContainer
@export var response_button_scene: PackedScene
@export var quantity_slider: Slider
@export var price_slider: Slider
@export var price_label: Label
@export var quantity_label: Label
@export var total_label: Label
@export var deal_button: Button
@export var cancel_button: Button
@export var product_info_container: PanelContainer
@export var negotiation_container: PanelContainer
@export var success_panel: PanelContainer
@export var failure_panel: PanelContainer

@export_category("UI Settings")
@export var response_button_count: int = 4
@export var price_slider_steps: int = 20
@export var quantity_slider_steps: int = 10
@export var max_price_multiplier: float = 2.0
@export var min_price_multiplier: float = 0.5

var street_dealing = null
var signal_bus = null
var current_customer_id = ""
var current_deal = null
var current_stage = ""
var current_dialogue = ""
var response_buttons = []
var response_data = []
var price_formatter = "%0.2f"
var quality_labels = ["Low", "Medium", "High", "Very High"]
var quantity_formatter = "%0.1f g"

func _ready():
    street_dealing = get_node_or_null("/root/StreetDealing")
    signal_bus = get_node_or_null("/root/SignalBus")
    
    if signal_bus:
        if signal_bus.has_signal("deal_started"):
            signal_bus.deal_started.connect(_on_deal_started)
        if signal_bus.has_signal("deal_completed"):
            signal_bus.deal_completed.connect(_on_deal_completed)
        if signal_bus.has_signal("deal_failed"):
            signal_bus.deal_failed.connect(_on_deal_failed)
        if signal_bus.has_signal("game_event"):
            signal_bus.game_event.connect(_on_game_event)
    
    setup_response_buttons()
    
    if price_slider:
        price_slider.value_changed.connect(_on_price_slider_changed)
    if quantity_slider:
        quantity_slider.value_changed.connect(_on_quantity_slider_changed)
    
    if deal_button:
        deal_button.pressed.connect(_on_deal_button_pressed)
    if cancel_button:
        cancel_button.pressed.connect(_on_cancel_button_pressed)
    
    hide()

func setup_response_buttons():
    for button in response_buttons:
        if is_instance_valid(button):
            button.queue_free()
    response_buttons.clear()
    
    if response_container && response_button_scene:
        for i in range(response_button_count):
            var button = response_button_scene.instantiate()
            response_container.add_child(button)
            button.visible = false
            button.pressed.connect(_on_response_button_pressed.bind(i))
            response_buttons.append(button)

func show_ui():
    visible = true
    get_tree().paused = true

func hide_ui():
    visible = false
    get_tree().paused = false
    current_deal = null
    current_customer_id = ""

func _on_deal_started(deal_data):
    current_deal = deal_data
    current_customer_id = deal_data.customer_id
    current_stage = "greeting"
    
    current_dialogue = deal_data.customer.get("greeting", "Hey, you got something for me?")
    
    update_customer_info()
    update_dialogue()
    update_responses("greeting")
    setup_product_info()
    show_ui()

func _on_deal_completed(deal_data):
    if success_panel:
        success_panel.visible = true
    
    if deal_data.has("total_value"):
        var success_msg = "Deal completed! You sold %s for $%s." % [
            quantity_formatter % deal_data.quantity,
            price_formatter % deal_data.total_value
        ]
        
        if dialogue_label:
            dialogue_label.text = success_msg
    
    await get_tree().create_timer(2.0).timeout
    hide_ui()

func _on_deal_failed(fail_data):
    if failure_panel:
        failure_panel.visible = true
    
    var reason = fail_data.reason if fail_data.has("reason") else "unknown"
    var fail_msg = "Deal failed: "
    
    match reason:
        "suspicion":
            fail_msg += "The customer got suspicious and left."
        "player_cancelled":
            fail_msg += "You cancelled the deal."
        "police":
            fail_msg += "Police presence scared the customer away."
        "undercover":
            fail_msg += "It was an undercover cop!"
        _:
            fail_msg += "The customer walked away."
    
    if dialogue_label:
        dialogue_label.text = fail_msg
    
    await get_tree().create_timer(2.0).timeout
    hide_ui()

func update_customer_info():
    if !current_deal || !current_deal.has("customer"):
        return
    
    if customer_label:
        var customer_type = current_deal.customer.type.capitalize() if current_deal.customer.has("type") else "Customer"
        customer_label.text = customer_type

func update_dialogue():
    if dialogue_label:
        dialogue_label.text = current_dialogue

func update_responses(stage):
    if !street_dealing || !street_dealing.player_responses.has(stage):
        return
    
    var responses = street_dealing.player_responses[stage]
    response_data = []
    
    for i in range(response_buttons.size()):
        var button = response_buttons[i]
        
        if i < responses.size():
            var response_text = responses[i]
            
            if response_text.contains("{price}") && current_deal && current_deal.has("counter_price"):
                response_text = response_text.replace("{price}", price_formatter % current_deal.counter_price)
            
            button.text = response_text
            button.visible = true
            response_data.append(response_text)
        else:
            button.visible = false
    
    if negotiation_container && product_info_container:
        negotiation_container.visible = stage == "negotiation"
        product_info_container.visible = stage != "negotiation"

func setup_product_info():
    if !street_dealing:
        return
    
    if price_slider:
        var base_price = street_dealing.get_meth_price()
        var min_price = base_price * min_price_multiplier
        var max_price = base_price * max_price_multiplier
        
        price_slider.min_value = min_price
        price_slider.max_value = max_price
        price_slider.step = (max_price - min_price) / price_slider_steps
        price_slider.value = base_price
    
    if quantity_slider:
        var max_quantity = street_dealing.current_meth_quantity
        
        if current_deal && current_deal.customer.has("quantity_wanted"):
            max_quantity = min(max_quantity, current_deal.customer.quantity_wanted)
        
        quantity_slider.min_value = 0.1
        quantity_slider.max_value = max_quantity
        quantity_slider.step = max_quantity / quantity_slider_steps
        quantity_slider.value = max_quantity / 2.0
    
    _on_price_slider_changed(price_slider.value)
    _on_quantity_slider_changed(quantity_slider.value)

func _on_response_button_pressed(index):
    if index >= response_data.size():
        return
    
    match current_stage:
        "greeting":
            current_stage = "negotiation"
            update_responses("negotiation")
        
        "negotiation":
            if current_deal.has("counter_price"):
                var price = price_slider.value
                var quantity = quantity_slider.value
                
                var modifier = 0.0
                if index == 0:  # Assertive (quality argument)
                    modifier = 0.1
                elif index == 1:  # Final price offer
                    price = current_deal.counter_price * 1.05  # Slightly higher than counter
                    modifier = 0.2
                elif index == 2:  # Take it or leave it
                    modifier = -0.1
                elif index == 3:  # Work something out
                    price = current_deal.counter_price * 1.1  # Higher but not by much
                    modifier = 0.3
                
                if price_slider:
                    price_slider.value = price
                
                if street_dealing:
                    var success = street_dealing.offer_deal(price, quantity)
                    if !success && current_deal && current_deal.has("counter_price"):
                        current_dialogue = "How about $%s per gram?" % (price_formatter % current_deal.counter_price)
                        update_dialogue()
            else:
                if street_dealing:
                    street_dealing.offer_deal(price_slider.value, quantity_slider.value)

func _on_price_slider_changed(value):
    if price_label:
        price_label.text = "$" + (price_formatter % value) + "/g"
    
    update_total_value()

func _on_quantity_slider_changed(value):
    if quantity_label:
        quantity_label.text = quantity_formatter % value
    
    update_total_value()

func update_total_value():
    if total_label && price_slider && quantity_slider:
        var total = price_slider.value * quantity_slider.value
        total_label.text = "$" + (price_formatter % total)

func _on_deal_button_pressed():
    if !street_dealing || !current_deal:
        return
    
    street_dealing.offer_deal(price_slider.value, quantity_slider.value)

func _on_cancel_button_pressed():
    if street_dealing:
        street_dealing.cancel_deal()

func _on_game_event(event_name, data):
    match event_name:
        "counter_offer":
            if data.has("price") && current_deal:
                current_deal.counter_price = data.price
                current_dialogue = "How about $%s per gram?" % (price_formatter % data.price)
                update_dialogue()
                update_responses("negotiation")
        
        "police_spotted":
            if is_visible() && street_dealing:
                street_dealing.cancel_deal()
                hide_ui() 