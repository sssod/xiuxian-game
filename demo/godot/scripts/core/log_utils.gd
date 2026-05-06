extends RefCounted

static func visible(kind: String, message: String, turn_id: int, world_day: int, world_hour: int) -> Dictionary:
	return {
		"entry_id": _entry_id("visible", kind, turn_id, world_hour),
		"kind": kind,
		"message": message,
		"turn_id": turn_id,
		"world_day": world_day,
		"world_hour": world_hour,
		"visibility": "player"
	}

static func debug(kind: String, message: String, turn_id: int, world_hour: int, payload := {}) -> Dictionary:
	return {
		"entry_id": _entry_id("debug", kind, turn_id, world_hour),
		"kind": kind,
		"message": message,
		"turn_id": turn_id,
		"world_hour": world_hour,
		"payload": payload
	}

static func _entry_id(scope: String, kind: String, turn_id: int, world_hour: int) -> String:
	var stamp := int(Time.get_unix_time_from_system() * 1000.0)
	return "%s_%s_t%03d_h%06d_%d" % [scope, kind, turn_id, world_hour, stamp]
