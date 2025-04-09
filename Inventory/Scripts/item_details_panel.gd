extends Panel

# Called when the node enters the scene tree for the first time
func _ready():
	# Initially hide the panel
	visible = false

# Display item details
func display_item(item_data):
	if item_data == null:
		visible = false
		return
		
	# Set the item texture
	$MarginContainer/VBoxContainer/HBoxContainer/ItemTexture.texture = item_data.texture
	
	# Set the item name
	$MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/ItemNameLabel.text = item_data.name
	
	# Set the item quantity if applicable
	if item_data.has("quantity"):
		$MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/ItemQuantityLabel.text = "Quantity: " + str(item_data.quantity)
		$MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/ItemQuantityLabel.visible = true
	else:
		$MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/ItemQuantityLabel.visible = false
	
	# Set the item description
	$MarginContainer/VBoxContainer/DescriptionLabel.text = item_data.description if item_data.has("description") else ""
	
	# Show the panel
	visible = true

# Clear and hide the panel
func clear():
	$MarginContainer/VBoxContainer/HBoxContainer/ItemTexture.texture = null
	$MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/ItemNameLabel.text = ""
	$MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/ItemQuantityLabel.text = ""
	$MarginContainer/VBoxContainer/DescriptionLabel.text = ""
	visible = false 