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
				"managed_action_state": room.command_queue.managed_action_state.duplicate(true),
			},
			"character": room.character_state.cultivation_state.duplicate(true),
			"method_states": room.character_state.method_states.duplicate(true),
			"inventory": room.character_state.inventory.duplicate(true),
			"active_resource_effects": room.character_state.active_resource_effects.duplicate(true),
			"resource_use_logs": room.character_state.resource_use_logs.duplicate(true),
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

	var normalized_resource_inputs: Array[Dictionary] = []
	var resource_inputs = command.get("resource_inputs", [])
	if typeof(resource_inputs) == TYPE_ARRAY and not resource_inputs.is_empty():
		var resource_validation = _validate_resource_inputs(room, data_registry, command, profile)
		if not bool(resource_validation.get("ok", false)):
			return _validation_error(
				str(resource_validation.get("code", "resource_inputs_invalid")),
				str(resource_validation.get("error", "Resource input validation failed.")),
				phase,
				command,
				resource_validation
			)
		normalized_resource_inputs = resource_validation.get("normalized_resource_inputs", [])

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

	if str(profile.get("settlement_kind", "cultivation")) == "method_study":
		var target_method_id = str(command.get("target_method_id", profile.get("default_target_method_id", "")))
		if target_method_id.is_empty():
			return _validation_error(
				"missing_method_study_target",
				"Method study requires a learned target method.",
				phase,
				command
			)
		if not room.character_state.has_method_state(target_method_id):
			return _validation_error(
				"method_state_not_found",
				"Method study target is not learned: %s" % target_method_id,
				phase,
				command,
				{"target_method_id": target_method_id}
			)

	return {
		"ok": true,
		"code": "command_valid",
		"phase": phase,
		"command_id": command.get("command_id", ""),
		"action_type": action_type,
		"f1_eligible": bool(profile.get("f1_eligible", false)),
		"normalized_resource_inputs": normalized_resource_inputs,
	}


func _ensure_current_command(room, data_registry, world_time: Dictionary) -> Dictionary:
	if room.command_queue.current_command.is_empty():
		return _promote_next_or_fallback(room, data_registry, world_time, "queue_empty")

	if room.command_queue.is_current_fallback():
		room.speed_state = RuntimeConstantsScript.SPEED_N1
		return {}

	var command = room.command_queue.current_command.duplicate(true)
	var state = str(command.get("state", CommandQueueScript.COMMAND_STATE_PENDING))
	if state != CommandQueueScript.COMMAND_STATE_PENDING:
		return {}

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

	var resource_activation = room.character_state.activate_resource_inputs(command, world_time)
	if not bool(resource_activation.get("ok", false)):
		return {
			"ok": false,
			"code": resource_activation.get("code", "resource_activation_failed"),
			"error": resource_activation.get("error", ""),
			"visible_summary": "Command failed to start because resource input activation failed.",
			"replay_entries": [],
		}
	command["resource_inputs"] = resource_activation.get("resource_inputs", [])
	room.command_queue.current_command = command.duplicate(true)
	if str(command.get("action_type", "")) == CommandQueueScript.ACTION_MANAGED_ACTION:
		room.command_queue.managed_action_state = {
			"command_id": command.get("command_id", ""),
			"character_id": command.get("character_id", ""),
			"started_world_day": int(world_time.get("world_day", 1)),
			"started_world_hour": int(world_time.get("world_hour", 0)),
			"planned_duration_hours": int(command.get("planned_duration_hours", 0)),
			"policy": "explicit_low_interaction",
			"f1_eligible": bool(profile.get("f1_eligible", false)),
		}
	elif not room.command_queue.managed_action_state.is_empty():
		room.command_queue.managed_action_state = {}

	var replay_entry = room.replay_log.append_event(
		"command_started",
		world_time,
		{
			"command": command.duplicate(true),
			"resource_activation": resource_activation.duplicate(true),
		}
	)

	return {
		"ok": true,
		"code": "command_started",
		"command_id": command.get("command_id", ""),
		"action_type": command.get("action_type", ""),
		"resource_activation": resource_activation,
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
	var settlement_kind = str(profile.get("settlement_kind", "cultivation"))
	var tick_event_name = "cultivation_tick"
	var tick_result = {}
	if settlement_kind == "method_study":
		tick_event_name = "method_study_tick"
		tick_result = room.character_state.apply_method_study_tick(profile, command, world_time)
	else:
		tick_result = room.character_state.apply_cultivation_tick(segment, profile, command, world_time)

	command["elapsed_hours"] = int(command.get("elapsed_hours", 0)) + 1
	if bool(tick_result.get("ok", false)):
		command["compatible_elapsed_hours"] = int(command.get("compatible_elapsed_hours", 0)) + int(tick_result.get("compatible_hours", 0.0))
	room.command_queue.current_command = command.duplicate(true)

	var replay_entries: Array[Dictionary] = []
	var tick_entry = room.replay_log.append_event(
		tick_event_name,
		world_time,
		{
			"tick": tick_result.duplicate(true),
			"command": command.duplicate(true),
		}
	)
	replay_entries.append(tick_entry)

	var gate_result = {}
	if settlement_kind != "method_study" and bool(tick_result.get("ok", false)) and bool(profile.get("can_trigger_minor_stage_advance", false)):
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
	var managed_action_completed = false
	if str(command.get("action_type", "")) == CommandQueueScript.ACTION_MANAGED_ACTION:
		managed_action_completed = true
		room.command_queue.managed_action_state = {}
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
		"managed_action_completed": managed_action_completed,
		"next_setup": next_setup,
		"visible_summary": "Command completed: %s. %s" % [
			command.get("action_type", ""),
			next_setup.get("visible_summary", ""),
		],
		"replay_entries": replay_entries,
	}


