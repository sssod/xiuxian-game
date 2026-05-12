extends RefCounted
class_name SettlementEngine

const RuntimeConstantsScript = preload("res://src/runtime/runtime_constants.gd")
const FixedSeedRandomScript = preload("res://src/runtime/fixed_seed_random.gd")
const ResultPackageScript = preload("res://src/runtime/result_package.gd")


func advance_one_hour(room, data_registry):
	room.active_state = RuntimeConstantsScript.ROOM_SETTLEMENT_IN_PROGRESS_STATE

	var before_time = room.world_time.to_dict()
	room.world_time.advance_hours(1)

	var rng = FixedSeedRandomScript.new(room.world_seed + room.rng_cursor)
	var rng_marker = rng.next_debug_marker()
	room.rng_cursor += 1

	var after_time = room.world_time.to_dict()
	var replay_entry = room.replay_log.append_event(
		"hour_tick",
		after_time,
		{
			"speed_state": room.speed_state,
			"rng_marker": rng_marker,
			"config_loaded": data_registry.config_loaded,
		}
	)

	var visible_logs: Array[String] = [
		"World time advanced from Day %d Hour %02d to Day %d Hour %02d." % [
			before_time.get("world_day", 1),
			before_time.get("world_hour", 0),
			after_time.get("world_day", 1),
			after_time.get("world_hour", 0),
		],
	]

	var debug_trace: Array[Dictionary] = [
		{
			"step": "hour_tick",
			"before": before_time,
			"after": after_time,
			"speed_state": room.speed_state,
			"rng_marker": rng_marker,
			"config_path": data_registry.config_path,
		},
	]

	var result = ResultPackageScript.create(
		room.next_result_id(),
		RuntimeConstantsScript.SOURCE_SYSTEM_ROOM,
		room.room_id,
		after_time,
		visible_logs,
		debug_trace,
		[replay_entry],
		{
			"world_time": {
				"before": before_time,
				"after": after_time,
			}
		}
	)
	room.active_state = RuntimeConstantsScript.ROOM_ACTIVE_STATE
	room.result_history.append(result.to_dict())
	return result


func advance_hours(room, data_registry, hours: int, speed_state: String = "") -> Array:
	var safe_hours = hours
	if safe_hours < 0:
		safe_hours = 0

	if not speed_state.is_empty() and room.speed_state != speed_state:
		var previous_speed = room.speed_state
		room.speed_state = speed_state
		room.replay_log.append_event(
			"speed_state_changed",
			room.world_time.to_dict(),
			{
				"before": previous_speed,
				"after": room.speed_state,
				"reason": "advance_hours",
			}
		)

	var results: Array = []
	for _i in range(safe_hours):
		results.append(advance_one_hour(room, data_registry))
	return results
