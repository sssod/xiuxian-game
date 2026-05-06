extends RefCounted

const DemoConstants = preload("res://scripts/core/demo_constants.gd")
const PersonalActionInstruction = preload("res://scripts/core/personal_action_instruction.gd")
const ActionValidator = preload("res://scripts/core/action_validator.gd")
const ContentLoader = preload("res://scripts/core/content_loader.gd")
const LogUtils = preload("res://scripts/core/log_utils.gd")

static func settle_turn(runtime: Dictionary, content: Dictionary, player_id := DemoConstants.LOCAL_PLAYER_ID) -> Dictionary:
	var room_state: Dictionary = runtime.get("room_state", {})
	var turn_id := int(room_state.get("current_turn_id", 1))
	var world_day := int(room_state.get("current_world_day", 1))
	var world_hour := int(room_state.get("current_world_hour", 0))
	var turn_config: Dictionary = room_state.get("turn_config", DemoConstants.default_turn_config())
	var turn_total_hours := DemoConstants.turn_total_hours(turn_config)
	var original_queue: Array = runtime.get("pending_player_decisions", {}).get(player_id, [])
	var validation := ActionValidator.validate_queue(runtime, content, player_id, original_queue)

	if not validation["ok"]:
		return _validation_failed_result(turn_id, world_day, world_hour, player_id, validation)

	var actual_queue := _actual_queue_for_settlement(original_queue, turn_total_hours)
	var actual_entries := []
	var skipped_actions := []
	var interruptions := []
	var visible_logs := [
		LogUtils.visible("turn_settlement_started", "第 %d 回合开始结算。" % turn_id, turn_id, world_day, world_hour)
	]
	var debug_logs := []
	var hidden_world_logs := []
	var rumor_entries := []
	var character_deltas := {}
	var node_deltas := {}
	var sect_deltas := {}
	var resource_slot_deltas := {}
	var method_state_deltas := {}
	var asset_container_deltas := {}
	var item_stack_deltas := {}
	var item_instance_deltas := {}
	var active_resource_effect_deltas := {}
	var asset_log_entries := []
	var character_log_entries := []
	var sect_log_entries := []
	var sect_ai_outcomes := []
	var remaining_hours := turn_total_hours
	var cursor_world_hour := world_hour

	for action in actual_queue:
		if typeof(action) != TYPE_DICTIONARY:
			continue
		if remaining_hours <= 0:
			var skipped_entry := _skipped_entry(action, "turn_budget_exhausted")
			actual_entries.append(skipped_entry)
			skipped_actions.append(skipped_entry)
			continue

		var action_id := str(action.get("action_id", ""))
		if action_id == "move_to_node":
			var move_result := _settle_move_action(runtime, content, action, turn_id, world_day, cursor_world_hour, remaining_hours, character_deltas, node_deltas)
			remaining_hours = int(move_result["remaining_hours"])
			cursor_world_hour = int(move_result["cursor_world_hour"])
			actual_entries.append_array(move_result["actual_entries"])
			interruptions.append_array(move_result["interruptions"])
			visible_logs.append_array(move_result["visible_logs"])
			hidden_world_logs.append_array(move_result["hidden_world_logs"])
		elif action_id == "ask_for_rumor":
			var rumor_result := _settle_node_action(runtime, content, action, turn_id, world_day, cursor_world_hour, remaining_hours, character_deltas, node_deltas, "node_rumor")
			remaining_hours = int(rumor_result["remaining_hours"])
			cursor_world_hour = int(rumor_result["cursor_world_hour"])
			actual_entries.append(rumor_result["actual_entry"])
			visible_logs.append_array(rumor_result["visible_logs"])
			hidden_world_logs.append_array(rumor_result["hidden_world_logs"])
			rumor_entries.append_array(rumor_result["rumor_entries"])
		elif action_id == "gather_resource":
			var gather_result := _settle_gather_resource_action(runtime, content, action, turn_id, world_day, cursor_world_hour, remaining_hours, character_deltas, node_deltas, resource_slot_deltas, asset_container_deltas, item_stack_deltas, asset_log_entries)
			remaining_hours = int(gather_result["remaining_hours"])
			cursor_world_hour = int(gather_result["cursor_world_hour"])
			actual_entries.append(gather_result["actual_entry"])
			visible_logs.append_array(gather_result["visible_logs"])
			hidden_world_logs.append_array(gather_result["hidden_world_logs"])
		elif action_id == "join_sect_event":
			var join_result := _settle_join_sect_action(runtime, content, action, turn_id, world_day, cursor_world_hour, remaining_hours, character_deltas, node_deltas, asset_container_deltas, item_stack_deltas, item_instance_deltas, asset_log_entries, character_log_entries)
			remaining_hours = int(join_result["remaining_hours"])
			cursor_world_hour = int(join_result["cursor_world_hour"])
			actual_entries.append(join_result["actual_entry"])
			visible_logs.append_array(join_result["visible_logs"])
			hidden_world_logs.append_array(join_result["hidden_world_logs"])
			rumor_entries.append_array(join_result["rumor_entries"])
		elif action_id == "study_method":
			var study_result := _settle_study_method_action(runtime, content, action, turn_id, world_day, cursor_world_hour, remaining_hours, character_deltas, method_state_deltas, character_log_entries)
			remaining_hours = int(study_result["remaining_hours"])
			cursor_world_hour = int(study_result["cursor_world_hour"])
			actual_entries.append(study_result["actual_entry"])
			visible_logs.append_array(study_result["visible_logs"])
		elif action_id == "active_cultivation":
			var cultivation_result := _settle_active_cultivation_action(runtime, content, action, turn_id, world_day, cursor_world_hour, remaining_hours, character_deltas, item_stack_deltas, active_resource_effect_deltas, asset_log_entries, character_log_entries)
			remaining_hours = int(cultivation_result["remaining_hours"])
			cursor_world_hour = int(cultivation_result["cursor_world_hour"])
			actual_entries.append(cultivation_result["actual_entry"])
			visible_logs.append_array(cultivation_result["visible_logs"])
		elif action_id == "request_sect_resource":
			var request_result := _settle_request_sect_resource_action(runtime, content, action, turn_id, world_day, cursor_world_hour, remaining_hours, character_deltas, sect_deltas, asset_container_deltas, item_stack_deltas, asset_log_entries, sect_log_entries)
			remaining_hours = int(request_result["remaining_hours"])
			cursor_world_hour = int(request_result["cursor_world_hour"])
			actual_entries.append(request_result["actual_entry"])
			visible_logs.append_array(request_result["visible_logs"])
		else:
			var generic_result := _settle_simple_time_action(action, turn_id, world_day, cursor_world_hour, remaining_hours)
			remaining_hours = int(generic_result["remaining_hours"])
			cursor_world_hour = int(generic_result["cursor_world_hour"])
			actual_entries.append(generic_result["actual_entry"])
			visible_logs.append_array(generic_result["visible_logs"])

	if remaining_hours > 0:
		actual_entries.append({
			"instruction_id": "unallocated_time_rest",
			"action_id": "rest_or_guard",
			"planned_duration_hours": remaining_hours,
			"actual_consumed_hours": remaining_hours,
			"status": "completed",
			"skip_or_interrupt_reason": "unallocated_time_filled_by_rest",
			"started_world_hour": cursor_world_hour,
			"ended_world_hour": cursor_world_hour + remaining_hours
		})
		cursor_world_hour += remaining_hours
		remaining_hours = 0

	var sect_ai_result := _settle_sect_ai(runtime, content, turn_id, world_day, world_hour, turn_total_hours, sect_deltas, node_deltas, resource_slot_deltas)
	sect_ai_outcomes.append_array(sect_ai_result["outcomes"])
	visible_logs.append_array(sect_ai_result["visible_logs"])
	hidden_world_logs.append_array(sect_ai_result["hidden_world_logs"])
	rumor_entries.append_array(sect_ai_result["rumor_entries"])
	sect_log_entries.append_array(sect_ai_result["sect_log_entries"])

	var next_world_hour := world_hour + turn_total_hours
	var next_world_day := world_day + int(turn_config.get("turn_duration_days", DemoConstants.DEFAULT_TURN_DURATION_DAYS))
	var next_turn_id := turn_id + 1
	var next_macro_period_id := DemoConstants.macro_period_for_world_day(next_world_day)
	var summary := {
		"turn_id": turn_id,
		"player_id": player_id,
		"planned_actions": _summarize_actions(original_queue),
		"actual_actions": actual_entries,
		"turn_total_hours": turn_total_hours,
		"consumed_hours": turn_total_hours,
		"skipped_actions": skipped_actions,
		"interruptions": interruptions,
		"notes": _summary_notes(interruptions, rumor_entries, sect_ai_outcomes)
	}

	for entry in actual_entries:
		visible_logs.append(LogUtils.visible("action_result", "行动 %s 实际消耗 %d 小时。" % [entry["action_id"], entry["actual_consumed_hours"]], turn_id, world_day, int(entry.get("ended_world_hour", next_world_hour))))
	visible_logs.append(LogUtils.visible("turn_settlement_finished", "第 %d 回合结束，世界时间推进到第 %d 天。" % [turn_id, next_world_day], turn_id, next_world_day, next_world_hour))
	debug_logs.append(LogUtils.debug("s1_package_created", "ResultPackage generated by Phase D settlement.", turn_id, next_world_hour, {
		"actual_entries": actual_entries.size(),
		"interruptions": interruptions.size(),
		"node_delta_count": node_deltas.size(),
		"sect_delta_count": sect_deltas.size(),
		"resource_slot_delta_count": resource_slot_deltas.size(),
		"method_delta_count": method_state_deltas.size(),
		"asset_log_count": asset_log_entries.size(),
		"sect_ai_outcome_count": sect_ai_outcomes.size()
	}))

	var package := {
		"package_id": "s1_turn_%03d_phase_d" % turn_id,
		"source_system": "S1_settlement_bus",
		"turn_id": turn_id,
		"world_seed": room_state.get("world_seed", DemoConstants.DEFAULT_WORLD_SEED),
		"state_deltas": {
			"room_state": {
				"current_turn_id": next_turn_id,
				"current_world_day": next_world_day,
				"current_world_hour": next_world_hour,
				"current_hour_tick": next_world_hour,
				"current_macro_period_id": next_macro_period_id,
				"current_phase": "turn_end",
				"settlement_status": "completed",
				"world_state_version_increment": 1
				},
				"character_states": character_deltas,
				"node_states": node_deltas,
				"sect_states": sect_deltas,
				"resource_slot_states": resource_slot_deltas,
				"method_states": method_state_deltas,
				"asset_containers": asset_container_deltas,
			"item_stacks": item_stack_deltas,
			"item_instances": item_instance_deltas,
				"active_resource_effects": active_resource_effect_deltas,
				"asset_log_entries": asset_log_entries,
				"character_log_entries": character_log_entries,
				"sect_log_entries": sect_log_entries,
				"rumor_pool_entries": rumor_entries,
			"clear_pending_player_decisions": [player_id],
			"player_lock_state": {
				"player_id": player_id,
				"lock_state": "unlocked"
			}
		},
		"visible_logs": visible_logs,
		"hidden_world_logs": hidden_world_logs,
		"debug_logs": debug_logs,
			"resource_changes": asset_log_entries,
			"sect_ai_outcomes": sect_ai_outcomes,
			"errors": [],
			"original_vs_actual_summary": summary
	}

	var replay := {
		"replay_id": "turn_%03d_seed_%s" % [turn_id, str(room_state.get("world_seed", DemoConstants.DEFAULT_WORLD_SEED))],
		"schema_version": DemoConstants.SCHEMA_VERSION,
		"content_version": DemoConstants.CONTENT_VERSION,
		"turn_id": turn_id,
		"rng_seed": room_state.get("world_seed", DemoConstants.DEFAULT_WORLD_SEED),
		"input_actions": original_queue,
		"result_packages": [package],
		"original_vs_actual_summary": summary,
		"state_before": {
			"current_turn_id": turn_id,
			"current_world_day": world_day,
			"current_world_hour": world_hour,
			"world_state_version": room_state.get("world_state_version", 0)
		},
		"state_after": {
			"current_turn_id": next_turn_id,
			"current_world_day": next_world_day,
			"current_world_hour": next_world_hour,
			"world_state_version": int(room_state.get("world_state_version", 0)) + 1,
				"character_deltas": character_deltas,
				"node_deltas": node_deltas,
				"sect_deltas": sect_deltas,
				"resource_slot_deltas": resource_slot_deltas,
				"method_state_deltas": method_state_deltas,
			"item_stack_deltas": item_stack_deltas,
			"active_resource_effect_deltas": active_resource_effect_deltas
		},
		"event_outcomes": interruptions
	}

	return {
		"ok": true,
		"validation": validation,
		"packages": [package],
		"turn_replay": replay
	}

