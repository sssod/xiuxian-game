extends RefCounted
class_name UiStateAdapter


func from_room(room, last_result = null) -> Dictionary:
	var result_summary = "No result package yet."
	if last_result != null and not last_result.visible_logs.is_empty():
		result_summary = last_result.visible_logs[0]
	var character_summary = room.character_state.summary()
	var method_summary = _method_summary(room.character_state.method_states)
	var resource_summary = _resource_summary(room.character_state.inventory, room.character_state.active_resource_effects)
	var current_command = room.command_queue.current_command
	var command_summary = room.command_queue.command_label(current_command)
	var future_commands: Array[String] = []
	for command in room.command_queue.queued_commands:
		future_commands.append(room.command_queue.command_label(command))

	return {
		"room_name": room.room_name,
		"room_id": room.room_id,
		"mode": room.mode,
		"save_lineage": room.save_lineage,
		"active_state": room.active_state,
		"world_seed": room.world_seed,
		"world_time_label": room.world_time.label(),
		"speed_state": room.speed_state,
		"queue_empty": room.command_queue.is_empty(),
		"current_command_summary": command_summary,
		"future_command_summaries": future_commands,
		"future_command_count": room.command_queue.queued_commands.size(),
		"current_command_is_fallback": room.command_queue.is_current_fallback(),
		"managed_action_state": room.command_queue.managed_action_state.duplicate(true),
		"character_initialized": room.character_state.initialized,
		"character_summary": character_summary,
		"cultivation_state": room.character_state.cultivation_state.duplicate(true),
		"method_summary": method_summary,
		"method_states": room.character_state.method_states.duplicate(true),
		"resource_summary": resource_summary,
		"inventory": room.character_state.inventory.duplicate(true),
		"active_resource_effects": room.character_state.active_resource_effects.duplicate(true),
		"resource_use_log_count": room.character_state.resource_use_logs.size(),
		"result_summary": result_summary,
		"replay_entries": room.replay_log.entries.size(),
		"result_packages": room.result_history.size(),
		"last_recovery_status": room.last_recovery_status.duplicate(true),
	}


func _method_summary(method_states: Dictionary) -> String:
	if method_states.is_empty():
		return "No learned methods."
	var summaries: Array[String] = []
	for method_id in method_states.keys():
		var state = method_states.get(method_id, {})
		if typeof(state) != TYPE_DICTIONARY:
			continue
		summaries.append("%s L%d %.1f%%" % [
			state.get("display_name", method_id),
			int(state.get("mastery_level", 1)),
			float(state.get("mastery_norm", 0.0)) * 100.0,
		])
	return ", ".join(summaries)


func _resource_summary(inventory: Dictionary, active_resource_effects: Dictionary) -> String:
	var parts: Array[String] = []
	var items = inventory.get("items", {})
	if typeof(items) == TYPE_DICTIONARY:
		for item_id in items.keys():
			var item = items.get(item_id, {})
			if typeof(item) != TYPE_DICTIONARY:
				continue
			parts.append("%s x%d" % [
				item.get("display_name", item_id),
				int(item.get("quantity", 0)),
			])

	var active_parts: Array[String] = []
	for effect_id in active_resource_effects.keys():
		var effect = active_resource_effects.get(effect_id, {})
		if typeof(effect) != TYPE_DICTIONARY:
			continue
		active_parts.append("%s %.1fh %s" % [
			effect.get("display_name", effect_id),
			float(effect.get("remaining_effective_hours", 0.0)),
			effect.get("state", "active"),
		])

	if parts.is_empty():
		parts.append("no inventory resources")
	if active_parts.is_empty():
		active_parts.append("no active residual effects")
	return "Inventory: %s | Residual: %s" % [
		", ".join(parts),
		", ".join(active_parts),
	]
