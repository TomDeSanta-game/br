extends Node

signal slot_clicked(slot)
signal item_selected(item_data)
signal item_used(item_data)
signal item_dropped(item_data)

signal player_state_changed(prev_state, new_state)

signal player_entered_office
signal player_entered_wash_area
signal player_entered_lobby