static func _settle_move_action(runtime: Dictionary, content: Dictionary, action: Dictionary, turn_id: int, world_day: int, cursor_world_hour: int, remaining_hours: int, character_deltas: Dictionary, node_deltas: Dictionary) -> Dictionary:
	var actor_id := str(action.get("actor_id", ""))
	var from_node := _current_location_for_actor(runtime, character_deltas, actor_id)
	var target_node := _target_node(action)
	var route := ContentLoader.route_between(content, from_node, target_node)
	var travel_hours := int(route.get("base_travel_hours", action.get("planned_duration_hours", 0)))
	var consumed_hours = min(travel_hours, remaining_hours)
	var actual_entries := []
	var interruptions := []
	var visible_logs := []
	var hidden_world_logs := []

	if consumed_hours < travel_hours:
		actual_entries.append(_actual_entry(action, travel_hours, consumed_hours, "interrupted", "turn_budget_exhausted_before_arrival", cursor_world_hour, cursor_world_hour + consumed_hours))
		return {
			"remaining_hours": remaining_hours - consumed_hours,
			"cursor_world_hour": cursor_world_hour + consumed_hours,
			"actual_entries": actual_entries,
			"interruptions": interruptions,
			"visible_logs": visible_logs,
			"hidden_world_logs": hidden_world_logs
		}

	_set_character_delta(character_deltas, actor_id, {"current_location": target_node})
	_set_node_delta(node_deltas, target_node, {"visibility_state": "known"})
	actual_entries.append(_actual_entry(action, travel_hours, consumed_hours, "completed", "", cursor_world_hour, cursor_world_hour + consumed_hours))
	visible_logs.append(LogUtils.visible("movement_completed", "从%s抵达%s，路线耗时%d小时。" % [_node_name(runtime, content, from_node), _node_name(runtime, content, target_node), consumed_hours], turn_id, world_day, cursor_world_hour + consumed_hours))

	var new_remaining: int = remaining_hours - int(consumed_hours)
	var new_cursor: int = cursor_world_hour + int(consumed_hours)
	var event: Dictionary = _movement_event_for_route(content, route)
	if not event.is_empty() and new_remaining > 0:
		var event_hours: int = int(min(int(event.get("consumed_hours", 0)), new_remaining))
		var event_entry := {
			"instruction_id": "%s__%s" % [action.get("instruction_id", "move_to_node"), event.get("id", "event")],
			"action_id": "inserted_event:%s" % event.get("id", "unknown_event"),
			"planned_duration_hours": int(event.get("consumed_hours", 0)),
			"actual_consumed_hours": event_hours,
			"status": "completed",
			"skip_or_interrupt_reason": "movement_event_delay",
			"started_world_hour": new_cursor,
			"ended_world_hour": new_cursor + event_hours
		}
		actual_entries.append(event_entry)
		interruptions.append({
			"event_id": event.get("id", ""),
			"source_instruction_id": action.get("instruction_id", ""),
			"consumed_hours": event_hours,
			"effect": "delay_following_actions"
		})
		_set_node_delta(node_deltas, target_node, {"append_state_tags": ["recent_minor_delay"]})
		visible_logs.append(LogUtils.visible("inserted_event", "%s：%s，后续行动顺延%d小时。" % [event.get("display_name", "插入事件"), event.get("description", "途中出现延误。"), event_hours], turn_id, world_day, new_cursor + event_hours))
		hidden_world_logs.append(LogUtils.visible("world_route_event", "%s 发生移动延误事件。" % _node_name(runtime, content, target_node), turn_id, world_day, new_cursor + event_hours))
		new_remaining -= event_hours
		new_cursor += event_hours

	return {
		"remaining_hours": new_remaining,
		"cursor_world_hour": new_cursor,
		"actual_entries": actual_entries,
		"interruptions": interruptions,
		"visible_logs": visible_logs,
		"hidden_world_logs": hidden_world_logs
	}

static func _settle_node_action(runtime: Dictionary, content: Dictionary, action: Dictionary, turn_id: int, world_day: int, cursor_world_hour: int, remaining_hours: int, character_deltas: Dictionary, node_deltas: Dictionary, trigger_scope: String) -> Dictionary:
	var planned_hours := int(action.get("planned_duration_hours", 0))
	var consumed_hours = min(planned_hours, remaining_hours)
	var ended_hour: int = cursor_world_hour + int(consumed_hours)
	var node_id := _target_node(action)
	var status := "completed"
	var reason := ""
	if consumed_hours < planned_hours:
		status = "partial"
		reason = "event_delay_or_budget_exhausted"

	var actual_entry := _actual_entry(action, planned_hours, consumed_hours, status, reason, cursor_world_hour, ended_hour)
	var visible_logs := []
	var hidden_world_logs := []
	var rumor_entries := []

	if consumed_hours > 0:
		var events := ContentLoader.node_events(content, trigger_scope, node_id)
		for event in events:
			for revealed_node in event.get("reveal_nodes", []):
				_set_node_delta(node_deltas, str(revealed_node), {"visibility_state": "known"})
			var rumor_entry := {
				"rumor_id": "%s_t%03d_h%06d" % [event.get("id", "rumor"), turn_id, ended_hour],
				"event_id": event.get("id", ""),
				"source_node_id": node_id,
				"turn_id": turn_id,
				"world_hour": ended_hour,
				"message": event.get("rumor_text", event.get("description", ""))
			}
			rumor_entries.append(rumor_entry)
			visible_logs.append(LogUtils.visible("rumor_discovered", rumor_entry["message"], turn_id, world_day, ended_hour))
			hidden_world_logs.append(LogUtils.visible("world_rumor_created", "节点%s生成传闻%s。" % [node_id, event.get("id", "")], turn_id, world_day, ended_hour))

	return {
		"remaining_hours": remaining_hours - consumed_hours,
		"cursor_world_hour": ended_hour,
		"actual_entry": actual_entry,
		"visible_logs": visible_logs,
		"hidden_world_logs": hidden_world_logs,
		"rumor_entries": rumor_entries
	}

