extends RefCounted
class_name CommandQueue

const MAX_FUTURE_COMMANDS = 3
const ACTION_FALLBACK_MEDITATE = "fallback_meditate"
const ACTION_REST = "rest"
const COMMAND_STATE_PENDING = "pending"
const COMMAND_STATE_RUNNING = "running"
const COMMAND_STATE_COMPLETED = "completed"
const COMMAND_STATE_SKIPPED = "skipped"

var current_command: Dictionary = {}
var queued_commands: Array[Dictionary] = []
var fallback_state: Dictionary = {}
var managed_action_state: Dictionary = {}
var next_command_sequence = 1


func is_empty() -> bool:
	return current_command.is_empty() and queued_commands.is_empty()


func is_current_fallback() -> bool:
	return bool(current_command.get("is_fallback", false))


func has_future_queue_space() -> bool:
	return queued_commands.size() < MAX_FUTURE_COMMANDS


func create_player_command(
		action_type: String,
		planned_duration_hours: int,
		world_time: Dictionary,
		character_id: String,
		resource_inputs_value: Array = []
) -> Dictionary:
	var command = _base_command(action_type, world_time, character_id)
	command["command_id"] = _next_command_id()
	command["source"] = "explicit_player"
	command["planned_duration_hours"] = planned_duration_hours
	command["resource_inputs"] = resource_inputs_value.duplicate(true)
	return command


func create_fallback_command(
		reason: String,
		world_time: Dictionary,
		character_id: String,
		node_risk: String = "low"
) -> Dictionary:
	var action_type = ACTION_FALLBACK_MEDITATE
	if node_risk != "low":
		action_type = ACTION_REST

	var command = _base_command(action_type, world_time, character_id)
	command["command_id"] = _next_fallback_id()
	command["source"] = "system_fallback"
	command["state"] = COMMAND_STATE_RUNNING
	command["is_fallback"] = true
	command["fallback_reason"] = reason
	command["node_risk"] = node_risk
	command["expected_reward_level"] = "very_low" if action_type == ACTION_FALLBACK_MEDITATE else "low"
	command["force_speed"] = "N1"
	command["f1_eligible"] = false
	command["started_world_day"] = int(world_time.get("world_day", 1))
	command["started_world_hour"] = int(world_time.get("world_hour", 0))

	fallback_state = {
		"fallback_id": command.get("command_id", ""),
		"character_id": character_id,
		"started_world_day": command.get("started_world_day", 1),
		"started_world_hour": command.get("started_world_hour", 0),
		"action": action_type,
		"reason": reason,
		"node_risk": node_risk,
		"expected_reward_level": command.get("expected_reward_level", "very_low"),
		"force_speed": "N1",
		"f1_eligible": false,
		"replaced_by_command_ref": "",
	}
	return command


func add_command(command: Dictionary) -> Dictionary:
	if current_command.is_empty() or is_current_fallback():
		if is_current_fallback():
			fallback_state["replaced_by_command_ref"] = str(command.get("command_id", ""))
		current_command = command.duplicate(true)
		return {
			"ok": true,
			"code": "command_set_current",
			"command_id": command.get("command_id", ""),
		}

	if not has_future_queue_space():
		return {
			"ok": false,
			"code": "future_queue_full",
			"error": "Future command queue is full.",
			"max_future_commands": MAX_FUTURE_COMMANDS,
		}

	queued_commands.append(command.duplicate(true))
	return {
		"ok": true,
		"code": "command_queued",
		"command_id": command.get("command_id", ""),
		"future_queue_size": queued_commands.size(),
	}


func pop_next_command() -> Dictionary:
	if queued_commands.is_empty():
		return {}
	return queued_commands.pop_front()


func command_label(command: Dictionary) -> String:
	if command.is_empty():
		return "none"
	return "%s[%s] %d/%d" % [
		command.get("action_type", ""),
		command.get("state", ""),
		int(command.get("elapsed_hours", 0)),
		int(command.get("planned_duration_hours", 0)),
	]


func to_dict() -> Dictionary:
	return {
		"current_command": current_command.duplicate(true),
		"queued_commands": queued_commands.duplicate(true),
		"max_future_commands": MAX_FUTURE_COMMANDS,
		"fallback_state": fallback_state.duplicate(true),
		"managed_action_state": managed_action_state.duplicate(true),
		"next_command_sequence": next_command_sequence,
	}


static func from_dict(data: Dictionary):
	var queue = load("res://src/runtime/command_queue.gd").new()

	var current = data.get("current_command", {})
	if typeof(current) == TYPE_DICTIONARY:
		queue.current_command = current.duplicate(true)

	var queued = data.get("queued_commands", [])
	if typeof(queued) == TYPE_ARRAY:
		for item in queued:
			if typeof(item) == TYPE_DICTIONARY:
				queue.queued_commands.append(item.duplicate(true))

	var fallback = data.get("fallback_state", {})
	if typeof(fallback) == TYPE_DICTIONARY:
		queue.fallback_state = fallback.duplicate(true)

	var managed = data.get("managed_action_state", {})
	if typeof(managed) == TYPE_DICTIONARY:
		queue.managed_action_state = managed.duplicate(true)

	queue.next_command_sequence = int(data.get("next_command_sequence", 1))
	if queue.next_command_sequence < 1:
		queue.next_command_sequence = 1

	return queue


func _base_command(action_type: String, world_time: Dictionary, character_id: String) -> Dictionary:
	return {
		"command_id": "",
		"character_id": character_id,
		"action_type": action_type,
		"source": "explicit_player",
		"state": COMMAND_STATE_PENDING,
		"created_world_day": int(world_time.get("world_day", 1)),
		"created_world_hour": int(world_time.get("world_hour", 0)),
		"started_world_day": 0,
		"started_world_hour": 0,
		"completed_world_day": 0,
		"completed_world_hour": 0,
		"planned_duration_hours": 1,
		"elapsed_hours": 0,
		"compatible_elapsed_hours": 0,
		"resource_inputs": [],
		"f1_eligible": false,
		"is_fallback": false,
		"last_validation": {},
	}


func _next_command_id() -> String:
	var command_id = "cmd_%04d" % next_command_sequence
	next_command_sequence += 1
	return command_id


func _next_fallback_id() -> String:
	var fallback_id = "fallback_%04d" % next_command_sequence
	next_command_sequence += 1
	return fallback_id
