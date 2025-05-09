extends Node

signal player_event(event_type, data)
signal player_state_changed(new_state, old_state)
signal player_detected(detector_type)
signal player_entered_area(area_name)
signal player_exited_area(area_name)
signal player_entered(zone_name)
signal player_exited(zone_name)
signal damaged(amount, knockback)
signal death
signal health_changed(new_value, old_value)
signal stress_changed(new_value, old_value)

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

signal tension_changed(new_value, old_value)
signal max_tension_reached
signal min_tension_reached
signal threshold_crossed(threshold_name, direction, threshold_value, current_value)
signal heat_level_changed(new_level, old_level)

signal police_alert_changed(level, old_level)
signal police_response(response_type)
signal wanted_level_changed(level, old_level)
signal police_alerted

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

signal faction_relationship_changed(faction_id, value)

signal quest_update(quest_id, value)

signal phone_call_incoming(caller_id, caller_data)
signal phone_call_answered(caller_id)
signal phone_call_declined(caller_id)
signal phone_call_ended(caller_id, duration)
signal phone_call_missed(caller_id)
signal phone_call_started(contact_id, contact)
signal phone_call_held(caller_id)
signal phone_call_resumed(caller_id)
signal phone_dialogue(caller_id, text)
signal phone_choices(caller_id, options)
signal phone_message_received(sender_id, message_data)
signal phone_power_changed(is_powered)
signal phone_silent_changed(is_silenced)
signal phone_gps_changed(is_tracked)

signal lighting_time_changed(current_time)
signal lighting_state_changed(state_name)
signal light_updated(light, color, energy)

signal player_objective_updated(title, description, objective_type, progress)

signal drug_effect_started(effect_name, duration)
signal drug_effect_ended(effect_name)
signal drug_effect_applied(effect_type, intensity)
signal drug_effect_parameter_changed(parameter, value)
signal game_over(reason)

signal surveillance_camera_activated(camera_id, camera_data)
signal surveillance_camera_deactivated(camera_id)
signal surveillance_mode_changed(is_active)
signal surveillance_feed_static(intensity)
signal surveillance_emergency_triggered(location_id, threat_level) 