static func _settle_gather_resource_action(runtime: Dictionary, content: Dictionary, action: Dictionary, turn_id: int, world_day: int, cursor_world_hour: int, remaining_hours: int, character_deltas: Dictionary, node_deltas: Dictionary, resource_slot_deltas: Dictionary, asset_container_deltas: Dictionary, item_stack_deltas: Dictionary, asset_log_entries: Array) -> Dictionary:
	var planned_hours := int(action.get("planned_duration_hours", 0))
	var consumed_hours = min(planned_hours, remaining_hours)
	var ended_hour: int = cursor_world_hour + int(consumed_hours)
	var status := "completed"
	var reason := ""
	if consumed_hours < planned_hours:
		status = "partial"
		reason = "event_delay_or_budget_exhausted"

	var actual_entry := _actual_entry(action, planned_hours, consumed_hours, status, reason, cursor_world_hour, ended_hour)
	var visible_logs := []
	var hidden_world_logs := []
	if consumed_hours <= 0:
		return {
			"remaining_hours": remaining_hours - consumed_hours,
			"cursor_world_hour": ended_hour,
			"actual_entry": actual_entry,
			"visible_logs": visible_logs,
			"hidden_world_logs": hidden_world_logs
		}

	var node_id := _target_node(action)
	var slot_state := _first_resource_slot_for_node(runtime, resource_slot_deltas, node_id)
	if slot_state.is_empty():
		actual_entry["status"] = "skipped"
		actual_entry["skip_or_interrupt_reason"] = "resource_slot_missing"
		return {
			"remaining_hours": remaining_hours - consumed_hours,
			"cursor_world_hour": ended_hour,
			"actual_entry": actual_entry,
			"visible_logs": [LogUtils.visible("gather_resource_failed", "此处没有可采集资源槽。", turn_id, world_day, ended_hour)],
			"hidden_world_logs": hidden_world_logs
		}

	var abundance := int(slot_state.get("abundance", 0))
	var gathered_amount: int = int(min(float(abundance), max(1.0, floor(float(consumed_hours) / 12.0))))
	var item_template_id := str(slot_state.get("resource_item_template_id", "spirit_grass_stack"))
	var next_slot := slot_state.duplicate(true)
	next_slot["abundance"] = max(0, abundance - gathered_amount)
	next_slot["last_gathered_turn_id"] = turn_id
	next_slot["last_gathered_world_hour"] = ended_hour
	if not next_slot.get("state_tags", []).has("recently_gathered"):
		next_slot["state_tags"].append("recently_gathered")
	resource_slot_deltas[str(next_slot.get("slot_id", ""))] = next_slot

	var actor_id := str(action.get("actor_id", ""))
	var container_id := _inventory_container_id(runtime, character_deltas, actor_id)
	var stack_id := _add_stack_to_container(runtime, content, item_stack_deltas, asset_container_deltas, container_id, "CharacterInventory", item_template_id, gathered_amount, turn_id, ended_hour, action.get("instruction_id", ""))
	_set_node_delta(node_deltas, node_id, {"append_state_tags": ["resource_gathered_recent"]})

	var asset_log := _asset_log("resource_gathered", actor_id, container_id, item_template_id, action.get("instruction_id", ""), turn_id, world_day, ended_hour, consumed_hours, {
		"stack_id": stack_id,
		"slot_id": next_slot.get("slot_id", ""),
		"amount": gathered_amount,
		"node_id": node_id
	})
	asset_log_entries.append(asset_log)
	visible_logs.append(LogUtils.visible("resource_gathered", "在%s采集到%s x%d，资源槽丰度降至%d。" % [_node_name(runtime, content, node_id), item_template_id, gathered_amount, int(next_slot["abundance"])], turn_id, world_day, ended_hour))
	hidden_world_logs.append(LogUtils.visible("world_resource_slot_changed", "%s 的资源槽 %s 被采集。" % [node_id, next_slot.get("slot_id", "")], turn_id, world_day, ended_hour))
	actual_entry["resource_slot_id"] = next_slot.get("slot_id", "")
	actual_entry["gathered_item_template_id"] = item_template_id
	actual_entry["gathered_amount"] = gathered_amount
	return {
		"remaining_hours": remaining_hours - consumed_hours,
		"cursor_world_hour": ended_hour,
		"actual_entry": actual_entry,
		"visible_logs": visible_logs,
		"hidden_world_logs": hidden_world_logs
	}

static func _settle_join_sect_action(runtime: Dictionary, content: Dictionary, action: Dictionary, turn_id: int, world_day: int, cursor_world_hour: int, remaining_hours: int, character_deltas: Dictionary, node_deltas: Dictionary, asset_container_deltas: Dictionary, item_stack_deltas: Dictionary, item_instance_deltas: Dictionary, asset_log_entries: Array, character_log_entries: Array) -> Dictionary:
	var planned_hours := int(action.get("planned_duration_hours", 0))
	var consumed_hours = min(planned_hours, remaining_hours)
	var ended_hour: int = cursor_world_hour + int(consumed_hours)
	var status := "completed"
	var reason := ""
	if consumed_hours < planned_hours:
		status = "partial"
		reason = "event_delay_or_budget_exhausted"

	var actual_entry := _actual_entry(action, planned_hours, consumed_hours, status, reason, cursor_world_hour, ended_hour)
	var visible_logs := []
	var hidden_world_logs := []
	var rumor_entries := []
	if consumed_hours <= 0 or status != "completed":
		return {
			"remaining_hours": remaining_hours - consumed_hours,
			"cursor_world_hour": ended_hour,
			"actual_entry": actual_entry,
			"visible_logs": visible_logs,
			"hidden_world_logs": hidden_world_logs,
			"rumor_entries": rumor_entries
		}

	var actor_id := str(action.get("actor_id", ""))
	var event := ContentLoader.event_template(content, "sect_entry_test")
	var aptitude: Dictionary = event.get("aptitude_result", {})
	var sect_id := str(event.get("granted_sect_id", "sect_yunlu"))
	var rank := str(event.get("granted_rank", "outer"))
	var permissions: Array = event.get("granted_permissions", [])
	var identity := {
		"sect_id": sect_id,
		"rank": rank,
		"positions": [],
		"permissions": permissions,
		"member_reputation": 1,
		"contribution_records": [],
		"special_authorizations": []
	}
	_set_character_delta(character_deltas, actor_id, {
		"sect_identity": identity,
		"aptitude_profile": aptitude,
		"current_location": "node_outer_sect_room"
	})
	_append_character_array(runtime, character_deltas, actor_id, "known_info_refs", ["sect_yunlu", "node_outer_sect_room", "node_spirit_grass_slope"])

	for revealed_node in event.get("reveal_nodes", []):
		_set_node_delta(node_deltas, str(revealed_node), {"visibility_state": "known"})

	var container_id := _inventory_container_id(runtime, character_deltas, actor_id)
	var carrier_instance_ids := []
	for item_template_id in event.get("reward_item_instances", []):
		var template := ContentLoader.item_template(content, str(item_template_id))
		if template.is_empty():
			continue
		var item_id := "instance_%s_t%03d_h%06d" % [str(item_template_id), turn_id, ended_hour]
		carrier_instance_ids.append(item_id)
		item_instance_deltas[item_id] = {
			"item_id": item_id,
			"item_template_id": str(item_template_id),
			"tier_code": template.get("tier_code", "M0"),
			"quality_code": template.get("quality_code", "common"),
			"instance_state": {
				"carrier_type": template.get("carrier_type", ""),
				"method_template_id": template.get("method_template_id", ""),
				"method_type": template.get("method_type", ""),
				"copy_or_bind_state": "personal_copy",
				"source_event_id": "sect_entry_test"
			},
			"durability": 1.0,
			"charge": 0.0,
			"source_log_refs": [],
			"owner_container_ref": {"container_type": "CharacterInventory", "container_id": container_id},
			"tags": ["MethodCarrierItem"]
		}
		_append_asset_container_delta(asset_container_deltas, container_id, "item_instance_refs", item_id)

	for stack_reward in event.get("reward_item_stacks", []):
		if typeof(stack_reward) != TYPE_DICTIONARY:
			continue
		var item_template_id := str(stack_reward.get("item_template_id", ""))
		var template := ContentLoader.item_template(content, item_template_id)
		if template.is_empty():
			continue
		var stack_id := "stack_%s_t%03d_h%06d" % [item_template_id, turn_id, ended_hour]
		item_stack_deltas[stack_id] = {
			"stack_id": stack_id,
			"item_template_id": item_template_id,
			"tier_code": template.get("tier_code", "M0"),
			"quality_code": template.get("quality_code", "common"),
			"amount": int(stack_reward.get("amount", 1)),
			"key_state_tags": [],
			"bind_state": "unbound",
			"owner_container_ref": {"container_type": "CharacterInventory", "container_id": container_id}
		}
		_append_asset_container_delta(asset_container_deltas, container_id, "item_stack_refs", stack_id)

	var asset_log := _asset_log("sect_entry_reward", actor_id, container_id, "sect_entry_test", action.get("instruction_id", ""), turn_id, world_day, ended_hour, consumed_hours, {
		"item_instances": carrier_instance_ids,
		"item_stacks": event.get("reward_item_stacks", [])
	})
	asset_log_entries.append(asset_log)
	character_log_entries.append(LogUtils.visible("sect_entry_completed", "通过云麓宗入门试炼，成为外门弟子。", turn_id, world_day, ended_hour))
	visible_logs.append(LogUtils.visible("sect_entry_completed", "云麓宗收你为外门弟子，资质已揭示，并发下入门道功与清灵丹。", turn_id, world_day, ended_hour))
	hidden_world_logs.append(LogUtils.visible("world_sect_entry", "%s 完成云麓宗入门。" % actor_id, turn_id, world_day, ended_hour))
	rumor_entries.append({
		"rumor_id": "sect_entry_test_t%03d_h%06d" % [turn_id, ended_hour],
		"event_id": "sect_entry_test",
		"source_node_id": "node_yunlu_gate",
		"turn_id": turn_id,
		"world_hour": ended_hour,
		"message": event.get("rumor_text", "云麓宗收下一名新弟子。")
	})
	actual_entry["granted_sect_id"] = sect_id
	actual_entry["granted_rank"] = rank
	return {
		"remaining_hours": remaining_hours - consumed_hours,
		"cursor_world_hour": ended_hour,
		"actual_entry": actual_entry,
		"visible_logs": visible_logs,
		"hidden_world_logs": hidden_world_logs,
		"rumor_entries": rumor_entries
	}

