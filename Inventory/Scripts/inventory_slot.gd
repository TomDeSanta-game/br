extends Panel
const SLOT_COLOR_EMPTY = Color("#323232")
const SLOT_COLOR_FILLED = Color("#3C3C3C")
const SLOT_COLOR_HOVER = Color("#4ECDC4")
const TEXT_COLOR = Color("#F0F0F0")
const RARITY_COLORS = {
	"common": Color("#FFFFFF"),
	"uncommon": Color("#47B73A"),
	"rare": Color("#4794EA"),
	"epic": Color("#9E4BF8"),
	"legendary": Color("#FF9C00")
}
var item_data = null
var slot_index = -1
var is_hovered = false
func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = SLOT_COLOR_EMPTY
	stylebox.corner_radius_top_left = 8
	stylebox.corner_radius_top_right = 8
	stylebox.corner_radius_bottom_left = 8
	stylebox.corner_radius_bottom_right = 8
	add_theme_stylebox_override("panel", stylebox)
	
	
	$QuantityLabel.add_theme_color_override("font_color", TEXT_COLOR)
	
	clear_slot()
func set_item(data):
	item_data = data
	
	if item_data:
		$ItemTexture.texture = item_data.texture
		
		
		if item_data.has("quantity") and item_data.quantity > 1:
			$QuantityLabel.text = str(item_data.quantity)
			$QuantityLabel.visible = true
		else:
			$QuantityLabel.visible = false
		$ItemTexture.visible = true
		
		
		if item_data.has("rarity") and RARITY_COLORS.has(item_data.rarity):
			$RarityIndicator.color = RARITY_COLORS[item_data.rarity]
			$RarityIndicator.visible = true
			
			
			if item_data.rarity == "epic" or item_data.rarity == "legendary":
				var glow_effect = RichTextEffect.new()
				$ItemTexture.material = glow_effect
		else:
			$RarityIndicator.visible = false
		
		
		var stylebox = get_theme_stylebox("panel").duplicate()
		stylebox.bg_color = SLOT_COLOR_FILLED
		add_theme_stylebox_override("panel", stylebox)
		
		
		var tween = create_tween()
		$ItemTexture.scale = Vector2(0.9, 0.9)
		tween.tween_property($ItemTexture, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	else:
		clear_slot()
func clear_slot():
	item_data = null
	$ItemTexture.texture = null
	$ItemTexture.visible = false
	$QuantityLabel.visible = false
	$RarityIndicator.visible = false
	
	
	var stylebox = get_theme_stylebox("panel").duplicate()
	stylebox.bg_color = SLOT_COLOR_EMPTY
	add_theme_stylebox_override("panel", stylebox)
func select():
	$Border.border_color = SLOT_COLOR_HOVER
	
	
	var stylebox = get_theme_stylebox("panel").duplicate()
	stylebox.bg_color = SLOT_COLOR_HOVER.darkened(0.2)
	add_theme_stylebox_override("panel", stylebox)
	
	
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1).set_ease(Tween.EASE_OUT)
func deselect():
	$Border.border_color = Color(0.396, 0.396, 0.396, 0.5)
	
	
	var stylebox = get_theme_stylebox("panel").duplicate()
	if item_data:
		stylebox.bg_color = SLOT_COLOR_FILLED
	else:
		stylebox.bg_color = SLOT_COLOR_EMPTY
	
	if is_hovered:
		stylebox.bg_color = stylebox.bg_color.lightened(0.1)
		
	add_theme_stylebox_override("panel", stylebox)
	
	
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1).set_ease(Tween.EASE_OUT)
func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			SignalBus.emit_signal("slot_clicked", self)
func _on_mouse_entered():
	is_hovered = true
	
	
	var stylebox = get_theme_stylebox("panel").duplicate()
	if item_data:
		stylebox.bg_color = SLOT_COLOR_FILLED.lightened(0.1)
	else:
		stylebox.bg_color = SLOT_COLOR_EMPTY.lightened(0.1)
	add_theme_stylebox_override("panel", stylebox)
	
	
	if $ItemTexture.visible:
		var tween = create_tween()
		tween.tween_property($ItemTexture, "scale", Vector2(1.1, 1.1), 0.1).set_ease(Tween.EASE_OUT)
func _on_mouse_exited():
	is_hovered = false
	
	
	var stylebox = get_theme_stylebox("panel").duplicate()
	if item_data:
		stylebox.bg_color = SLOT_COLOR_FILLED
	else:
		stylebox.bg_color = SLOT_COLOR_EMPTY
	add_theme_stylebox_override("panel", stylebox)
	
	
	if $ItemTexture.visible:
		var tween = create_tween()
		tween.tween_property($ItemTexture, "scale", Vector2(1.0, 1.0), 0.1).set_ease(Tween.EASE_OUT)
func set_slot_index(index):
	slot_index = index
func get_slot_index():
	return slot_index 
