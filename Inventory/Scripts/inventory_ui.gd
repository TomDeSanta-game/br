extends Control
func _ready():
	Log.info(self.name, "Simplified inventory UI loaded")
	add_to_group("Inventory")
	visible = false
func toggle_inventory():
	visible = !visible
func add_item(item_id, item_data):
	Log.info(self.name, "Adding item: " + str(item_data) + " x1")
	Log.info(self.name, "Added item with ID: \"" + item_id + "\"")
	return true