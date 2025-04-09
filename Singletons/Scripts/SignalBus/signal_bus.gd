extends Node

# Inventory signals
signal slot_clicked(slot)
signal item_selected(item_data)
signal item_used(item_data)
signal item_dropped(item_data)

# Player state signals
signal player_state_changed(prev_state, new_state)