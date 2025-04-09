extends Control
const BACKGROUND_COLOR = Color("#1E1E1E")
const SLOT_COLOR_EMPTY = Color("#323232")
const SLOT_COLOR_FILLED = Color("#3C3C3C")
const SLOT_COLOR_HOVER = Color("#4ECDC4")
const TEXT_COLOR = Color("#F0F0F0")
const ACCENT_COLOR = Color("#FF6B6B")
const SECONDARY_COLOR = Color("#77DD77")
var inventory_data: Dictionary = {}
var selected_slot: int = -1
var tooltip_item = null
var current_category: String = "All"
var categories = ["All", "Weapons", "Potions", "Gear", "Materials"]
var search_text: String = ""
var tooltip_timer: Timer = null
var is_mouse_over_tooltip: bool = false
var is_mouse_over_slot: bool = false
var current_tooltip_slot = null
func _ready():
	Grok.register_inventory(self)
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = BACKGROUND_COLOR
	stylebox.corner_radius_top_left = 15
	stylebox.corner_radius_top_right = 15
	stylebox.corner_radius_bottom_left = 15
	stylebox.corner_radius_bottom_right = 15
	$Background.add_theme_stylebox_override("panel", stylebox)
	setup_tooltip()
	setup_categories()
	setup_action_buttons()
	setup_search_input()
	tooltip_timer = Timer.new()
	tooltip_timer.wait_time = 1.0
	tooltip_timer.one_shot = true
	tooltip_timer.timeout.connect(_on_tooltip_timer_timeout)
	add_child(tooltip_timer)
	$Background/MarginContainer/VBoxContainer/SearchContainer/SearchInput.text_changed.connect(_on_search_text_changed)
	var sort_button = $Background/MarginContainer/VBoxContainer/SearchContainer/SortButton
	sort_button.get_popup().id_pressed.connect(_on_sort_option_selected)
	setup_sort_button(sort_button)
	$Background/MarginContainer/VBoxContainer/ButtonContainer/HBoxContainer/UseButton.pressed.connect(_on_use_button_pressed)
	$Background/MarginContainer/VBoxContainer/ButtonContainer/HBoxContainer/DropButton.pressed.connect(_on_drop_button_pressed)
	$Background/MarginContainer/VBoxContainer/ButtonContainer/HBoxContainer/CloseButton.pressed.connect(_on_close_button_pressed)
	SignalBus.slot_clicked.connect(_on_slot_clicked)
	for slot in $Background/MarginContainer/VBoxContainer/ItemGridContainer/ItemGrid.get_children():
		var index = slot.get_index()
		slot.set_slot_index(index)
		slot.mouse_entered.connect(_on_slot_mouse_entered.bind(slot))
		slot.mouse_exited.connect(_on_slot_mouse_exited)
	$Tooltip.visible = false
	visible = false
	$Tooltip.mouse_entered.connect(_on_tooltip_mouse_entered)
	$Tooltip.mouse_exited.connect(_on_tooltip_mouse_exited)
	update_inventory_display()
func _on_slot_mouse_entered(_slot):
	is_mouse_over_slot = true
	if tooltip_timer.is_stopped() == false:
		tooltip_timer.stop()
func _on_slot_mouse_exited():
	is_mouse_over_slot = false
	check_hide_tooltip()
func _on_tooltip_mouse_entered():
	is_mouse_over_tooltip = true
	if tooltip_timer.is_stopped() == false:
		tooltip_timer.stop()
func _on_tooltip_mouse_exited():
	is_mouse_over_tooltip = false
	check_hide_tooltip()
func check_hide_tooltip():
	if !is_mouse_over_slot and !is_mouse_over_tooltip and $Tooltip.visible:
		tooltip_timer.start()
func _on_tooltip_timer_timeout():
	if !is_mouse_over_slot and !is_mouse_over_tooltip:
		$Tooltip.visible = false
