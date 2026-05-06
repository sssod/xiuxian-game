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
	var method_state_deltas := {}
	var asset_container_deltas := {}
	var item_stack_deltas := {}
	var item_instance_deltas := {}
	var active_resource_effect_deltas := {}
	var asset_log_entries := []
	var character_log_entries := []
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
		"notes": _summary_notes(interruptions, rumor_entries)
	}

	for entry in actual_entries:
		visible_logs.append(LogUtils.visible("action_result", "行动 %s 实际消耗 %d 小时。" % [entry["action_id"], entry["actual_consumed_hours"]], turn_id, world_day, int(entry.get("ended_world_hour", next_world_hour))))
	visible_logs.append(LogUtils.visible("turn_settlement_finished", "第 %d 回合结束，世界时间推进到第 %d 天。" % [turn_id, next_world_day], turn_id, next_world_day, next_world_hour))
	debug_logs.append(LogUtils.debug("s1_package_created", "ResultPackage generated by Phase C settlement.", turn_id, next_world_hour, {
		"actual_entries": actual_entries.size(),
		"interruptions": interruptions.size(),
		"node_delta_count": node_deltas.size(),
		"method_delta_count": method_state_deltas.size(),
		"asset_log_count": asset_log_entries.size()
	}))

	var package := {
		"package_id": "s1_turn_%03d_phase_c" % turn_id,
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
			"method_states": method_state_deltas,
			"asset_containers": asset_container_deltas,
			"item_stacks": item_stack_deltas,
			"item_instances": item_instance_deltas,
			"active_resource_effects": active_resource_effect_deltas,
			"asset_log_entries": asset_log_entries,
			"character_log_entries": character_log_entries,
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

static func _summary_notes(interruptions: Array, rumor_entries: Array) -> Array:
	var notes := ["Phase C settlement path: movement, node events, sect entry, MethodState, cultivation, and resource inputs resolved through ResultPackage writeback."]
	if not interruptions.is_empty():
		notes.append("插入事件消耗了额外小时，后续行动按剩余预算执行。")
	if not rumor_entries.is_empty():
		notes.append("打听行动生成了玩家可见传闻，并更新节点可见性。")
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

static func _movement_event_for_route(content: Dictionary, route: Dictionary) -> Dictionary:
	if route.get("risk_tags", []).has("minor_delay"):
		return ContentLoader.event_template(content, "road_minor_delay")
	return {}

static func _node_name(runtime: Dictionary, content: Dictionary, node_id: String) -> String:
	if runtime.get("node_states", {}).has(node_id):
		return str(runtime["node_states"][node_id].get("display_name", node_id))
	return str(ContentLoader.node_template(content, node_id).get("display_name", node_id))