static func _settle_study_method_action(runtime: Dictionary, content: Dictionary, action: Dictionary, turn_id: int, world_day: int, cursor_world_hour: int, remaining_hours: int, character_deltas: Dictionary, method_state_deltas: Dictionary, character_log_entries: Array) -> Dictionary:
	var planned_hours := int(action.get("planned_duration_hours", 0))
	var consumed_hours = min(planned_hours, remaining_hours)
	var ended_hour: int = cursor_world_hour + int(consumed_hours)
	var status := "completed"
	var reason := ""
	if consumed_hours < planned_hours:
		status = "partial"
		reason = "event_delay_or_budget_exhausted"
	var actual_entry := _actual_entry(action, planned_hours, consumed_hours, status, reason, cursor_world_hour, ended_hour)
	var visible_logs := []
	if consumed_hours <= 0:
		return {
			"remaining_hours": remaining_hours - consumed_hours,
			"cursor_world_hour": ended_hour,
			"actual_entry": actual_entry,
			"visible_logs": visible_logs
		}

	var actor_id := str(action.get("actor_id", ""))
	var carrier_template := ContentLoader.item_template(content, "basic_dao_method_carrier")
	var method_template_id := str(carrier_template.get("method_template_id", "basic_yunlu_dao_method"))
	var method_state_id := "method_%s_%s" % [method_template_id, actor_id]
	var current_state: Dictionary = runtime.get("method_states", {}).get(method_state_id, {}).duplicate(true)
	if method_state_deltas.has(method_state_id):
		current_state = method_state_deltas[method_state_id].duplicate(true)

	var character := _character_with_deltas(runtime, character_deltas, actor_id)
	var comprehension := int(character.get("aptitude_profile", {}).get("aptitude_comprehension", 0))
	var gained_exp: float = float(consumed_hours) * (1.0 + float(comprehension) * 0.03)
	var mastery_exp: float = float(current_state.get("mastery_exp", 0.0)) + gained_exp
	var mastery_level: int = int(max(1, int(current_state.get("mastery_level", 0))))
	if mastery_exp >= 72.0:
		mastery_level = 2
	var effective_cap := _method_effective_cap(carrier_template, mastery_level)
	method_state_deltas[method_state_id] = {
		"method_id": method_state_id,
		"template_id": method_template_id,
		"owner_character_id": actor_id,
		"method_type": carrier_template.get("method_type", "dao_method"),
		"mastery_level": mastery_level,
		"mastery_exp": mastery_exp,
		"current_effective_cap_stage": effective_cap,
		"unlocked_effect_refs": [],
		"source_carrier_ref": _find_item_instance_id(runtime, actor_id, "basic_dao_method_carrier"),
		"bind_or_permission_state": "learned_from_complete_carrier"
	}

	var cultivation: Dictionary = character.get("cultivation", {}).duplicate(true)
	cultivation["main_dao_method_ref"] = method_state_id
	cultivation["progress_cap_context"] = {
		"cap_source": "main_dao_method",
		"theoretical_max_cap_stage": carrier_template.get("theoretical_max_cap_stage", "A-3"),
		"current_effective_cap_stage": effective_cap,
		"required_mastery_level": 1,
		"missing_condition_refs": [],
		"suggested_actions": ["active_cultivation"]
	}
	_set_character_delta(character_deltas, actor_id, {"cultivation": cultivation})
	character_log_entries.append(LogUtils.visible("method_studied", "研习云麓入门道功，生成 MethodState。", turn_id, world_day, ended_hour))
	visible_logs.append(LogUtils.visible("method_studied", "云麓入门道功已入门，当前有效上限：%s。" % effective_cap, turn_id, world_day, ended_hour))
	actual_entry["method_state_id"] = method_state_id
	actual_entry["mastery_exp_delta"] = gained_exp
	return {
		"remaining_hours": remaining_hours - consumed_hours,
		"cursor_world_hour": ended_hour,
		"actual_entry": actual_entry,
		"visible_logs": visible_logs
	}

static func _settle_active_cultivation_action(runtime: Dictionary, content: Dictionary, action: Dictionary, turn_id: int, world_day: int, cursor_world_hour: int, remaining_hours: int, character_deltas: Dictionary, item_stack_deltas: Dictionary, active_resource_effect_deltas: Dictionary, asset_log_entries: Array, character_log_entries: Array) -> Dictionary:
	var planned_hours := int(action.get("planned_duration_hours", 0))
	var consumed_hours = min(planned_hours, remaining_hours)
	var ended_hour: int = cursor_world_hour + int(consumed_hours)
	var status := "completed"
	var reason := ""
	if consumed_hours < planned_hours:
		status = "partial"
		reason = "event_delay_or_budget_exhausted"
	var actual_entry := _actual_entry(action, planned_hours, consumed_hours, status, reason, cursor_world_hour, ended_hour)
	var visible_logs := []
	if consumed_hours <= 0:
		return {
			"remaining_hours": remaining_hours - consumed_hours,
			"cursor_world_hour": ended_hour,
			"actual_entry": actual_entry,
			"visible_logs": visible_logs
		}

	var actor_id := str(action.get("actor_id", ""))
	var character := _character_with_deltas(runtime, character_deltas, actor_id)
	var cultivation: Dictionary = character.get("cultivation", {}).duplicate(true)
	var method_state_id := str(cultivation.get("main_dao_method_ref", ""))
	var method_state: Dictionary = runtime.get("method_states", {}).get(method_state_id, {})
	var carrier_template := ContentLoader.item_template(content, "basic_dao_method_carrier")
	var node_id := _target_node(action)
	var node_state: Dictionary = runtime.get("node_states", {}).get(node_id, ContentLoader.node_template(content, node_id))
	var aura_level := int(node_state.get("aura_profile", {}).get("aura_level", 1))
	var aptitude: Dictionary = character.get("aptitude_profile", {})
	var mastery_level := int(method_state.get("mastery_level", 1))
	var base_per_hour: float = float(carrier_template.get("absorption_profile", {}).get("base_progress_per_hour", 0.6))
	var aura_multiplier: float = 1.0 + float(max(0.0, float(aura_level - 1))) * 0.25
	var aptitude_multiplier: float = 1.0 + float(aptitude.get("aptitude_root", 0)) * 0.02 + float(aptitude.get("aptitude_bone", 0)) * 0.01
	var mastery_multiplier: float = 1.0 + float(mastery_level) * 0.15
	var base_gain: float = float(consumed_hours) * base_per_hour * aura_multiplier * aptitude_multiplier * mastery_multiplier
	var resource_bonus: Dictionary = _consume_action_resource_inputs(runtime, content, action, actor_id, turn_id, world_day, cursor_world_hour, ended_hour, consumed_hours, item_stack_deltas, active_resource_effect_deltas, asset_log_entries, character_deltas)
	var total_gain: float = base_gain + float(resource_bonus.get("cultivation_progress_bonus", 0.0))
	var cultivation_result: Dictionary = _apply_cultivation_gain(cultivation, method_state, total_gain)
	_set_character_delta(character_deltas, actor_id, {"cultivation": cultivation_result["cultivation"]})
	character_log_entries.append(LogUtils.visible("active_cultivation", "主动吐纳%d小时，修为增长%.1f。" % [consumed_hours, total_gain], turn_id, world_day, ended_hour))

	var stage_note := ""
	if cultivation_result["stage_up"]:
		stage_note = " 小阶段提升至%s。" % cultivation_result["cultivation"].get("current_stage_code", "")
	visible_logs.append(LogUtils.visible("active_cultivation", "主动吐纳%d小时，修为增长%.1f。%s" % [consumed_hours, total_gain, stage_note], turn_id, world_day, ended_hour))
	if int(resource_bonus.get("residual_effect_hours", 0)) > 0:
		visible_logs.append(LogUtils.visible("resource_residual_created", "清灵丹剩余药性%d小时，已写入 ActiveResourceEffect。" % int(resource_bonus["residual_effect_hours"]), turn_id, world_day, ended_hour))
	actual_entry["cultivation_progress_delta"] = total_gain
	actual_entry["resource_bonus"] = resource_bonus
	actual_entry["stage_after"] = cultivation_result["cultivation"].get("current_stage_code", "")
	return {
		"remaining_hours": remaining_hours - consumed_hours,
		"cursor_world_hour": ended_hour,
		"actual_entry": actual_entry,
		"visible_logs": visible_logs
	}