func setup_tooltip():
	var tooltip_stylebox = StyleBoxFlat.new()
	tooltip_stylebox.bg_color = BACKGROUND_COLOR.darkened(0.2)
	tooltip_stylebox.corner_radius_top_left = 10
	tooltip_stylebox.corner_radius_top_right = 10
	tooltip_stylebox.corner_radius_bottom_left = 10
	tooltip_stylebox.corner_radius_bottom_right = 10
	tooltip_stylebox.shadow_color = Color(0, 0, 0, 0.4)
	tooltip_stylebox.shadow_size = 3
	tooltip_stylebox.shadow_offset = Vector2(1, 1)
	tooltip_stylebox.content_margin_left = 8
	tooltip_stylebox.content_margin_top = 8
	tooltip_stylebox.content_margin_right = 8
	tooltip_stylebox.content_margin_bottom = 8
	$Tooltip.add_theme_stylebox_override("panel", tooltip_stylebox)
	$Tooltip.custom_minimum_size = Vector2(220, 0)
	var separator_stylebox = StyleBoxFlat.new()
	separator_stylebox.bg_color = ACCENT_COLOR.darkened(0.5)
	separator_stylebox.content_margin_top = 1
	separator_stylebox.content_margin_bottom = 1
	$Tooltip/VBoxContainer/HSeparator.add_theme_stylebox_override("separator", separator_stylebox)
	$Tooltip/VBoxContainer/ItemName.add_theme_color_override("font_color", TEXT_COLOR)
	$Tooltip/VBoxContainer/ItemCategory.add_theme_color_override("font_color", ACCENT_COLOR)
	$Tooltip/VBoxContainer/ItemDescription.add_theme_color_override("font_color", TEXT_COLOR.darkened(0.2))
	$Tooltip/VBoxContainer.add_theme_constant_override("separation", 4)
func setup_categories():
	var category_container = $Background/MarginContainer/VBoxContainer/CategoryContainer/HBoxContainer
	for button in category_container.get_children():
		button.pressed.connect(_on_category_button_pressed.bind(button.text))
		var normal_stylebox = StyleBoxFlat.new()
		normal_stylebox.bg_color = SLOT_COLOR_EMPTY
		normal_stylebox.corner_radius_top_left = 8
		normal_stylebox.corner_radius_top_right = 8
		normal_stylebox.corner_radius_bottom_left = 8
		normal_stylebox.corner_radius_bottom_right = 8
		var hover_stylebox = normal_stylebox.duplicate()
		hover_stylebox.bg_color = SLOT_COLOR_HOVER.darkened(0.2)
		var pressed_stylebox = normal_stylebox.duplicate()
		pressed_stylebox.bg_color = SLOT_COLOR_HOVER
		button.add_theme_stylebox_override("normal", normal_stylebox)
		button.add_theme_stylebox_override("hover", hover_stylebox)
		button.add_theme_stylebox_override("pressed", pressed_stylebox)
		button.add_theme_color_override("font_color", TEXT_COLOR)
		button.add_theme_color_override("font_hover_color", TEXT_COLOR.lightened(0.2))
		button.add_theme_color_override("font_pressed_color", TEXT_COLOR.lightened(0.3))
		button.focus_mode = Control.FOCUS_NONE
		if button.text == "All":
			button.add_theme_stylebox_override("normal", pressed_stylebox)
func setup_action_buttons():
	var use_button = $Background/MarginContainer/VBoxContainer/ButtonContainer/HBoxContainer/UseButton
	var drop_button = $Background/MarginContainer/VBoxContainer/ButtonContainer/HBoxContainer/DropButton
	var close_button = $Background/MarginContainer/VBoxContainer/ButtonContainer/HBoxContainer/CloseButton
	setup_action_button(use_button, SECONDARY_COLOR, "Use")
	setup_action_button(drop_button, Color("#CCCCCC"), "Drop")
	setup_action_button(close_button, ACCENT_COLOR, "Close")
