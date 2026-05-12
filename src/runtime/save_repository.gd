extends RefCounted
class_name SaveRepository

const RuntimeConstantsScript = preload("res://src/runtime/runtime_constants.gd")
const RoomStateScript = preload("res://src/runtime/room_state.gd")

const DEFAULT_SAVE_PATH = "user://single_local_smoke_save.json"


func serialize_room(room, save_metadata: Dictionary = {}) -> String:
	var data = room.to_dict()
	if not save_metadata.is_empty():
		data["_save_metadata"] = save_metadata.duplicate(true)
	return JSON.stringify(data, "\t")


func deserialize_room(raw: String) -> Dictionary:
	var parsed_result = _parse_save_root(raw)
	if not bool(parsed_result.get("ok", false)):
		return parsed_result

	var parsed = parsed_result.get("data", {})
	var shape_validation = _validate_save_shape(parsed)
	if not bool(shape_validation.get("ok", false)):
		return shape_validation

	var save_version = int(parsed.get("save_version"))
	if save_version != RuntimeConstantsScript.SAVE_SCHEMA_VERSION:
		return _diagnostic_error(
			"unsupported_save_version",
			"Unsupported save version: %d" % save_version,
			{
				"save_version": save_version,
				"supported_save_version": RuntimeConstantsScript.SAVE_SCHEMA_VERSION,
			}
		)

	var room = RoomStateScript.from_dict(parsed)
	var validation = _validate_loaded_room(room)
	if not bool(validation.get("ok", false)):
		return validation

	var recovery = _recover_room_if_needed(room)
	if not bool(recovery.get("ok", false)):
		return recovery

	return {
		"ok": true,
		"can_continue": true,
		"room": room,
		"recovery": recovery,
	}