static func _settle_request_sect_resource_action(runtime: Dictionary, content: Dictionary, action: Dictionary, turn_id: int, world_day: int, cursor_world_hour: int, remaining_hours: int, character_deltas: Dictionary, sect_deltas: Dictionary, asset_container_deltas: Dictionary, item_stack_deltas: Dictionary, asset_log_entries: Array, sect_log_entries: Array) -> Dictionary:
	var planned_hours := int(action.get("planned_duration_hours", 0))
	var consumed_hours = min(planned_hours, remaining_hours)
	var ended_hour: int = cursor_world_hour + int(consumed_hours)
	var status := "completed"
	var reason := ""
	if consumed_hours < planned_hours:
		status = "partial"
		reason = "event_delay_or_budget_exhausted"
	var actual_entry := _actual_entry(action, planned_hours, consumed_hours, status, reason, cursor_world_hour, ended_hour)
	var visible_logs := []
	if consumed_hours <= 0 or status != "completed":
		return {
			"remaining_hours": remaining_hours - consumed_hours,
			"cursor_world_hour": ended_hour,
			"actual_entry": actual_entry,
			"visible_logs": visible_logs
		}

	var actor_id := str(action.get("actor_id", ""))
	var target: Dictionary = action.get("target", {})
	var sect_id := str(target.get("target_id", "sect_yunlu"))
	var item_template_id := str(target.get("item_template_id", "qingling_pill"))
	var amount := int(target.get("amount", 1))
	var sect := _sect_with_deltas(runtime, sect_deltas, sect_id)
	var storage_container_id := str(sect.get("storage_container_ref", {}).get("container_id", ""))
	var source_stack_id := _find_stack_id(runtime, item_stack_deltas, storage_container_id, item_template_id)
	if source_stack_id == "":
		actual_entry["status"] = "skipped"
		actual_entry["skip_or_interrupt_reason"] = "sect_storage_lacks_resource"
		return {
			"remaining_hours": remaining_hours - consumed_hours,
			"cursor_world_hour": ended_hour,
			"actual_entry": actual_entry,
			"visible_logs": [LogUtils.visible("sect_resource_request_failed", "宗门库存不足，申请未批准。", turn_id, world_day, ended_hour)]
		}

	var source_stack := _stack_with_deltas(runtime, item_stack_deltas, source_stack_id)
	var next_source_stack := source_stack.duplicate(true)
	next_source_stack["amount"] = max(0, int(source_stack.get("amount", 0)) - amount)
	item_stack_deltas[source_stack_id] = next_source_stack

	var target_container_id := _inventory_container_id(runtime, character_deltas, actor_id)
	var target_stack_id := _add_stack_to_container(runtime, content, item_stack_deltas, asset_container_deltas, target_container_id, "CharacterInventory", item_template_id, amount, turn_id, ended_hour, action.get("instruction_id", ""))

	var next_sect := sect.duplicate(true)
	var stock: Dictionary = next_sect.get("sect_resource_stock", {}).duplicate(true)
	if item_template_id in ["qingling_pill", "stability_talisman"]:
		stock["cultivation_resource"] = max(0, int(stock.get("cultivation_resource", 0)) - amount)
	var stock_log := LogUtils.visible("sect_stock_granted", "云麓宗批准资源申请：%s x%d。" % [item_template_id, amount], turn_id, world_day, ended_hour)
	stock["expense_records"].append({
		"turn_id": turn_id,
		"world_hour": ended_hour,
		"kind": "disciple_resource_request",
		"item_template_id": item_template_id,
		"amount": amount,
		"actor_ref": actor_id
	})
	stock["stock_logs"].append(stock_log.get("entry_id", ""))
	next_sect["sect_resource_stock"] = stock
	_set_sect_delta(sect_deltas, sect_id, next_sect)

	var asset_log := _asset_log("sect_resource_granted", actor_id, storage_container_id, item_template_id, action.get("instruction_id", ""), turn_id, world_day, ended_hour, consumed_hours, {
		"source_stack_id": source_stack_id,
		"target_stack_id": target_stack_id,
		"amount": amount,
		"sect_id": sect_id
	})
	asset_log["container_to"] = target_container_id
	asset_log_entries.append(asset_log)
	sect_log_entries.append(stock_log)
	visible_logs.append(LogUtils.visible("sect_resource_granted", "宗门发放%s x%d，已进入角色背包；宗门库存同步扣减。" % [item_template_id, amount], turn_id, world_day, ended_hour))
	actual_entry["granted_item_template_id"] = item_template_id
	actual_entry["granted_amount"] = amount
	actual_entry["source_stack_id"] = source_stack_id
	actual_entry["target_stack_id"] = target_stack_id
	return {
		"remaining_hours": remaining_hours - consumed_hours,
		"cursor_world_hour": ended_hour,
		"actual_entry": actual_entry,
		"visible_logs": visible_logs
	}

static func _settle_simple_time_action(action: Dictionary, turn_id: int, world_day: int, cursor_world_hour: int, remaining_hours: int) -> Dictionary:
	var planned_hours := int(action.get("planned_duration_hours", 0))
	var consumed_hours = min(planned_hours, remaining_hours)
	var status := "completed"
	var reason := ""
	if consumed_hours < planned_hours:
		status = "partial"
		reason = "event_delay_or_budget_exhausted"
	var ended_hour: int = cursor_world_hour + int(consumed_hours)
	return {
		"remaining_hours": remaining_hours - consumed_hours,
		"cursor_world_hour": ended_hour,
		"actual_entry": _actual_entry(action, planned_hours, consumed_hours, status, reason, cursor_world_hour, ended_hour),
		"visible_logs": [
			LogUtils.visible("time_action_completed", "%s 执行%d小时。" % [action.get("action_id", "unknown_action"), consumed_hours], turn_id, world_day, ended_hour)
		]
	}

static func _settle_sect_ai(runtime: Dictionary, content: Dictionary, turn_id: int, world_day: int, world_hour: int, turn_total_hours: int, sect_deltas: Dictionary, node_deltas: Dictionary, resource_slot_deltas: Dictionary) -> Dictionary:
	var result := {
		"outcomes": [],
		"visible_logs": [],
		"hidden_world_logs": [],
		"rumor_entries": [],
		"sect_log_entries": []
	}
	for sect_id in runtime.get("sect_states", {}).keys():
		var sect := _sect_with_deltas(runtime, sect_deltas, str(sect_id))
		var active: Dictionary = sect.get("active_continuous_action", {})
		var status := str(active.get("status", "none"))
		if status in ["", "none", "completed", "interrupted"]:
			var selected := _select_sect_ai_action(runtime, content, sect)
			if selected.is_empty():
				continue
			var next_sect := sect.duplicate(true)
			next_sect["active_continuous_action"] = _make_sect_continuous_action(selected, str(sect_id), turn_id, world_day)
			_set_sect_delta(sect_deltas, str(sect_id), next_sect)
			var log_entry := LogUtils.visible("sect_ai_action_selected", "%s 将%s列为当前唯一持续行动。" % [sect.get("display_name", str(sect_id)), selected.get("display_name", selected.get("id", ""))], turn_id, world_day, world_hour)
			result["sect_log_entries"].append(log_entry)
			result["visible_logs"].append(LogUtils.visible("sect_ai_summary", "宗门当前重点：%s。" % selected.get("display_name", selected.get("id", "")), turn_id, world_day, world_hour))
			result["outcomes"].append({
				"kind": "selected_continuous_action",
				"sect_id": str(sect_id),
				"action_id": selected.get("id", ""),
				"target_node_id": selected.get("target_node_id", "")
			})
		elif status == "active":
			var advance_result := _advance_sect_continuous_action(runtime, content, sect, turn_id, world_day, world_hour, turn_total_hours, sect_deltas, node_deltas, resource_slot_deltas)
			result["outcomes"].append_array(advance_result["outcomes"])
			result["visible_logs"].append_array(advance_result["visible_logs"])
			result["hidden_world_logs"].append_array(advance_result["hidden_world_logs"])
			result["rumor_entries"].append_array(advance_result["rumor_entries"])
			result["sect_log_entries"].append_array(advance_result["sect_log_entries"])
	return result

