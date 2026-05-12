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


func get_cultivation_balance_config() -> Dictionary:
	var balance = config.get("cultivation_balance", {})
	if typeof(balance) != TYPE_DICTIONARY:
		return {}
	return balance.duplicate(true)


func get_action_profile(action_type: String) -> Dictionary:
	var balance = config.get("cultivation_balance", {})
	if typeof(balance) != TYPE_DICTIONARY:
		return {}

	var profiles = balance.get("action_profiles", {})
	if typeof(profiles) != TYPE_DICTIONARY:
		return {}

	var profile = profiles.get(action_type, {})
	if typeof(profile) != TYPE_DICTIONARY:
		return {}
	return profile.duplicate(true)


func get_action_min_duration(action_type: String, fallback: int = 1) -> int:
	var profile = get_action_profile(action_type)
	if profile.is_empty():
		return fallback
	var duration = int(profile.get("min_duration_hours", fallback))
	if duration < 1:
		return 1
	return duration


func get_default_method_study_target() -> String:
	var profile = get_action_profile("method_study")
	return str(profile.get("default_target_method_id", ""))


func get_default_resource_input_item() -> String:
	var balance = config.get("cultivation_balance", {})
	if typeof(balance) != TYPE_DICTIONARY:
		return "clear_qi_pill_mvp"
	return str(balance.get("default_resource_input_item", "clear_qi_pill_mvp"))


func get_resource_effect_template(resource_effect_template_id: String) -> Dictionary:
	var balance = config.get("cultivation_balance", {})
	if typeof(balance) != TYPE_DICTIONARY:
		return {}

	var templates = balance.get("resource_effect_templates", {})
	if typeof(templates) != TYPE_DICTIONARY:
		return {}

	var template = templates.get(resource_effect_template_id, {})
	if typeof(template) != TYPE_DICTIONARY:
		return {}
	var output = template.duplicate(true)
	output["resource_effect_template_id"] = resource_effect_template_id
	return output


func get_realm_segment(segment_id: String) -> Dictionary:
	var balance = config.get("cultivation_balance", {})
	if typeof(balance) != TYPE_DICTIONARY:
		return {}

	var segments = balance.get("realm_segments", [])
	if typeof(segments) != TYPE_ARRAY:
		return {}

	for segment in segments:
		if typeof(segment) == TYPE_DICTIONARY and str(segment.get("segment_id", "")) == segment_id:
			return segment.duplicate(true)

	return {}
