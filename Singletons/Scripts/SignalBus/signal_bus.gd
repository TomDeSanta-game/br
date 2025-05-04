extends Node

signal player_event(event_type, data)
signal player_state_changed(new_state, old_state)
signal player_detected(detector_type)
signal player_entered_area(area_name)
signal player_exited_area(area_name)
signal player_entered(zone_name)
signal player_exited(zone_name)

signal object_event(object, event_type, data)
signal slot_clicked(slot)
signal gong_struck
signal meth_batch_collected(batch_id)

signal ui_event(event_type, data)
signal time_updated(time_remaining, total_time)
signal show_alert_message(message)
signal show_mission_text(text)
signal update_mission_text(text)
signal hide_mission_text
signal update_mission_progress(completed, total)

signal game_event(event_name, data)
signal death
signal damaged(amount, knockback)

signal police_alert_changed(level, old_level)
signal police_response(response_type)
signal wanted_level_changed(level, old_level)
signal police_alerted

signal tension_changed(new_value, old_value)
signal max_tension_reached
signal min_tension_reached
signal threshold_crossed(threshold_name, direction)
signal heat_level_changed(new_level, old_level)

signal encounter_started(encounter_name)
signal encounter_completed(encounter_name, success)
signal encounter_failed(encounter_name)

signal music_changed(music_name)
signal ambient_changed(ambient_name)

signal deal_started(customer_data)
signal deal_completed(deal_data)
signal deal_failed(reason)
signal deal_canceled
signal customer_left
signal territory_status_changed(territory_name, status)
signal counter_offer(data)