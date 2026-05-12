extends RefCounted
class_name ReplayLog

var entries: Array[Dictionary] = []


func append_event(event_type: String, world_time: Dictionary, data: Dictionary = {}) -> Dictionary:
	var entry = {
		"index": entries.size() + 1,
		"event_type": event_type,
		"world_time": world_time.duplicate(true),
		"data": data.duplicate(true),
	}
	entries.append(entry)
	return entry


func to_array() -> Array[Dictionary]:
	return entries.duplicate(true)


static func from_array(data: Array):
	var log = load("res://src/runtime/replay_log.gd").new()
	for item in data:
		if typeof(item) == TYPE_DICTIONARY:
			log.entries.append(item.duplicate(true))
	return log
