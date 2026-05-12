extends RefCounted
class_name CommandQueue

const MAX_FUTURE_COMMANDS = 3

var current_command: Dictionary = {}
var queued_commands: Array[Dictionary] = []
var fallback_state: Dictionary = {}
var managed_action_state: Dictionary = {}


func is_empty() -> bool:
	return current_command.is_empty() and queued_commands.is_empty()


func to_dict() -> Dictionary:
	return {
		"current_command": current_command.duplicate(true),
		"queued_commands": queued_commands.duplicate(true),
		"max_future_commands": MAX_FUTURE_COMMANDS,
		"fallback_state": fallback_state.duplicate(true),
		"managed_action_state": managed_action_state.duplicate(true),
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

	return queue
