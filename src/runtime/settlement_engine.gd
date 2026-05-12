extends RefCounted
class_name SettlementEngine

const RuntimeConstantsScript = preload("res://src/runtime/runtime_constants.gd")
const FixedSeedRandomScript = preload("res://src/runtime/fixed_seed_random.gd")
const ResultPackageScript = preload("res://src/runtime/result_package.gd")
const CommandQueueScript = preload("res://src/runtime/command_queue.gd")


func advance_one_hour(room, data_registry):
	room.active_state = RuntimeConstantsScript.ROOM_SETTLEMENT_IN_PROGRESS_STATE

	var before_time = room.world_time.to_dict()
	var command_setup = _ensure_current_command(room, data_registry, before_time)
	room.world_time.advance_hours(1)

	var rng = FixedSeedRandomScript.new(room.world_seed + room.rng_cursor)
	var rng_marker = rng.next_debug_marker()
	room.rng_cursor += 1

	var after_time = room.world_time.to_dict()
	var command_tick = _settle_current_command_hour(room, data_registry, after_time)
	var command_completion = _complete_or_continue_current_command(room, data_registry, after_time)
	var replay_entry = room.replay_log.append_event(
		"hour_tick",
		after_time,
		{
			"speed_state": room.speed_state,
			"rng_marker": rng_marker,
			"config_loaded": data_registry.config_loaded,
			"current_command": room.command_queue.current_command.duplicate(true),
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
	if not str(command_setup.get("visible_summary", "")).is_empty():
		visible_logs.append(str(command_setup.get("visible_summary", "")))
	if not str(command_tick.get("visible_summary", "")).is_empty():
		visible_logs.append(str(command_tick.get("visible_summary", "")))
	if not str(command_completion.get("visible_summary", "")).is_empty():
		visible_logs.append(str(command_completion.get("visible_summary", "")))

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
	if not command_setup.is_empty():
		debug_trace.append({
			"step": "command_setup",
			"data": command_setup.duplicate(true),
		})
	if not command_tick.is_empty():
		debug_trace.append({
			"step": "command_tick",
			"data": command_tick.duplicate(true),
		})
	if not command_completion.is_empty():
		debug_trace.append({
			"step": "command_completion",
			"data": command_completion.duplicate(true),
		})

	var replay_entries: Array[Dictionary] = []
	for entry in command_setup.get("replay_entries", []):
		if typeof(entry) == TYPE_DICTIONARY:
			replay_entries.append(entry.duplicate(true))
	for entry in command_tick.get("replay_entries", []):
		if typeof(entry) == TYPE_DICTIONARY:
			replay_entries.append(entry.duplicate(true))
	for entry in command_completion.get("replay_entries", []):
		if typeof(entry) == TYPE_DICTIONARY:
			replay_entries.append(entry.duplicate(true))
	replay_entries.append(replay_entry)

	var result = ResultPackageScript.create(
		room.next_result_id(),
		RuntimeConstantsScript.SOURCE_SYSTEM_ROOM,
		room.room_id,
		after_time,
		visible_logs,
		debug_trace,
		replay_entries,
		{
			"world_time": {
				"before": before_time,
				"after": after_time,
			},
			"command": {
				"setup": command_setup,
				"tick": command_tick,
				"completion": command_completion,
				"current_command": room.command_queue.current_command.duplicate(true),
				"queued_commands": room.command_queue.queued_commands.duplicate(true),
			},
			"character": room.character_state.cultivation_state.duplicate(true),
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


func validate_command(room, data_registry, command: Dictionary, phase: String = "enqueue") -> Dictionary:
	var action_type = str(command.get("action_type", ""))
	if action_type.is_empty():
		return _validation_error("missing_action_type", "Command action type is missing.", phase, command)

	if not room.character_state.initialized:
		return _validation_error("character_not_initialized", "Character is not initialized.", phase, command)

	var profile = data_registry.get_action_profile(action_type)
	if profile.is_empty():
		return _validation_error("unknown_action_type", "Action profile is not configured: %s" % action_type, phase, command)

	var resource_inputs = command.get("resource_inputs", [])
	if typeof(resource_inputs) == TYPE_ARRAY and not resource_inputs.is_empty():
		return _validation_error(
			"resource_inputs_not_supported",
			"MVP P3 active breathing does not support resource inputs until inventory exists.",
			phase,
			command
		)

	var planned_duration = int(command.get("planned_duration_hours", 1))
	var min_duration = int(profile.get("min_duration_hours", 1))
	var max_duration = int(profile.get("max_duration_hours", 0))
	if planned_duration < min_duration:
		return _validation_error(
			"duration_too_short",
			"Command duration is shorter than the action minimum.",
			phase,
			command,
			{"min_duration_hours": min_duration}
		)

	if max_duration > 0 and planned_duration > max_duration:
		return _validation_error(
			"duration_too_long",
			"Command duration exceeds the action maximum.",
			phase,
			command,
			{"max_duration_hours": max_duration}
		)

	if str(profile.get("compatible_hour_policy", "none")) != "none":
		var segment_id = str(room.character_state.cultivation_state.get("current_realm_segment_id", ""))
		if data_registry.get_realm_segment(segment_id).is_empty():
			return _validation_error(
				"missing_realm_segment",
				"Current realm segment is not configured: %s" % segment_id,
				phase,
				command
			)

	return {
		"ok": true,
		"code": "command_valid",
		"phase": phase,
		"command_id": command.get("command_id", ""),
		"action_type": action_type,
		"f1_eligible": bool(profile.get("f1_eligible", false)),
	}


func _ensure_current_command(room, data_registry, world_time: Dictionary) -> Dictionary:
	if room.command_queue.current_command.is_empty():
		return _promote_next_or_fallback(room, data_registry, world_time, "queue_empty")

	if room.command_queue.is_current_fallback():
		room.speed_state = RuntimeConstantsScript.SPEED_N1
		return {}

	var command = room.command_queue.current_command.duplicate(true)
	var validation = validate_command(room, data_registry, command, "execution")
	if not bool(validation.get("ok", false)):
		var skipped_entry = room.replay_log.append_event(
			"command_skipped",
			world_time,
			{
				"command": command.duplicate(true),
				"validation": validation.duplicate(true),
			}
		)
		room.command_queue.current_command = {}
		var fallback = _start_fallback(room, world_time, "validation_failed")
		var replay_entries: Array[Dictionary] = [skipped_entry]
		for entry in fallback.get("replay_entries", []):
			if typeof(entry) == TYPE_DICTIONARY:
				replay_entries.append(entry.duplicate(true))
		return {
			"ok": false,
			"code": "execution_validation_failed",
			"validation": validation,
			"visible_summary": "Command skipped before execution: %s. Fallback started." % command.get("action_type", ""),
			"replay_entries": replay_entries,
		}

	var state = str(command.get("state", CommandQueueScript.COMMAND_STATE_PENDING))
	if state == CommandQueueScript.COMMAND_STATE_PENDING:
		return _start_command(room, command, data_registry.get_action_profile(str(command.get("action_type", ""))), world_time)

	return {}


func _promote_next_or_fallback(room, data_registry, world_time: Dictionary, fallback_reason: String) -> Dictionary:
	var next_command = room.command_queue.pop_next_command()
	if next_command.is_empty():
		return _start_fallback(room, world_time, fallback_reason)

	var validation = validate_command(room, data_registry, next_command, "execution")
	if not bool(validation.get("ok", false)):
		var skipped_entry = room.replay_log.append_event(
			"command_skipped",
			world_time,
			{
				"command": next_command.duplicate(true),
				"validation": validation.duplicate(true),
			}
		)
		var fallback = _start_fallback(room, world_time, "validation_failed")
		var replay_entries: Array[Dictionary] = [skipped_entry]
		for entry in fallback.get("replay_entries", []):
			if typeof(entry) == TYPE_DICTIONARY:
				replay_entries.append(entry.duplicate(true))
		return {
			"ok": false,
			"code": "queued_command_validation_failed",
			"validation": validation,
			"visible_summary": "Queued command skipped: %s. Fallback started." % next_command.get("action_type", ""),
			"replay_entries": replay_entries,
		}

	return _start_command(room, next_command, data_registry.get_action_profile(str(next_command.get("action_type", ""))), world_time)


func _start_command(room, command: Dictionary, profile: Dictionary, world_time: Dictionary) -> Dictionary:
	command["state"] = CommandQueueScript.COMMAND_STATE_RUNNING
	command["started_world_day"] = int(world_time.get("world_day", 1))
	command["started_world_hour"] = int(world_time.get("world_hour", 0))
	command["f1_eligible"] = bool(profile.get("f1_eligible", false))
	command["last_validation"] = {
		"ok": true,
		"code": "execution_started",
	}
	room.command_queue.current_command = command.duplicate(true)

	var replay_entry = room.replay_log.append_event(
		"command_started",
		world_time,
		{
			"command": command.duplicate(true),
		}
	)

	return {
		"ok": true,
		"code": "command_started",
		"command_id": command.get("command_id", ""),
		"action_type": command.get("action_type", ""),
		"visible_summary": "Command started: %s for %d hour(s)." % [
			profile.get("display_name", command.get("action_type", "")),
			int(command.get("planned_duration_hours", 0)),
		],
		"replay_entries": [replay_entry],
	}


func _start_fallback(room, world_time: Dictionary, reason: String) -> Dictionary:
	var fallback = room.command_queue.create_fallback_command(
		reason,
		world_time,
		room.character_state.character_id,
		"low"
	)
	room.command_queue.current_command = fallback.duplicate(true)
	room.speed_state = RuntimeConstantsScript.SPEED_N1
	var replay_entry = room.replay_log.append_event(
		"fallback_started",
		world_time,
		{
			"fallback": fallback.duplicate(true),
		}
	)
	return {
		"ok": true,
		"code": "fallback_started",
		"fallback": fallback,
		"visible_summary": "Queue empty or invalid; fallback meditation is running at N1.",
		"replay_entries": [replay_entry],
	}


func _settle_current_command_hour(room, data_registry, world_time: Dictionary) -> Dictionary:
	if room.command_queue.current_command.is_empty():
		return {}

	var command = room.command_queue.current_command.duplicate(true)
	var action_type = str(command.get("action_type", ""))
	var profile = data_registry.get_action_profile(action_type)
	var segment_id = str(room.character_state.cultivation_state.get("current_realm_segment_id", ""))
	var segment = data_registry.get_realm_segment(segment_id)
	var tick_result = room.character_state.apply_cultivation_tick(segment, profile, command, world_time)

	command["elapsed_hours"] = int(command.get("elapsed_hours", 0)) + 1
	if bool(tick_result.get("ok", false)):
		command["compatible_elapsed_hours"] = int(command.get("compatible_elapsed_hours", 0)) + int(tick_result.get("compatible_hours", 0.0))
	room.command_queue.current_command = command.duplicate(true)

	var replay_entries: Array[Dictionary] = []
	var tick_entry = room.replay_log.append_event(
		"cultivation_tick",
		world_time,
		{
			"tick": tick_result.duplicate(true),
			"command": command.duplicate(true),
		}
	)
	replay_entries.append(tick_entry)

	var gate_result = {}
	if bool(tick_result.get("ok", false)) and bool(profile.get("can_trigger_minor_stage_advance", false)):
		var next_segment = data_registry.get_realm_segment(str(segment.get("next_segment_id", "")))
		gate_result = room.character_state.apply_minor_stage_gate(segment, next_segment, world_time)
		if bool(gate_result.get("advanced", false)):
			var advanced_entry = room.replay_log.append_event(
				"minor_stage_advanced",
				world_time,
				gate_result.duplicate(true)
			)
			replay_entries.append(advanced_entry)
		elif bool(gate_result.get("bottleneck_reached", false)):
			var bottleneck_entry = room.replay_log.append_event(
				"cultivation_bottleneck_reached",
				world_time,
				gate_result.duplicate(true)
			)
			replay_entries.append(bottleneck_entry)

	var visible_summary = str(tick_result.get("visible_summary", ""))
	if bool(gate_result.get("advanced", false)):
		visible_summary += " Minor stage advanced to %s." % gate_result.get("to_minor_stage", "")
	elif bool(gate_result.get("bottleneck_reached", false)):
		visible_summary += " Bottleneck reached; major breakthrough must be started explicitly."

	return {
		"ok": tick_result.get("ok", false),
		"code": tick_result.get("code", "cultivation_tick_settled"),
		"command_id": command.get("command_id", ""),
		"action_type": action_type,
		"tick": tick_result,
		"gate": gate_result,
		"visible_summary": visible_summary,
		"replay_entries": replay_entries,
	}


func _complete_or_continue_current_command(room, data_registry, world_time: Dictionary) -> Dictionary:
	if room.command_queue.current_command.is_empty() or room.command_queue.is_current_fallback():
		return {}

	var command = room.command_queue.current_command.duplicate(true)
	var planned_duration = int(command.get("planned_duration_hours", 1))
	var elapsed = int(command.get("elapsed_hours", 0))
	if elapsed < planned_duration:
		return {}

	command["state"] = CommandQueueScript.COMMAND_STATE_COMPLETED
	command["completed_world_day"] = int(world_time.get("world_day", 1))
	command["completed_world_hour"] = int(world_time.get("world_hour", 0))
	var completed_entry = room.replay_log.append_event(
		"command_completed",
		world_time,
		{
			"command": command.duplicate(true),
		}
	)
	room.command_queue.current_command = {}

	var next_setup = _promote_next_or_fallback(room, data_registry, world_time, "queue_empty")
	var replay_entries: Array[Dictionary] = [completed_entry]
	for entry in next_setup.get("replay_entries", []):
		if typeof(entry) == TYPE_DICTIONARY:
			replay_entries.append(entry.duplicate(true))

	return {
		"ok": true,
		"code": "command_completed",
		"command": command,
		"next_setup": next_setup,
		"visible_summary": "Command completed: %s. %s" % [
			command.get("action_type", ""),
			next_setup.get("visible_summary", ""),
		],
		"replay_entries": replay_entries,
	}


func _validation_error(
		code: String,
		error: String,
		phase: String,
		command: Dictionary,
		extra: Dictionary = {}
) -> Dictionary:
	var result = {
		"ok": false,
		"code": code,
		"error": error,
		"phase": phase,
		"command_id": command.get("command_id", ""),
		"action_type": command.get("action_type", ""),
	}
	for key in extra.keys():
		result[key] = extra.get(key)
	return result