static func _select_sect_ai_action(runtime: Dictionary, content: Dictionary, sect: Dictionary) -> Dictionary:
	var actions := ContentLoader.ai_actions_for_sect(content, str(sect.get("sect_id", "")))
	var stock: Dictionary = sect.get("sect_resource_stock", {})
	for template in actions:
		var action_id := str(template.get("id", ""))
		var target_node_id := str(template.get("target_node_id", ""))
		var node_state := _node_with_deltas(runtime, {}, target_node_id)
		if action_id == "sect_patrol_route":
			var danger_level := int(node_state.get("danger_profile", {}).get("danger_level", 0))
			if danger_level >= 2 and not node_state.get("state_tags", []).has("sect_patrol_recent"):
				return template
		elif action_id == "sect_maintain_training_site":
			var aura_level := int(node_state.get("aura_profile", {}).get("aura_level", 0))
			if aura_level < 5 and int(stock.get("material_stock", 0)) > 0:
				return template
		elif action_id == "sect_mine_resource_node":
			if int(stock.get("material_stock", 0)) < 6:
				return template
	if not actions.is_empty():
		return actions[0]
	return {}

static func _make_sect_continuous_action(template: Dictionary, sect_id: String, turn_id: int, world_day: int) -> Dictionary:
	return {
		"action_id": template.get("id", ""),
		"sect_id": sect_id,
		"action_type": template.get("action_type", ""),
		"target_node_id": template.get("target_node_id", ""),
		"status": "active",
		"started_turn_id": turn_id,
		"started_world_day": world_day,
		"expected_duration_turns": int(template.get("expected_duration_turns", 1)),
		"expected_duration_hours": int(template.get("expected_duration_hours", 120)),
		"accumulated_hours": 0,
		"progress": 0.0,
		"resource_budget": template.get("resource_budget", {}),
		"manpower_budget": int(template.get("resource_budget", {}).get("manpower_per_turn", 0)),
		"ai_reason_tags": template.get("ai_reason_tags", []),
		"interruption_rules": {},
		"related_event_refs": [],
		"visible_summary_key": template.get("display_name", template.get("id", "")),
		"world_log_refs": []
	}

static func _advance_sect_continuous_action(runtime: Dictionary, content: Dictionary, sect: Dictionary, turn_id: int, world_day: int, world_hour: int, turn_total_hours: int, sect_deltas: Dictionary, node_deltas: Dictionary, resource_slot_deltas: Dictionary) -> Dictionary:
	var result := {
		"outcomes": [],
		"visible_logs": [],
		"hidden_world_logs": [],
		"rumor_entries": [],
		"sect_log_entries": []
	}
	var active: Dictionary = sect.get("active_continuous_action", {}).duplicate(true)
	var template := ContentLoader.ai_action_template(content, str(active.get("action_id", "")))
	if template.is_empty():
		return result

	var next_sect := sect.duplicate(true)
	var stock: Dictionary = next_sect.get("sect_resource_stock", {}).duplicate(true)
	var budget: Dictionary = active.get("resource_budget", {})
	var manpower_cost := int(budget.get("manpower_per_turn", 0))
	var material_cost := int(budget.get("material_stock_per_turn", 0))
	if int(stock.get("manpower", 0)) < manpower_cost or int(stock.get("material_stock", 0)) < material_cost:
		active["status"] = "blocked"
		active["ai_reason_tags"].append("stock_or_manpower_shortage")
		next_sect["active_continuous_action"] = active
		_set_sect_delta(sect_deltas, str(sect.get("sect_id", "")), next_sect)
		var blocked_log := LogUtils.visible("sect_ai_action_blocked", "%s 因库存或人力不足受阻。" % active.get("visible_summary_key", active.get("action_id", "")), turn_id, world_day, world_hour)
		result["sect_log_entries"].append(blocked_log)
		result["visible_logs"].append(blocked_log)
		return result

	stock["manpower"] = int(stock.get("manpower", 0)) - manpower_cost
	stock["material_stock"] = int(stock.get("material_stock", 0)) - material_cost
	active["accumulated_hours"] = int(active.get("accumulated_hours", 0)) + turn_total_hours
	active["progress"] = min(1.0, float(active.get("accumulated_hours", 0)) / max(1.0, float(active.get("expected_duration_hours", 1))))

	var target_node_id := str(active.get("target_node_id", ""))
	_apply_sect_ai_node_effect(runtime, template, target_node_id, node_deltas)
	if str(template.get("id", "")) == "sect_mine_resource_node" and active["progress"] >= 1.0:
		stock["material_stock"] = int(stock.get("material_stock", 0)) + 3

	var progress_log := LogUtils.visible("sect_ai_action_progressed", "%s 推进至 %.0f%%。" % [active.get("visible_summary_key", active.get("action_id", "")), float(active["progress"]) * 100.0], turn_id, world_day, world_hour + turn_total_hours)
	active["world_log_refs"].append(progress_log.get("entry_id", ""))
	result["sect_log_entries"].append(progress_log)
	result["hidden_world_logs"].append(LogUtils.visible("world_sect_ai_progress", "%s 影响节点 %s。" % [active.get("action_id", ""), target_node_id], turn_id, world_day, world_hour + turn_total_hours))
	result["rumor_entries"].append({
		"rumor_id": "%s_t%03d_h%06d" % [active.get("action_id", "sect_ai"), turn_id, world_hour + turn_total_hours],
		"event_id": active.get("action_id", ""),
		"source_node_id": target_node_id,
		"turn_id": turn_id,
		"world_hour": world_hour + turn_total_hours,
		"message": "%s有所动作：%s。" % [sect.get("display_name", "宗门"), active.get("visible_summary_key", "宗门持续行动")]
	})
	result["visible_logs"].append(LogUtils.visible("sect_ai_summary", "%s：%s，当前进度 %.0f%%。" % [sect.get("display_name", "宗门"), active.get("visible_summary_key", ""), float(active["progress"]) * 100.0], turn_id, world_day, world_hour + turn_total_hours))
	result["outcomes"].append({
		"kind": "advanced_continuous_action",
		"sect_id": sect.get("sect_id", ""),
		"action_id": active.get("action_id", ""),
		"target_node_id": target_node_id,
		"progress": active["progress"]
	})

	if active["progress"] >= 1.0:
		active["status"] = "completed"
		result["sect_log_entries"].append(LogUtils.visible("sect_ai_action_completed", "%s 已完成。" % active.get("visible_summary_key", active.get("action_id", "")), turn_id, world_day, world_hour + turn_total_hours))

	next_sect["sect_resource_stock"] = stock
	next_sect["active_continuous_action"] = active
	_set_sect_delta(sect_deltas, str(sect.get("sect_id", "")), next_sect)
	return result

static func _apply_sect_ai_node_effect(runtime: Dictionary, template: Dictionary, target_node_id: String, node_deltas: Dictionary) -> void:
	var node_state := _node_with_deltas(runtime, node_deltas, target_node_id)
	var node_effect: Dictionary = template.get("node_delta_on_progress", {})
	var delta := {}
	if node_effect.has("danger_delta"):
		var danger_profile: Dictionary = node_state.get("danger_profile", {}).duplicate(true)
		danger_profile["danger_level"] = max(1, int(danger_profile.get("danger_level", 1)) + int(node_effect.get("danger_delta", 0)))
		delta["danger_profile"] = danger_profile
	if node_effect.has("aura_delta"):
		var aura_profile: Dictionary = node_state.get("aura_profile", {}).duplicate(true)
		aura_profile["aura_level"] = min(5, int(aura_profile.get("aura_level", 1)) + int(node_effect.get("aura_delta", 0)))
		delta["aura_profile"] = aura_profile
	if node_effect.has("append_state_tags"):
		delta["append_state_tags"] = node_effect.get("append_state_tags", [])
	_set_node_delta(node_deltas, target_node_id, delta)

static func _validation_failed_result(turn_id: int, world_day: int, world_hour: int, player_id: String, validation: Dictionary) -> Dictionary:
	var package := {
		"package_id": "s1_turn_%03d_validation_failed" % turn_id,
		"source_system": "S1_settlement_bus",
		"turn_id": turn_id,
		"state_deltas": {
			"room_state": {
				"current_phase": "personal_action_planning",
				"settlement_status": "validation_failed"
			},
			"player_lock_state": {
				"player_id": player_id,
				"lock_state": "unlocked"
			}
		},
		"visible_logs": [
			LogUtils.visible("validation_failed", "锁定失败：行动预案没有通过硬校验。", turn_id, world_day, world_hour)
		],
		"debug_logs": [
			LogUtils.debug("validation_failed", "Action validation failed before settlement.", turn_id, world_hour, validation)
		],
		"errors": validation["errors"]
	}
	return {
		"ok": false,
		"validation": validation,
		"packages": [package],
		"turn_replay": {}
	}

static func _actual_queue_for_settlement(original_queue: Array, turn_total_hours: int) -> Array:
	if original_queue.is_empty():
		return [PersonalActionInstruction.make_rest(DemoConstants.LOCAL_CHARACTER_ID, 1, turn_total_hours)]
	return original_queue.duplicate(true)

