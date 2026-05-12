extends RefCounted
class_name SaveRepository

const RuntimeConstantsScript = preload("res://src/runtime/runtime_constants.gd")
const RoomStateScript = preload("res://src/runtime/room_state.gd")

const DEFAULT_SAVE_PATH = "user://single_local_smoke_save.json"


func serialize_room(room) -> String:
	return JSON.stringify(room.to_dict(), "\t")


func deserialize_room(raw: String) -> Dictionary:
	var parsed = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {
			"ok": false,
			"code": "invalid_json",
			"error": "Save data is not a JSON object.",
		}

	var save_version = int(parsed.get("save_version", -1))
	if save_version != RuntimeConstantsScript.SAVE_SCHEMA_VERSION:
		return {
			"ok": false,
			"code": "unsupported_save_version",
			"error": "Unsupported save version: %d" % save_version,
			"save_version": save_version,
			"supported_save_version": RuntimeConstantsScript.SAVE_SCHEMA_VERSION,
		}

	var room = RoomStateScript.from_dict(parsed)
	var validation = _validate_loaded_room(room)
	if not bool(validation.get("ok", false)):
		return validation

	var recovery = _recover_room_if_needed(room)
	if not bool(recovery.get("ok", false)):
		return recovery

	return {
		"ok": true,
		"room": room,
		"recovery": recovery,
	}


func save_room(room, path: String = DEFAULT_SAVE_PATH) -> Dictionary:
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
		return {
			"ok": false,
			"code": "save_open_failed",
			"error": "Unable to open save path: %s" % path,
		}

	file.store_string(serialize_room(room))
	return {
		"ok": true,
		"path": path,
		"save_version": room.save_version,
		"world_time": room.world_time.to_dict(),
		"active_state": room.active_state,
	}


func load_room(path: String = DEFAULT_SAVE_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {
			"ok": false,
			"code": "save_missing",
			"error": "Save file does not exist: %s" % path,
		}

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
		return {
			"ok": false,
			"code": "unsupported_room_mode",
			"error": "MVP-1 can only load single_local saves.",
			"mode": room.mode,
		}

	if room.save_lineage != RuntimeConstantsScript.SAVE_LINEAGE_SINGLE:
		return {
			"ok": false,
			"code": "unsupported_save_lineage",
			"error": "MVP-1 can only load single_only save lineage.",
			"save_lineage": room.save_lineage,
		}

	var supported_states = [
		RuntimeConstantsScript.ROOM_ACTIVE_STATE,
		RuntimeConstantsScript.ROOM_SETTLEMENT_IN_PROGRESS_STATE,
	]
	if not supported_states.has(room.active_state):
		return {
			"ok": false,
			"code": "unsupported_active_state",
			"error": "Unsupported room active state: %s" % room.active_state,
			"active_state": room.active_state,
		}

	return {
		"ok": true,
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