func _validate_resource_inputs(room, data_registry, command: Dictionary, profile: Dictionary) -> Dictionary:
	var resource_inputs = command.get("resource_inputs", [])
	if typeof(resource_inputs) != TYPE_ARRAY:
		return {
			"ok": false,
			"code": "invalid_resource_inputs",
			"error": "Command resource_inputs must be an array.",
		}

	if not bool(profile.get("resource_inputs_supported", false)):
		return {
			"ok": false,
			"code": "resource_inputs_not_supported",
			"error": "This action profile does not support resource inputs.",
			"resource_input_count": resource_inputs.size(),
		}

	var max_inputs = int(profile.get("resource_slot_count", 0))
	if max_inputs < 1:
		return {
			"ok": false,
			"code": "resource_inputs_not_supported",
			"error": "This action has no resource input slots.",
			"resource_input_count": resource_inputs.size(),
		}

	if resource_inputs.size() > max_inputs:
		return {
			"ok": false,
			"code": "resource_input_slots_exceeded",
			"error": "Resource input count exceeds the action slot count.",
			"resource_input_count": resource_inputs.size(),
			"resource_slot_count": max_inputs,
		}

	var normalized: Array[Dictionary] = []
	for index in range(resource_inputs.size()):
		var input = resource_inputs[index]
		if typeof(input) != TYPE_DICTIONARY:
			return {
				"ok": false,
				"code": "invalid_resource_input",
				"error": "Each resource input must be a dictionary.",
			}

		var resource_item_template_id = str(input.get("resource_item_template_id", input.get("resource_id", "")))
		var inventory_item = room.character_state.get_inventory_item(resource_item_template_id)
		if inventory_item.is_empty():
			return {
				"ok": false,
				"code": "resource_not_owned",
				"error": "Resource input is not available in the character inventory.",
				"resource_item_template_id": resource_item_template_id,
			}
		var effect_template_id = str(input.get("resource_effect_template_id", inventory_item.get("resource_effect_template_id", "")))
		var effect_template = data_registry.get_resource_effect_template(effect_template_id)
		if effect_template.is_empty():
			return {
				"ok": false,
				"code": "missing_resource_effect_template",
				"error": "Resource effect template is not configured: %s" % effect_template_id,
				"resource_item_template_id": resource_item_template_id,
				"resource_effect_template_id": effect_template_id,
			}

		var input_validation = room.character_state.validate_resource_input_binding(
			input,
			inventory_item,
			effect_template,
			profile,
			command
		)
		if not bool(input_validation.get("ok", false)):
			return input_validation

		normalized.append(_normalized_resource_binding(input, inventory_item, effect_template, command, index))

	return {
		"ok": true,
		"code": "resource_inputs_valid",
		"normalized_resource_inputs": normalized,
	}