static func _summarize_actions(actions: Array) -> Array:
	var summaries := []
	for action in actions:
		if typeof(action) != TYPE_DICTIONARY:
			continue
		summaries.append({
			"instruction_id": action.get("instruction_id", ""),
			"action_id": action.get("action_id", ""),
			"planned_duration_hours": int(action.get("planned_duration_hours", 0)),
			"target": action.get("target", {}),
			"status": action.get("status", "draft")
		})
	return summaries

static func _actual_entry(action: Dictionary, planned_hours: int, consumed_hours: int, status: String, reason: String, started_world_hour: int, ended_world_hour: int) -> Dictionary:
	return {
		"instruction_id": action.get("instruction_id", ""),
		"action_id": action.get("action_id", ""),
		"target": action.get("target", {}),
		"planned_duration_hours": planned_hours,
		"actual_consumed_hours": consumed_hours,
		"status": status,
		"skip_or_interrupt_reason": reason,
		"started_world_hour": started_world_hour,
		"ended_world_hour": ended_world_hour
	}

static func _skipped_entry(action: Dictionary, reason: String) -> Dictionary:
	return {
		"instruction_id": action.get("instruction_id", ""),
		"action_id": action.get("action_id", ""),
		"target": action.get("target", {}),
		"planned_duration_hours": int(action.get("planned_duration_hours", 0)),
		"actual_consumed_hours": 0,
		"status": "skipped",
		"skip_or_interrupt_reason": reason
	}

static func _summary_notes(interruptions: Array, rumor_entries: Array, sect_ai_outcomes: Array) -> Array:
	var notes := ["Phase D settlement path: personal actions, resources, node slots, and sect AI resolved through ResultPackage writeback."]
	if not interruptions.is_empty():
		notes.append("插入事件消耗了额外小时，后续行动按剩余预算执行。")
	if not rumor_entries.is_empty():
		notes.append("打听行动生成了玩家可见传闻，并更新节点可见性。")
	if not sect_ai_outcomes.is_empty():
		notes.append("宗门 AI 维护唯一持续行动，并通过结果包影响宗门、节点或传闻。")
	return notes

static func _target_node(action: Dictionary) -> String:
	var target = action.get("target", {})
	if typeof(target) != TYPE_DICTIONARY:
		return ""
	return str(target.get("target_id", ""))

static func _current_location_for_actor(runtime: Dictionary, character_deltas: Dictionary, actor_id: String) -> String:
	if character_deltas.has(actor_id) and character_deltas[actor_id].has("current_location"):
		return str(character_deltas[actor_id]["current_location"])
	return str(runtime.get("incarnations", {}).get(actor_id, {}).get("current_location", ""))

static func _set_character_delta(character_deltas: Dictionary, character_id: String, delta: Dictionary) -> void:
	if not character_deltas.has(character_id):
		character_deltas[character_id] = {}
	for key in delta.keys():
		character_deltas[character_id][key] = delta[key]

static func _set_node_delta(node_deltas: Dictionary, node_id: String, delta: Dictionary) -> void:
	if node_id == "":
		return
	if not node_deltas.has(node_id):
		node_deltas[node_id] = {}
	for key in delta.keys():
		if key == "append_state_tags":
			if not node_deltas[node_id].has("append_state_tags"):
				node_deltas[node_id]["append_state_tags"] = []
			for tag in delta[key]:
				if not node_deltas[node_id]["append_state_tags"].has(tag):
					node_deltas[node_id]["append_state_tags"].append(tag)
		elif key == "append_world_log_refs":
			if not node_deltas[node_id].has("append_world_log_refs"):
				node_deltas[node_id]["append_world_log_refs"] = []
			for log_ref in delta[key]:
				node_deltas[node_id]["append_world_log_refs"].append(log_ref)
		else:
			node_deltas[node_id][key] = delta[key]

static func _set_sect_delta(sect_deltas: Dictionary, sect_id: String, next_sect: Dictionary) -> void:
	if sect_id == "":
		return
	sect_deltas[sect_id] = next_sect

static func _resource_bindings(action: Dictionary) -> Array:
	if action.has("resource_bindings"):
		return action.get("resource_bindings", [])
	return action.get("resource_inputs", [])

static func _consume_action_resource_inputs(runtime: Dictionary, content: Dictionary, action: Dictionary, actor_id: String, turn_id: int, world_day: int, started_world_hour: int, ended_world_hour: int, consumed_hours: int, item_stack_deltas: Dictionary, active_resource_effect_deltas: Dictionary, asset_log_entries: Array, character_deltas: Dictionary) -> Dictionary:
	var result := {
		"cultivation_progress_bonus": 0.0,
		"consumed_resources": [],
		"residual_effect_hours": 0
	}
	for binding in _resource_bindings(action):
		if typeof(binding) != TYPE_DICTIONARY:
			continue
		var resource_ref := str(binding.get("resource_ref", ""))
		var template := ContentLoader.item_template(content, resource_ref)
		if template.is_empty():
			continue
		var source_container_ref: Dictionary = binding.get("source_container_ref", {})
		var container_id := str(source_container_ref.get("container_id", _inventory_container_id(runtime, character_deltas, actor_id)))
		var stack_id := _find_stack_id(runtime, item_stack_deltas, container_id, resource_ref)
		if stack_id == "":
			continue

		var stack := _stack_with_deltas(runtime, item_stack_deltas, stack_id)
		var next_stack := stack.duplicate(true)
		next_stack["amount"] = max(0, int(stack.get("amount", 0)) - 1)
		item_stack_deltas[stack_id] = next_stack

		var max_effective_hours := int(binding.get("max_effective_hours", template.get("max_effective_hours", consumed_hours)))
		var planned_use_hours := int(binding.get("planned_use_hours", max_effective_hours))
		var compatible_hours := int(min(float(consumed_hours), min(float(max_effective_hours), float(planned_use_hours))))
		var unit_effect := float(template.get("unit_effect_per_hour", 0.0))
		var bonus := unit_effect * float(compatible_hours)
		result["cultivation_progress_bonus"] = float(result["cultivation_progress_bonus"]) + bonus
		result["consumed_resources"].append({
			"resource_ref": resource_ref,
			"stack_id": stack_id,
			"compatible_hours": compatible_hours,
			"bonus": bonus
		})

		var resource_log := _asset_log("resource_consumed", actor_id, container_id, resource_ref, action.get("instruction_id", ""), turn_id, world_day, ended_world_hour, compatible_hours, {
			"stack_id": stack_id,
			"amount": 1,
			"started_world_hour": started_world_hour,
			"resource_effect_template_id": binding.get("resource_effect_template_id", template.get("resource_effect_template_id", "")),
			"effect_channel": binding.get("effect_channel", template.get("effect_channel", ""))
		})
		asset_log_entries.append(resource_log)

		var residual_hours: int = int(max(0, max_effective_hours - compatible_hours))
		if residual_hours > 0:
			var effect_id := "effect_%s_%s_t%03d_h%06d" % [resource_ref, actor_id, turn_id, ended_world_hour]
			active_resource_effect_deltas[effect_id] = {
				"effect_id": effect_id,
				"owner_character_id": actor_id,
				"source_resource_ref": resource_ref,
				"resource_effect_template_id": binding.get("resource_effect_template_id", template.get("resource_effect_template_id", "")),
				"effect_channel": binding.get("effect_channel", template.get("effect_channel", "")),
				"compatible_action_tags": template.get("compatible_action_tags", []),
				"timing_mode": binding.get("timing_mode", "compatible_action_hours"),
				"remaining_effect_hours": float(residual_hours),
				"remaining_effect_amount": unit_effect * float(residual_hours),
				"residual_policy": binding.get("residual_policy", template.get("residual_policy", "stable_suspend")),
				"stable_until_world_hour": ended_world_hour + residual_hours,
				"decay_started_world_hour": 0,
				"pressure_tags": [],
				"created_turn_id": turn_id,
				"created_world_hour": ended_world_hour,
				"last_settled_world_hour": ended_world_hour,
				"log_refs": [resource_log.get("entry_id", "")]
			}
			_append_character_array(runtime, character_deltas, actor_id, "active_resource_effect_refs", [effect_id])
			result["residual_effect_hours"] = int(result["residual_effect_hours"]) + residual_hours
	return result

static func _apply_cultivation_gain(cultivation: Dictionary, method_state: Dictionary, gain: float) -> Dictionary:
	var next_cultivation := cultivation.duplicate(true)
	var stage := str(next_cultivation.get("current_stage_code", "A-1"))
	var progress := float(next_cultivation.get("cultivation_progress", 0.0)) + gain
	var effective_cap := str(method_state.get("current_effective_cap_stage", "A-1"))
	var stage_up := false

	if stage == "A-1":
		if progress >= 60.0 and _stage_allows(effective_cap, "A-2"):
			stage = "A-2"
			progress = min(progress - 60.0, 40.0)
			stage_up = true
		elif progress >= 60.0:
			progress = 60.0
			next_cultivation["bottleneck_state"] = "soft_cap"
	elif stage == "A-2":
		if progress >= 120.0:
			progress = 120.0
			next_cultivation["bottleneck_state"] = "breakthrough_required"

	next_cultivation["current_stage_code"] = stage
	next_cultivation["cultivation_progress"] = progress
	if stage_up:
		next_cultivation["bottleneck_state"] = "none"
	if not next_cultivation.has("progress_cap_context"):
		next_cultivation["progress_cap_context"] = {}
	next_cultivation["progress_cap_context"]["current_effective_cap_stage"] = effective_cap
	if not _stage_allows(effective_cap, stage):
		next_cultivation["bottleneck_state"] = "soft_cap"
		next_cultivation["progress_cap_context"]["cap_source"] = "main_dao_method"
		next_cultivation["progress_cap_context"]["missing_condition_refs"] = ["method_mastery_cap"]
	return {
		"cultivation": next_cultivation,
		"stage_up": stage_up
	}

