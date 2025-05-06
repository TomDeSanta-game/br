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
@onready var customer_panel = $CustomerPanel
@onready var customer_name = $CustomerPanel/VBoxContainer/CustomerName
@onready var customer_dialogue = $CustomerPanel/VBoxContainer/CustomerDialogue
@onready var options_container = $CustomerPanel/VBoxContainer/OptionsContainer
@onready var product_details = $CustomerPanel/VBoxContainer/ProductDetails
@onready var timer_bar = $CustomerPanel/TimerBar
var current_customer = null
var current_options = []
var base_price = 0
var min_price = 0
var max_price = 0
var current_price = 0
var deal_phase = "greeting"
var product_quality = 0.0
var product_amount = 0.0
var deal_success_chance = 0.0
var customer_data = {}
func _ready():
    street_dealing = get_node_or_null("/root/StreetDealing")
    signal_bus = get_node_or_null("/root/SignalBus")
    if signal_bus:
        signal_bus.deal_started.connect(_on_deal_started)
        signal_bus.deal_canceled.connect(_on_deal_canceled)
        signal_bus.customer_left.connect(_on_customer_left)
    setup_response_buttons()
    if price_slider:
        price_slider.value_changed.connect(_on_price_changed)
    if quantity_slider:
        quantity_slider.value_changed.connect(_on_quantity_changed)
    if deal_button:
        deal_button.pressed.connect(_on_deal_button_pressed)
    if cancel_button:
        cancel_button.pressed.connect(_on_cancel_button_pressed)
    hide_ui()
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
    customer_panel.visible = true
    get_tree().paused = true
func hide_ui():
    customer_panel.visible = false
    get_tree().paused = false
    current_deal = null
    current_customer_id = ""
    current_customer = null
    current_options = []
    deal_phase = "greeting"
func _on_deal_started(customer):
    if !street_dealing:
        return
    current_customer = customer
    customer_data = street_dealing.get_customer_data(customer)
    if !customer_data || customer_data.size() == 0:
        return
    show_ui()
    update_ui()
    show_greeting()
func _on_deal_canceled():
    hide_ui()
func _on_customer_left():
    if current_customer:
        hide_ui()
func show_greeting():
    deal_phase = "greeting"
    customer_name.text = customer_data.get("name", "Unknown")
    customer_dialogue.text = customer_data.get("greeting", "Hey...")
    clear_options()
    deal_button.visible = false
    cancel_button.visible = true
    timer_bar.visible = true
    product_details.visible = false
    price_slider.visible = false
    price_label.visible = false
func show_negotiation(product_type: String):
    deal_phase = "negotiation"
    var product_data = street_dealing.get_product_data(product_type)
    if !product_data:
        return
    product_quality = product_data.quality
    product_amount = product_data.amount
    customer_dialogue.text = customer_data.get("negotiation_dialogue", "How much?")
    clear_options()
    base_price = street_dealing.calculate_base_price(product_type, customer_data)
    min_price = int(base_price * 0.7)
    max_price = int(base_price * 1.5)
    current_price = base_price
    product_details.visible = true
    product_details.text = "Product: %s\nQuality: %s\nAmount: %s" % [product_data.name, _format_quality(product_quality), _format_amount(product_amount)]
    price_slider.visible = true
    price_slider.min_value = min_price
    price_slider.max_value = max_price
    price_slider.value = base_price
    price_label.visible = true
    price_label.text = "$%d" % base_price
    deal_button.visible = true
    deal_button.text = "Offer"
    cancel_button.visible = true
    timer_bar.visible = true
    _update_deal_chance()
func show_result(success: bool):
    deal_phase = "result"
    clear_options()
    if success:
        customer_dialogue.text = customer_data.get("success_dialogue", "Thanks!")
        if signal_bus:
            signal_bus.emit_signal("deal_completed", current_price, customer_data.get("type", "normal"))
        deal_button.visible = false
        cancel_button.visible = true
        cancel_button.text = "Close"
    else:
        customer_dialogue.text = customer_data.get("failure_dialogue", "No way!")
        if signal_bus:
            signal_bus.emit_signal("deal_failed", customer_data.get("type", "normal"))
        deal_button.visible = false
        cancel_button.visible = true
        cancel_button.text = "Close"
    product_details.visible = false
    price_slider.visible = false
    price_label.visible = false
    timer_bar.visible = false
func clear_options():
    for child in options_container.get_children():
        child.queue_free()
    current_options = []
func add_option(text: String, data = null):
    pass
func _on_option_selected(option_data):
    if !option_data:
        return
    if option_data.has("product_type"):
        var product_type = option_data.product_type
        show_negotiation(product_type)
    elif option_data.has("action"):
        match option_data.action:
            "leave":
                hide_ui()
                if signal_bus:
                    signal_bus.emit_signal("deal_canceled")
func _on_deal_button_pressed():
    if deal_phase == "negotiation":
        var success = street_dealing.attempt_deal(current_customer, current_price, product_quality)
        show_result(success)
func _on_cancel_button_pressed():
    if deal_phase == "result":
        hide_ui()
        return
    hide_ui()
    if signal_bus:
        signal_bus.emit_signal("deal_canceled")
func _on_price_changed(value):
    current_price = int(value)
    price_label.text = "$%d" % current_price
    _update_deal_chance()
func _on_quantity_changed(value):
    if quantity_label:
        quantity_label.text = quantity_formatter % value
    update_total_value()
func update_total_value():
    if total_label && price_slider && quantity_slider:
        var total = price_slider.value * quantity_slider.value
        total_label.text = "$" + (price_formatter % total)
func _update_deal_chance():
    deal_success_chance = street_dealing.calculate_success_chance(
        current_price,
        base_price,
        product_quality,
        customer_data
    )
    var chance_text = ""
    if deal_success_chance >= 0.8:
        chance_text = "Very Likely"
        deal_button.modulate = Color(0.2, 1.0, 0.2)
    elif deal_success_chance >= 0.6:
        chance_text = "Likely"
        deal_button.modulate = Color(0.5, 1.0, 0.5)
    elif deal_success_chance >= 0.4:
        chance_text = "Maybe"
        deal_button.modulate = Color(1.0, 1.0, 0.2)
    elif deal_success_chance >= 0.2:
        chance_text = "Unlikely"
        deal_button.modulate = Color(1.0, 0.5, 0.2)
    else:
        chance_text = "Very Unlikely"
        deal_button.modulate = Color(1.0, 0.2, 0.2)
    deal_button.text = "Offer (%s)" % chance_text
func update_ui():
    if !street_dealing || !current_customer:
        return
    var patience = street_dealing.get_customer_patience(current_customer)
    if patience > 0:
        timer_bar.value = patience * 100
func _format_quality(quality: float) -> String:
    if quality >= 0.9:
        return "Excellent"
    elif quality >= 0.7:
        return "Good"
    elif quality >= 0.5:
        return "Average"
    elif quality >= 0.3:
        return "Poor"
    else:
        return "Terrible"
func _format_amount(amount: float) -> String:
    if amount >= 0.9:
        return "Large"
    elif amount >= 0.7:
        return "Medium-Large"
    elif amount >= 0.5:
        return "Medium"
    elif amount >= 0.3:
        return "Small"
    else:
        return "Tiny"
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
                if index == 0:
                    modifier = 0.1
                elif index == 1:
                    price = current_deal.counter_price * 1.05
                    modifier = 0.2
                elif index == 2:
                    modifier = -0.1
                elif index == 3:
                    price = current_deal.counter_price * 1.1
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
    _on_price_changed(price_slider.value)
    _on_quantity_changed(quantity_slider.value)
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