func _normalized_resource_binding(
		raw_input: Dictionary,
		inventory_item: Dictionary,
		effect_template: Dictionary,
		command: Dictionary,
		index: int
) -> Dictionary:
	var existing_binding_id = str(raw_input.get("binding_id", ""))
	var binding_id = existing_binding_id
	if binding_id.is_empty():
		binding_id = "%s_resource_%02d" % [command.get("command_id", "cmd"), index + 1]
	var quality_factor = float(raw_input.get("resource_quality_factor", effect_template.get("resource_quality_factor", 1.0)))
	var state_factor = float(raw_input.get("state_factor", effect_template.get("state_factor", 1.0)))
	var unit_effect_rate = float(effect_template.get("unit_effect_rate", 0.0))
	var actual_unit_effect_rate = unit_effect_rate * quality_factor * state_factor
	return {
		"binding_id": binding_id,
		"command_id": command.get("command_id", ""),
		"character_id": command.get("character_id", ""),
		"source_container_id": inventory_item.get("source_container_id", ""),
		"resource_item_ref": raw_input.get("resource_item_ref", inventory_item.get("resource_item_template_id", "")),
		"resource_item_template_id": inventory_item.get("resource_item_template_id", ""),
		"resource_effect_template_id": effect_template.get("resource_effect_template_id", ""),
		"display_name": inventory_item.get("display_name", effect_template.get("display_name", "")),
		"quantity": int(raw_input.get("quantity", 1)),
		"effect_type": effect_template.get("effect_type", ""),
		"use_mode": effect_template.get("use_mode", "action_resource_input"),
		"compatible_action_tags": effect_template.get("compatible_action_tags", []).duplicate(true),
		"compatible_context_tags": effect_template.get("compatible_context_tags", []).duplicate(true),
		"effect_tick_mode": effect_template.get("effect_tick_mode", "compatible_action_hours"),
		"unit_effect_rate": unit_effect_rate,
		"actual_unit_effect_rate": actual_unit_effect_rate,
		"resource_quality_factor": quality_factor,
		"state_factor": state_factor,
		"resource_to_cp_ratio": float(effect_template.get("resource_to_cp_ratio", 1.0)),
		"pressure_per_applied_hour": float(effect_template.get("pressure_per_applied_hour", 0.0)),
		"max_effective_hours": float(effect_template.get("max_effective_hours", 0.0)),
		"activation_policy": effect_template.get("activation_policy", "consume_on_action_start"),
		"residual_policy": effect_template.get("residual_policy", "stable_suspend"),
		"residual_stability_hours": float(effect_template.get("residual_stability_hours", 0.0)),
		"can_be_settled_by_consolidation": bool(effect_template.get("can_be_settled_by_consolidation", false)),
		"settlement_policy": effect_template.get("settlement_policy", "none"),
		"stacking_group": effect_template.get("stacking_group", effect_template.get("resource_effect_template_id", "")),
		"max_same_group_active": int(effect_template.get("max_same_group_active", 1)),
		"created_world_day": int(command.get("created_world_day", 1)),
		"created_world_hour": int(command.get("created_world_hour", 0)),
		"consumed_at_world_day": int(raw_input.get("consumed_at_world_day", 0)),
		"consumed_at_world_hour": int(raw_input.get("consumed_at_world_hour", 0)),
		"active_effect_ref": str(raw_input.get("active_effect_ref", "")),
		"resource_use_log_refs": raw_input.get("resource_use_log_refs", []).duplicate(true) if typeof(raw_input.get("resource_use_log_refs", [])) == TYPE_ARRAY else [],
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