static func _stage_allows(cap_stage: String, target_stage: String) -> bool:
	return _stage_order(cap_stage) >= _stage_order(target_stage)

static func _stage_order(stage_code: String) -> int:
	match stage_code:
		"A-1":
			return 1
		"A-2":
			return 2
		"A-3":
			return 3
		"B-1":
			return 4
		_:
			return 0

static func _method_effective_cap(carrier_template: Dictionary, mastery_level: int) -> String:
	var profile: Dictionary = carrier_template.get("mastery_cap_profile", {})
	var key := "level_%d_effective_cap_stage" % mastery_level
	if profile.has(key):
		return str(profile[key])
	if mastery_level >= 2 and profile.has("level_2_effective_cap_stage"):
		return str(profile["level_2_effective_cap_stage"])
	return str(profile.get("level_1_effective_cap_stage", "A-1"))

static func _append_asset_container_delta(asset_container_deltas: Dictionary, container_id: String, ref_key: String, ref_id: String) -> void:
	if container_id == "" or ref_id == "":
		return
	if not asset_container_deltas.has(container_id):
		asset_container_deltas[container_id] = {}
	var append_key := "append_%s" % ref_key
	if not asset_container_deltas[container_id].has(append_key):
		asset_container_deltas[container_id][append_key] = []
	if not asset_container_deltas[container_id][append_key].has(ref_id):
		asset_container_deltas[container_id][append_key].append(ref_id)

static func _add_stack_to_container(runtime: Dictionary, content: Dictionary, item_stack_deltas: Dictionary, asset_container_deltas: Dictionary, container_id: String, container_type: String, item_template_id: String, amount: int, turn_id: int, world_hour: int, source_id: String) -> String:
	var existing_stack_id := _find_stack_id(runtime, item_stack_deltas, container_id, item_template_id)
	if existing_stack_id != "":
		var existing_stack := _stack_with_deltas(runtime, item_stack_deltas, existing_stack_id)
		var next_stack := existing_stack.duplicate(true)
		next_stack["amount"] = int(existing_stack.get("amount", 0)) + amount
		item_stack_deltas[existing_stack_id] = next_stack
		return existing_stack_id

	var template := ContentLoader.item_template(content, item_template_id)
	var stack_id := "stack_%s_%s_t%03d_h%06d_%s" % [container_id, item_template_id, turn_id, world_hour, _safe_id(source_id)]
	item_stack_deltas[stack_id] = {
		"stack_id": stack_id,
		"item_template_id": item_template_id,
		"tier_code": template.get("tier_code", "M0"),
		"quality_code": template.get("quality_code", "common"),
		"amount": amount,
		"key_state_tags": [],
		"bind_state": "unbound",
		"owner_container_ref": {"container_type": container_type, "container_id": container_id}
	}
	_append_asset_container_delta(asset_container_deltas, container_id, "item_stack_refs", stack_id)
	return stack_id

static func _append_character_array(runtime: Dictionary, character_deltas: Dictionary, actor_id: String, key: String, values: Array) -> void:
	var character := _character_with_deltas(runtime, character_deltas, actor_id)
	var next_values: Array = character.get(key, []).duplicate(true)
	for value in values:
		if not next_values.has(value):
			next_values.append(value)
	_set_character_delta(character_deltas, actor_id, {key: next_values})

static func _character_with_deltas(runtime: Dictionary, character_deltas: Dictionary, actor_id: String) -> Dictionary:
	var character: Dictionary = runtime.get("incarnations", {}).get(actor_id, {}).duplicate(true)
	if character_deltas.has(actor_id):
		for key in character_deltas[actor_id].keys():
			character[key] = character_deltas[actor_id][key]
	return character

static func _sect_with_deltas(runtime: Dictionary, sect_deltas: Dictionary, sect_id: String) -> Dictionary:
	if sect_deltas.has(sect_id):
		return sect_deltas[sect_id].duplicate(true)
	return runtime.get("sect_states", {}).get(sect_id, {}).duplicate(true)

static func _node_with_deltas(runtime: Dictionary, node_deltas: Dictionary, node_id: String) -> Dictionary:
	var node_state: Dictionary = runtime.get("node_states", {}).get(node_id, {}).duplicate(true)
	if node_deltas.has(node_id):
		for key in node_deltas[node_id].keys():
			if key == "append_state_tags":
				if not node_state.has("state_tags"):
					node_state["state_tags"] = []
				for tag in node_deltas[node_id][key]:
					if not node_state["state_tags"].has(tag):
						node_state["state_tags"].append(tag)
			else:
				node_state[key] = node_deltas[node_id][key]
	return node_state

static func _first_resource_slot_for_node(runtime: Dictionary, resource_slot_deltas: Dictionary, node_id: String) -> Dictionary:
	for slot_id in runtime.get("resource_slot_states", {}).keys():
		var slot_state := _resource_slot_with_deltas(runtime, resource_slot_deltas, str(slot_id))
		if str(slot_state.get("node_id", "")) == node_id and int(slot_state.get("abundance", 0)) > 0:
			return slot_state
	for slot_id in resource_slot_deltas.keys():
		var slot_state: Dictionary = resource_slot_deltas[slot_id]
		if str(slot_state.get("node_id", "")) == node_id and int(slot_state.get("abundance", 0)) > 0:
			return slot_state
	return {}

static func _resource_slot_with_deltas(runtime: Dictionary, resource_slot_deltas: Dictionary, slot_id: String) -> Dictionary:
	if resource_slot_deltas.has(slot_id):
		return resource_slot_deltas[slot_id].duplicate(true)
	return runtime.get("resource_slot_states", {}).get(slot_id, {}).duplicate(true)

static func _inventory_container_id(runtime: Dictionary, character_deltas: Dictionary, actor_id: String) -> String:
	var character := _character_with_deltas(runtime, character_deltas, actor_id)
	return str(character.get("inventory_container_ref", {}).get("container_id", ""))

static func _find_item_instance_id(runtime: Dictionary, actor_id: String, item_template_id: String) -> String:
	var character: Dictionary = runtime.get("incarnations", {}).get(actor_id, {})
	var container_id := str(character.get("inventory_container_ref", {}).get("container_id", ""))
	var container: Dictionary = runtime.get("asset_containers", {}).get(container_id, {})
	for item_id in container.get("item_instance_refs", []):
		var instance: Dictionary = runtime.get("item_instances", {}).get(str(item_id), {})
		if str(instance.get("item_template_id", "")) == item_template_id:
			return str(item_id)
	return ""

static func _find_stack_id(runtime: Dictionary, item_stack_deltas: Dictionary, container_id: String, item_template_id: String) -> String:
	var container: Dictionary = runtime.get("asset_containers", {}).get(container_id, {})
	for stack_id in container.get("item_stack_refs", []):
		var stack := _stack_with_deltas(runtime, item_stack_deltas, str(stack_id))
		if str(stack.get("item_template_id", "")) == item_template_id and int(stack.get("amount", 0)) > 0:
			return str(stack_id)
	return ""

static func _stack_with_deltas(runtime: Dictionary, item_stack_deltas: Dictionary, stack_id: String) -> Dictionary:
	if item_stack_deltas.has(stack_id):
		return item_stack_deltas[stack_id].duplicate(true)
	return runtime.get("item_stacks", {}).get(stack_id, {}).duplicate(true)

static func _asset_log(kind: String, actor_id: String, container_id: String, resource_or_event_ref: String, instruction_id: String, turn_id: int, world_day: int, world_hour: int, consumed_hours: int, details: Dictionary) -> Dictionary:
	var entry := LogUtils.visible(kind, "%s: %s" % [kind, resource_or_event_ref], turn_id, world_day, world_hour)
	entry["source_system"] = "asset_container"
	entry["actor_ref"] = actor_id
	entry["container_from"] = container_id
	entry["container_to"] = container_id
	entry["asset_refs"] = [resource_or_event_ref]
	entry["action_or_event_ref"] = instruction_id
	entry["consumed_hours"] = consumed_hours
	entry["details"] = details
	return entry

static func _safe_id(value: String) -> String:
	var result := value.replace(":", "_")
	result = result.replace("/", "_")
	result = result.replace(" ", "_")
	if result == "":
		return "auto"
	return result

static func _movement_event_for_route(content: Dictionary, route: Dictionary) -> Dictionary:
	if route.get("risk_tags", []).has("minor_delay"):
		return ContentLoader.event_template(content, "road_minor_delay")
	return {}

static func _node_name(runtime: Dictionary, content: Dictionary, node_id: String) -> String:
	if runtime.get("node_states", {}).has(node_id):
		return str(runtime["node_states"][node_id].get("display_name", node_id))
	return str(ContentLoader.node_template(content, node_id).get("display_name", node_id))
