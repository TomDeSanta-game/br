extends Panel
func _ready():
	
	visible = false
func display_item(item_data):
	if item_data == null:
		visible = false
		return
		
	
	$MarginContainer/VBoxContainer/HBoxContainer/ItemTexture.texture = item_data.texture
	
	
	$MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/ItemNameLabel.text = item_data.name
	
	
	if item_data.has("quantity"):
		$MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/ItemQuantityLabel.text = "Quantity: " + str(item_data.quantity)
		$MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/ItemQuantityLabel.visible = true
	else:
		$MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/ItemQuantityLabel.visible = false
	
	
	$MarginContainer/VBoxContainer/DescriptionLabel.text = item_data.description if item_data.has("description") else ""
	
	
	visible = true
func clear():
	$MarginContainer/VBoxContainer/HBoxContainer/ItemTexture.texture = null
	$MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/ItemNameLabel.text = ""
	$MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/ItemQuantityLabel.text = ""
	$MarginContainer/VBoxContainer/DescriptionLabel.text = ""
	visible = false 