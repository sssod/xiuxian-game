extends RefCounted
class_name UiStateAdapter


func from_room(room, last_result = null) -> Dictionary:
	var result_summary = "No result package yet."
	if last_result != null and not last_result.visible_logs.is_empty():
		result_summary = last_result.visible_logs[0]
	var character_summary = room.character_state.summary()
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
		"character_initialized": room.character_state.initialized,
		"character_summary": character_summary,
		"cultivation_state": room.character_state.cultivation_state.duplicate(true),
		"result_summary": result_summary,
		"replay_entries": room.replay_log.entries.size(),
		"result_packages": room.result_history.size(),
		"last_recovery_status": room.last_recovery_status.duplicate(true),
	}
