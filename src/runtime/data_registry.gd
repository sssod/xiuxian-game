extends RefCounted
class_name DataRegistry

const RuntimeConstantsScript = preload("res://src/runtime/runtime_constants.gd")

var config: Dictionary = {}
var config_loaded = false
var config_path = ""
var error_message = ""


func load_config(path: String = RuntimeConstantsScript.DEFAULT_CONFIG_PATH) -> Dictionary:
	config_path = path
	config_loaded = false
	error_message = ""
	config = {}

	if not FileAccess.file_exists(path):
		error_message = "Config file does not exist: %s" % path
		return status()

	var raw = FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		error_message = "Config file is not a JSON object: %s" % path
		return status()

	config = parsed
	config_loaded = true
	return status()


func status() -> Dictionary:
	return {
		"ok": config_loaded,
		"path": config_path,
		"error": error_message,
		"build_label": get_build_label(),
		"default_world_seed": get_default_world_seed(),
	}


func get_build_label() -> String:
	return str(config.get("build_label", "unloaded"))


func get_default_world_seed() -> int:
	return int(config.get("default_world_seed", RuntimeConstantsScript.DEFAULT_WORLD_SEED))


func get_smoke_room_name() -> String:
	var smoke = config.get("smoke", {})
	if typeof(smoke) != TYPE_DICTIONARY:
		return "Local Smoke Room"
	return str(smoke.get("room_name", "Local Smoke Room"))


func get_smoke_post_load_f1_hours() -> int:
	var smoke = config.get("smoke", {})
	if typeof(smoke) != TYPE_DICTIONARY:
		return 3
	var hours = int(smoke.get("post_load_f1_hours", 3))
	if hours < 1:
		return 1
	return hours


func get_character_init_config() -> Dictionary:
	var character_init = config.get("character_init", {})
	if typeof(character_init) != TYPE_DICTIONARY:
		return {}
	return character_init.duplicate(true)
