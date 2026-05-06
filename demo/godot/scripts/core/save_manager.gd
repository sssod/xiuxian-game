extends RefCounted

const DemoConstants = preload("res://scripts/core/demo_constants.gd")

const SAVE_DIR := "res://runtime/saves"
const REPLAY_DIR := "res://runtime/replays"

static func save_game(runtime: Dictionary, slot_name := "phase_a_demo") -> Dictionary:
	var dir_result := _ensure_dir(SAVE_DIR)
	if not dir_result["ok"]:
		return dir_result

	var path := "%s/%s.json" % [SAVE_DIR, slot_name]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "path": path, "error": "Cannot open save path for writing."}

	var save_payload := runtime.duplicate(true)
	save_payload["saved_at_unix"] = int(Time.get_unix_time_from_system())
	save_payload["schema_version"] = DemoConstants.SCHEMA_VERSION
	save_payload["content_version"] = DemoConstants.CONTENT_VERSION
	file.store_string(JSON.stringify(save_payload, "\t"))
	return {"ok": true, "path": ProjectSettings.globalize_path(path), "error": ""}

static func load_game(slot_name := "phase_a_demo") -> Dictionary:
	var path := "%s/%s.json" % [SAVE_DIR, slot_name]
	if not FileAccess.file_exists(path):
		return {"ok": false, "runtime": {}, "path": ProjectSettings.globalize_path(path), "error": "Save file does not exist."}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "runtime": {}, "path": ProjectSettings.globalize_path(path), "error": "Cannot read save file."}

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"ok": false, "runtime": {}, "path": ProjectSettings.globalize_path(path), "error": "Save JSON is invalid."}

	return {"ok": true, "runtime": parsed, "path": ProjectSettings.globalize_path(path), "error": ""}

static func write_replay(replay: Dictionary) -> Dictionary:
	if replay.is_empty():
		return {"ok": false, "path": "", "error": "Replay is empty."}

	var dir_result := _ensure_dir(REPLAY_DIR)
	if not dir_result["ok"]:
		return dir_result

	var replay_id := str(replay.get("replay_id", "turn_replay"))
	var path := "%s/%s.json" % [REPLAY_DIR, replay_id]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "path": ProjectSettings.globalize_path(path), "error": "Cannot open replay path for writing."}

	file.store_string(JSON.stringify(replay, "\t"))
	return {"ok": true, "path": ProjectSettings.globalize_path(path), "error": ""}

static func _ensure_dir(path: String) -> Dictionary:
	var absolute_path := ProjectSettings.globalize_path(path)
	if DirAccess.dir_exists_absolute(absolute_path):
		return {"ok": true, "path": absolute_path, "error": ""}
	var error := DirAccess.make_dir_recursive_absolute(absolute_path)
	if error != OK:
		return {"ok": false, "path": absolute_path, "error": "Cannot create directory. Error code: %d" % error}
	return {"ok": true, "path": absolute_path, "error": ""}