func diagnose_save_slot(path: String = DEFAULT_SAVE_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return _diagnostic_error(
			"save_missing",
			"Save file does not exist: %s" % path,
			{
				"path": path,
				"status": "missing",
			}
		)

	var raw = FileAccess.get_file_as_string(path)
	var parsed_result = _parse_save_root(raw)
	if not bool(parsed_result.get("ok", false)):
		parsed_result["path"] = path
		parsed_result["status"] = "unreadable"
		return parsed_result

	var parsed = parsed_result.get("data", {})
	var shape_validation = _validate_save_shape(parsed)
	if not bool(shape_validation.get("ok", false)):
		shape_validation["path"] = path
		shape_validation["status"] = "unreadable"
		return shape_validation

	var summary = _summarize_save_root(parsed, path)
	var save_version = int(parsed.get("save_version"))
	if save_version != RuntimeConstantsScript.SAVE_SCHEMA_VERSION:
		summary.merge(
			_diagnostic_error(
				"unsupported_save_version",
				"Unsupported save version: %d" % save_version,
				{
					"save_version": save_version,
					"supported_save_version": RuntimeConstantsScript.SAVE_SCHEMA_VERSION,
				}
			),
			true
		)
		summary["status"] = "blocked"
		return summary

	var room = RoomStateScript.from_dict(parsed)
	var validation = _validate_loaded_room(room)
	if not bool(validation.get("ok", false)):
		summary.merge(validation, true)
		summary["status"] = "blocked"
		return summary

	summary["ok"] = true
	summary["can_continue"] = true
	summary["code"] = "save_available"
	summary["error"] = ""
	if bool(summary.get("recovery_needed", false)):
		summary["code"] = "save_recovery_available"
		summary["status"] = "recovery_available"
	return summary


func save_room(room, path: String = DEFAULT_SAVE_PATH) -> Dictionary:
	var saved_at_unix = int(Time.get_unix_time_from_system())
	var metadata = {
		"app_version": RuntimeConstantsScript.APP_VERSION,
		"saved_at_unix": saved_at_unix,
		"save_path": path,
	}

	room.replay_log.append_event(
		"room_save_requested",
		room.world_time.to_dict(),
		{
			"path": path,
			"save_version": room.save_version,
			"active_state": room.active_state,
		}
	)

	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return _diagnostic_error(
			"save_open_failed",
			"Unable to open save path: %s" % path,
			{
				"path": path,
			}
		)

	file.store_string(serialize_room(room, metadata))
	return {
		"ok": true,
		"can_continue": true,
		"path": path,
		"save_version": room.save_version,
		"world_time": room.world_time.to_dict(),
		"active_state": room.active_state,
		"saved_at_unix": saved_at_unix,
	}


func load_room(path: String = DEFAULT_SAVE_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return diagnose_save_slot(path)

	var raw = FileAccess.get_file_as_string(path)
	var result = deserialize_room(raw)
	if bool(result.get("ok", false)):
		var room = result.get("room", null)
		if room != null:
			room.replay_log.append_event(
				"room_loaded",
				room.world_time.to_dict(),
				{
					"path": path,
					"recovery": result.get("recovery", {}),
				}
			)
	result["path"] = path
	return result


func _validate_loaded_room(room) -> Dictionary:
	if room.mode != RuntimeConstantsScript.ROOM_MODE_SINGLE_LOCAL:
		return _diagnostic_error(
			"unsupported_room_mode",
			"MVP-1 can only load single_local saves.",
			{
				"mode": room.mode,
			}
		)

	if room.save_lineage != RuntimeConstantsScript.SAVE_LINEAGE_SINGLE:
		return _diagnostic_error(
			"unsupported_save_lineage",
			"MVP-1 can only load single_only save lineage.",
			{
				"save_lineage": room.save_lineage,
			}
		)

	var supported_states = [
		RuntimeConstantsScript.ROOM_ACTIVE_STATE,
		RuntimeConstantsScript.ROOM_SETTLEMENT_IN_PROGRESS_STATE,
	]
	if not supported_states.has(room.active_state):
		return _diagnostic_error(
			"unsupported_active_state",
			"Unsupported room active state: %s" % room.active_state,
			{
				"active_state": room.active_state,
			}
		)

	return {
		"ok": true,
		"can_continue": true,
	}


func _recover_room_if_needed(room) -> Dictionary:
	var recovery = {
		"ok": true,
		"recovered": false,
		"from_active_state": room.active_state,
		"to_active_state": room.active_state,
		"strategy": "none",
	}

	if room.active_state == RuntimeConstantsScript.ROOM_SETTLEMENT_IN_PROGRESS_STATE:
		recovery["recovered"] = true
		recovery["to_active_state"] = RuntimeConstantsScript.ROOM_ACTIVE_STATE
		recovery["strategy"] = RuntimeConstantsScript.RECOVERY_STRATEGY_LAST_COMMITTED_SNAPSHOT
		room.active_state = RuntimeConstantsScript.ROOM_ACTIVE_STATE
		room.replay_log.append_event(
			"room_recovered",
			room.world_time.to_dict(),
			recovery
		)

	room.last_recovery_status = recovery.duplicate(true)
	return recovery


func _parse_save_root(raw: String) -> Dictionary:
	if raw.strip_edges().is_empty():
		return _diagnostic_error(
			"empty_save_file",
			"Save data is empty."
		)

	var json = JSON.new()
	var parse_error = json.parse(raw)
	if parse_error != OK:
		return _diagnostic_error(
			"invalid_json",
			"Save data is invalid JSON: %s" % json.get_error_message(),
			{
				"parse_error_line": json.get_error_line(),
			}
		)

	var parsed = json.data
	if typeof(parsed) != TYPE_DICTIONARY:
		return _diagnostic_error(
			"invalid_json",
			"Save data is not a JSON object."
		)

	return {
		"ok": true,
		"data": parsed,
	}


func _validate_save_shape(data: Dictionary) -> Dictionary:
	var root_specs = [
		{"field": "save_version", "types": [TYPE_INT, TYPE_FLOAT]},
		{"field": "room_id", "types": [TYPE_STRING]},
		{"field": "room_name", "types": [TYPE_STRING]},
		{"field": "mode", "types": [TYPE_STRING]},
		{"field": "world_seed", "types": [TYPE_INT, TYPE_FLOAT]},
		{"field": "save_lineage", "types": [TYPE_STRING]},
		{"field": "active_state", "types": [TYPE_STRING]},
		{"field": "speed_state", "types": [TYPE_STRING]},
		{"field": "world_time", "types": [TYPE_DICTIONARY]},
		{"field": "command_queue", "types": [TYPE_DICTIONARY]},
		{"field": "character_state", "types": [TYPE_DICTIONARY]},
		{"field": "replay_log", "types": [TYPE_ARRAY]},
		{"field": "result_history", "types": [TYPE_ARRAY]},
		{"field": "rng_cursor", "types": [TYPE_INT, TYPE_FLOAT]},
		{"field": "next_result_sequence", "types": [TYPE_INT, TYPE_FLOAT]},
	]

	for spec in root_specs:
		var field_name = str(spec.get("field", ""))
		var field_validation = _validate_typed_field(data, field_name, spec.get("types", []))
		if not bool(field_validation.get("ok", false)):
			return field_validation

	var time_data = data.get("world_time", {})
	for field_name in ["world_day", "world_hour"]:
		var time_validation = _validate_typed_field(time_data, field_name, [TYPE_INT, TYPE_FLOAT], "world_time.%s" % field_name)
		if not bool(time_validation.get("ok", false)):
			return time_validation

	var world_day = int(time_data.get("world_day"))
	var world_hour = int(time_data.get("world_hour"))
	if world_day < 1:
		return _diagnostic_error(
			"invalid_world_time",
			"Save field world_time.world_day must be at least 1.",
			{
				"field": "world_time.world_day",
				"value": world_day,
			}
		)

	if world_hour < 0 or world_hour >= 24:
		return _diagnostic_error(
			"invalid_world_time",
			"Save field world_time.world_hour must be between 0 and 23.",
			{
				"field": "world_time.world_hour",
				"value": world_hour,
			}
		)

	return {
		"ok": true,
		"can_continue": true,
	}


func _validate_typed_field(data: Dictionary, field_name: String, accepted_types: Array, diagnostic_name: String = "") -> Dictionary:
	var output_name = diagnostic_name
	if output_name.is_empty():
		output_name = field_name

	if not data.has(field_name):
		return _diagnostic_error(
			"missing_required_field",
			"Save field is missing: %s" % output_name,
			{
				"field": output_name,
			}
		)

	var value_type = typeof(data.get(field_name))
	if not accepted_types.has(value_type):
		return _diagnostic_error(
			"invalid_field_type",
			"Save field has invalid type: %s" % output_name,
			{
				"field": output_name,
				"actual_type": _type_name(value_type),
				"expected_types": _type_names(accepted_types),
			}
		)

	return {
		"ok": true,
		"can_continue": true,
	}


func _summarize_save_root(data: Dictionary, path: String) -> Dictionary:
	var metadata = data.get("_save_metadata", {})
	if typeof(metadata) != TYPE_DICTIONARY:
		metadata = {}

	var world_time = data.get("world_time", {})
	var active_state = str(data.get("active_state", ""))
	return {
		"ok": false,
		"can_continue": false,
		"code": "save_unchecked",
		"error": "",
		"path": path,
		"status": "available",
		"room_id": str(data.get("room_id", "")),
		"room_name": str(data.get("room_name", "")),
		"mode": str(data.get("mode", "")),
		"save_lineage": str(data.get("save_lineage", "")),
		"save_version": int(data.get("save_version")),
		"supported_save_version": RuntimeConstantsScript.SAVE_SCHEMA_VERSION,
		"world_seed": int(data.get("world_seed")),
		"active_state": active_state,
		"speed_state": str(data.get("speed_state", "")),
		"world_time": world_time.duplicate(true),
		"saved_at_unix": int(metadata.get("saved_at_unix", 0)),
		"saved_by_app_version": str(metadata.get("app_version", "")),
		"recovery_needed": active_state == RuntimeConstantsScript.ROOM_SETTLEMENT_IN_PROGRESS_STATE,
		"recovery_strategy": RuntimeConstantsScript.RECOVERY_STRATEGY_LAST_COMMITTED_SNAPSHOT if active_state == RuntimeConstantsScript.ROOM_SETTLEMENT_IN_PROGRESS_STATE else "none",
	}


func _diagnostic_error(code: String, error: String, extra: Dictionary = {}) -> Dictionary:
	var result = {
		"ok": false,
		"can_continue": false,
		"code": code,
		"error": error,
	}
	for key in extra.keys():
		result[key] = extra.get(key)
	return result


func _type_names(types: Array) -> Array[String]:
	var names: Array[String] = []
	for type_id in types:
		names.append(_type_name(int(type_id)))
	return names


func _type_name(type_id: int) -> String:
	match type_id:
		TYPE_NIL:
			return "nil"
		TYPE_BOOL:
			return "bool"
		TYPE_INT:
			return "int"
		TYPE_FLOAT:
			return "float"
		TYPE_STRING:
			return "string"
		TYPE_DICTIONARY:
			return "dictionary"
		TYPE_ARRAY:
			return "array"
		_:
			return "type_%d" % type_id