func setup_action_button(button, base_color, text):
	var normal_stylebox = StyleBoxFlat.new()
	normal_stylebox.bg_color = Color(0, 0, 0, 0)
	normal_stylebox.corner_radius_top_left = 8
	normal_stylebox.corner_radius_top_right = 8
	normal_stylebox.corner_radius_bottom_left = 8
	normal_stylebox.corner_radius_bottom_right = 8
	var hover_stylebox = normal_stylebox.duplicate()
	hover_stylebox.bg_color = base_color.darkened(0.7)
	var pressed_stylebox = normal_stylebox.duplicate()
	pressed_stylebox.bg_color = base_color.darkened(0.5)
	var focus_stylebox = normal_stylebox.duplicate()
	focus_stylebox.bg_color = Color(0, 0, 0, 0)
	focus_stylebox.border_width_bottom = 2
	focus_stylebox.border_color = base_color
	button.add_theme_stylebox_override("normal", normal_stylebox)
	button.add_theme_stylebox_override("hover", hover_stylebox)
	button.add_theme_stylebox_override("pressed", pressed_stylebox)
	button.add_theme_stylebox_override("focus", focus_stylebox)
	button.text = text
	button.add_theme_color_override("font_color", base_color)
	button.add_theme_color_override("font_hover_color", base_color.lightened(0.2))
	button.add_theme_color_override("font_pressed_color", base_color.lightened(0.3))
	button.add_theme_color_override("font_focus_color", base_color.lightened(0.2))
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
func setup_sort_button(button):
	var normal_stylebox = StyleBoxFlat.new()
	normal_stylebox.bg_color = SLOT_COLOR_EMPTY
	normal_stylebox.corner_radius_top_left = 8
	normal_stylebox.corner_radius_top_right = 8
	normal_stylebox.corner_radius_bottom_left = 8
	normal_stylebox.corner_radius_bottom_right = 8
	var hover_stylebox = normal_stylebox.duplicate()
	hover_stylebox.bg_color = SLOT_COLOR_HOVER.darkened(0.2)
	var pressed_stylebox = normal_stylebox.duplicate()
	pressed_stylebox.bg_color = SLOT_COLOR_HOVER
	var focus_stylebox = normal_stylebox.duplicate()
	focus_stylebox.bg_color = SLOT_COLOR_HOVER.darkened(0.3)
	focus_stylebox.border_width_bottom = 2
	focus_stylebox.border_width_top = 2
	focus_stylebox.border_width_left = 2
	focus_stylebox.border_width_right = 2
	focus_stylebox.border_color = ACCENT_COLOR
	button.add_theme_stylebox_override("normal", normal_stylebox)
	button.add_theme_stylebox_override("hover", hover_stylebox)
	button.add_theme_stylebox_override("pressed", pressed_stylebox)
	button.add_theme_stylebox_override("focus", focus_stylebox)
	button.add_theme_color_override("font_color", TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", TEXT_COLOR.lightened(0.2))
	button.add_theme_color_override("font_pressed_color", TEXT_COLOR.lightened(0.3))
	button.add_theme_color_override("font_focus_color", TEXT_COLOR.lightened(0.2))
	var popup = button.get_popup()
	var popup_stylebox = StyleBoxFlat.new()
	popup_stylebox.bg_color = BACKGROUND_COLOR
	popup_stylebox.corner_radius_top_left = 8
	popup_stylebox.corner_radius_top_right = 8
	popup_stylebox.corner_radius_bottom_left = 8
	popup_stylebox.corner_radius_bottom_right = 8
	popup.add_theme_stylebox_override("panel", popup_stylebox)
	popup.add_theme_color_override("font_color", TEXT_COLOR)
	popup.add_theme_color_override("font_hover_color", TEXT_COLOR.lightened(0.2))
	button.focus_mode = Control.FOCUS_NONE
func _on_category_button_pressed(category_name):
	current_category = category_name
	for button in $Background/MarginContainer/VBoxContainer/CategoryContainer/HBoxContainer.get_children():
		var normal_stylebox = button.get_theme_stylebox("normal").duplicate()
		var pressed_stylebox = button.get_theme_stylebox("pressed").duplicate() 
		if button.text == category_name:
			button.add_theme_stylebox_override("normal", pressed_stylebox)
		else:
			normal_stylebox.bg_color = SLOT_COLOR_EMPTY
			button.add_theme_stylebox_override("normal", normal_stylebox)
	update_inventory_display()
func _on_search_text_changed(new_text):
	search_text = new_text.to_lower()
	update_inventory_display()
func _on_slot_clicked(slot):
	var clicked_slot_index = slot.get_slot_index()
	select_slot(clicked_slot_index)
	update_tooltip(slot)
func update_inventory_display():
	for slot in $Background/MarginContainer/VBoxContainer/ItemGridContainer/ItemGrid.get_children():
		slot.visible = false
	var _visible_slot_count = 0
	var actual_item_count = 0
	for i in range(15):
		if inventory_data.has(str(i)):
			actual_item_count += 1
	for slot in $Background/MarginContainer/VBoxContainer/ItemGridContainer/ItemGrid.get_children():
		var slot_index = slot.get_slot_index()
		if inventory_data.has(str(slot_index)):
			var item = inventory_data[str(slot_index)]
			var category_match = current_category == "All" or (item.has("category") and item.category == current_category)
			var search_match = search_text.is_empty() or (
				item.has("name") and item.name.to_lower().contains(search_text) or
				item.has("description") and item.description.to_lower().contains(search_text)
			)
			if category_match and search_match:
				slot.set_item(item)
				slot.visible = true
				_visible_slot_count += 1
			else:
				slot.clear_slot()
				slot.visible = false
		else:
			if current_category == "All" and search_text.is_empty():
				slot.clear_slot()
				slot.visible = true
		if slot_index == selected_slot:
			slot.select()
		else:
			slot.deselect()
	$Background/MarginContainer/VBoxContainer/HeaderLabel.text = "INVENTORY (" + str(actual_item_count) + ")"
func set_inventory_data(data):
	inventory_data = data
	update_inventory_display()
func select_slot(slot_index):
	if slot_index >= 0 and slot_index < 15:
		selected_slot = slot_index
	else:
		selected_slot = -1
	update_inventory_display()
func _on_use_button_pressed():
	if selected_slot >= 0:
		var item_data = get_item_at_slot(selected_slot)
		if item_data:
			SignalBus.emit_signal("item_used", item_data)
func _on_drop_button_pressed():
	if selected_slot >= 0:
		var item_data = get_item_at_slot(selected_slot)
		if item_data:
			SignalBus.emit_signal("item_dropped", item_data)
			remove_item(selected_slot)
func _on_close_button_pressed():
	hide_inventory()
func get_item_at_slot(slot_index):
	if inventory_data.has(str(slot_index)):
		return inventory_data[str(slot_index)]
	return null
func toggle_inventory():
	if visible:
		hide_inventory()
	else:
		show_inventory()
func show_inventory():
	visible = true
	$AnimationPlayer.play("fade_in")
func hide_inventory():
	$AnimationPlayer.play("fade_out")
	await $AnimationPlayer.animation_finished
	visible = false
	$Tooltip.visible = false
func add_item(item_data):
	var item_name = item_data.name if item_data.has("name") else ""
	for i in range(15):
		if inventory_data.has(str(i)):
			var existing_item = inventory_data[str(i)]
			if existing_item.has("name") and existing_item.name == item_name:
				if existing_item.has("quantity"):
					existing_item.quantity += item_data.quantity if item_data.has("quantity") else 1
					update_inventory_display()
					return
	for i in range(15):
		if not inventory_data.has(str(i)):
			inventory_data[str(i)] = item_data
			update_inventory_display()
			return
	Log.info("Inventory Full!")
func remove_item(slot_index, _quantity=1):
	if inventory_data.has(str(slot_index)):
		inventory_data.erase(str(slot_index))
		update_inventory_display()
		if selected_slot == slot_index:
			$Tooltip.visible = false
func update_tooltip(slot):
	current_tooltip_slot = slot
	if slot.item_data:
		$Tooltip/VBoxContainer/ItemName.text = slot.item_data.name if slot.item_data.has("name") else "Unknown Item"
		$Tooltip/VBoxContainer/ItemDescription.text = slot.item_data.description if slot.item_data.has("description") else "No description available."
		if slot.item_data.has("category"):
			$Tooltip/VBoxContainer/ItemCategory.text = slot.item_data.category
			$Tooltip/VBoxContainer/ItemCategory.visible = true
		else:
			$Tooltip/VBoxContainer/ItemCategory.visible = false
		$Tooltip/VBoxContainer/ItemStats.text = ""
		if slot.item_data.has("stats"):
			var stats_text = ""
			for stat_name in slot.item_data.stats:
				var stat_value = slot.item_data.stats[stat_name]
				var _sign = "+" if stat_value > 0 else ""
				stats_text += stat_name + ": " + _sign + str(stat_value) + "\n"
			$Tooltip/VBoxContainer/ItemStats.text = stats_text
			$Tooltip/VBoxContainer/ItemStats.visible = true
		else:
			$Tooltip/VBoxContainer/ItemStats.visible = false
		var slot_global_pos = slot.global_position
		$Tooltip.global_position = Vector2(slot_global_pos.x + 50, slot_global_pos.y)
		if tooltip_timer.is_stopped() == false:
			tooltip_timer.stop()
		$Tooltip.modulate = Color(1, 1, 1, 0)
		$Tooltip.visible = true
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property($Tooltip, "modulate", Color(1, 1, 1, 1), 0.3)
		tween.parallel().tween_property($Tooltip, "scale", Vector2(1, 1), 0.3).from(Vector2(0.9, 0.95))
	else:
		$Tooltip.visible = false
func sort_inventory_by(sort_type):
	var sorted_items = []
	for i in range(15):
		if inventory_data.has(str(i)):
			var item = inventory_data[str(i)]
			item.slot_index = i
			sorted_items.append(item)
	match sort_type:
		"name":
			sorted_items.sort_custom(func(a, b): return a.name < b.name if a.has("name") and b.has("name") else false)
		"category":
			sorted_items.sort_custom(func(a, b): return a.category < b.category if a.has("category") and b.has("category") else false)
		"rarity":
			sorted_items.sort_custom(func(a, b): return a.rarity > b.rarity if a.has("rarity") and b.has("rarity") else false)
	inventory_data.clear()
	for i in range(sorted_items.size()):
		inventory_data[str(i)] = sorted_items[i]
	update_inventory_display()
func _on_sort_option_selected(id):
	match id:
		0:
			sort_inventory_by("name")
		1:
			sort_inventory_by("category")
		2:
			sort_inventory_by("rarity")
func setup_search_input():
	var search_input = $Background/MarginContainer/VBoxContainer/SearchContainer/SearchInput
	var normal_stylebox = StyleBoxFlat.new()
	normal_stylebox.bg_color = SLOT_COLOR_EMPTY
	normal_stylebox.corner_radius_top_left = 8
	normal_stylebox.corner_radius_top_right = 8
	normal_stylebox.corner_radius_bottom_left = 8
	normal_stylebox.corner_radius_bottom_right = 8
	normal_stylebox.content_margin_left = 12
	normal_stylebox.content_margin_top = 8
	normal_stylebox.content_margin_right = 12
	normal_stylebox.content_margin_bottom = 8
	var focus_stylebox = normal_stylebox.duplicate()
	focus_stylebox.border_width_bottom = 2
	focus_stylebox.border_width_top = 2
	focus_stylebox.border_width_left = 2
	focus_stylebox.border_width_right = 2
	focus_stylebox.border_color = SLOT_COLOR_HOVER
	search_input.add_theme_stylebox_override("normal", normal_stylebox)
	search_input.add_theme_stylebox_override("focus", focus_stylebox)
	search_input.add_theme_color_override("font_color", TEXT_COLOR)
	search_input.add_theme_color_override("font_placeholder_color", TEXT_COLOR.darkened(0.4))
	search_input.add_theme_color_override("caret_color", ACCENT_COLOR)
	search_input.placeholder_text = "Search items..."
