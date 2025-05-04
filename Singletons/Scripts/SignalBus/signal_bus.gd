extends Node

signal player_event(event_type, data)
signal object_event(object, event_type, data)
signal game_event(event_name, data)
signal ui_event(event_type, data)
signal slot_clicked(slot)
signal player_state_changed(new_state, old_state)

# Police system signals
signal police_alert_changed(level, old_level)
signal police_response(response_type)
signal wanted_level_changed(level, old_level)