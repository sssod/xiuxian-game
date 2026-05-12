extends RefCounted
class_name UiStateAdapter


func from_room(room, last_result = null) -> Dictionary:
	var result_summary = "No result package yet."
	if last_result != null and not last_result.visible_logs.is_empty():
		result_summary = last_result.visible_logs[0]

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
		"result_summary": result_summary,
		"replay_entries": room.replay_log.entries.size(),
		"result_packages": room.result_history.size(),
		"last_recovery_status": room.last_recovery_status.duplicate(true),
	}
