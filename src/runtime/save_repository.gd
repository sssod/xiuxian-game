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
			"error": "Save data is not a JSON object.",
		}

	var save_version = int(parsed.get("save_version", -1))
	if save_version != RuntimeConstantsScript.SAVE_SCHEMA_VERSION:
		return {
			"ok": false,
			"error": "Unsupported save version: %d" % save_version,
		}

	return {
		"ok": true,
		"room": RoomStateScript.from_dict(parsed),
	}


func save_room(room, path: String = DEFAULT_SAVE_PATH) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {
			"ok": false,
			"error": "Unable to open save path: %s" % path,
		}

	file.store_string(serialize_room(room))
	return {
		"ok": true,
		"path": path,
	}


func load_room(path: String = DEFAULT_SAVE_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {
			"ok": false,
			"error": "Save file does not exist: %s" % path,
		}

	var raw = FileAccess.get_file_as_string(path)
	return deserialize_room(raw)
