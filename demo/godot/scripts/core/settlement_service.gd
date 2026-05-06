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
	debug_logs.append(LogUtils.debug("s1_package_created", "ResultPackage generated by Phase B settlement.", turn_id, next_world_hour, {
		"actual_entries": actual_entries.size(),
		"interruptions": interruptions.size(),
		"node_delta_count": node_deltas.size()
	}))

	var package := {
		"package_id": "s1_turn_%03d_phase_b" % turn_id,
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
		"resource_changes": [],
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
			"node_deltas": node_deltas
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
	var notes := ["Phase B settlement path: movement, node rumor events, and plan delays resolved through ResultPackage writeback."]
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

static func _movement_event_for_route(content: Dictionary, route: Dictionary) -> Dictionary:
	if route.get("risk_tags", []).has("minor_delay"):
		return ContentLoader.event_template(content, "road_minor_delay")
	return {}

static func _node_name(runtime: Dictionary, content: Dictionary, node_id: String) -> String:
	if runtime.get("node_states", {}).has(node_id):
		return str(runtime["node_states"][node_id].get("display_name", node_id))
	return str(ContentLoader.node_template(content, node_id).get("display_name", node_id))
