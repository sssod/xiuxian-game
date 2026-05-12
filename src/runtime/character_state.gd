extends RefCounted
class_name CharacterState

var character_id = ""
var true_spirit_id = ""
var initialized = false
var true_spirit_state: Dictionary = {}
var identity: Dictionary = {}
var base_attributes: Dictionary = {}
var aptitude_profile: Dictionary = {}
var derived_bars: Dictionary = {}
var lifespan_state: Dictionary = {}
var cultivation_state: Dictionary = {}
var initial_logs: Array[String] = []


func initialize_first_entry(config: Dictionary, world_seed: int, world_time: Dictionary) -> Dictionary:
	if initialized:
		return {
			"ok": false,
			"code": "character_already_initialized",
			"error": "Current-life character is already initialized.",
		}

	var true_spirit_config = _dict_value(config, "true_spirit")
	var current_life_config = _dict_value(config, "current_life")
	var base_config = _dict_value(config, "base_attributes")
	var aptitude_config = _dict_value(config, "aptitude_profile")
	var bars_config = _dict_value(config, "derived_bars")
	var cultivation_config = _dict_value(config, "cultivation_state")

	true_spirit_id = str(true_spirit_config.get("spirit_id", "true_spirit_%d" % world_seed))
	character_id = str(current_life_config.get("character_id", "character_%d_01" % world_seed))
	initialized = true

	true_spirit_state = {
		"spirit_id": true_spirit_id,
		"true_name": str(true_spirit_config.get("true_name", "Unnamed Spirit")),
		"true_name_mode": str(true_spirit_config.get("true_name_mode", "custom")),
		"story_line_id": str(true_spirit_config.get("story_line_id", "story_generic_weak")),
		"story_line_type": str(true_spirit_config.get("story_line_type", "generic_weak")),
		"incarnation_count": int(true_spirit_config.get("incarnation_count", 1)),
		"true_name_visibility": str(true_spirit_config.get("true_name_visibility", "hidden")),
	}

	var age = int(current_life_config.get("age", 16))
	var lifespan_limit = int(current_life_config.get("lifespan_limit", 80))
	if lifespan_limit < 1:
		lifespan_limit = 1

	identity = {
		"character_id": character_id,
		"true_spirit_id": true_spirit_id,
		"character_name": str(current_life_config.get("character_name", "Unnamed Vessel")),
		"gender": str(current_life_config.get("gender", "unspecified")),
		"init_context": str(current_life_config.get("init_context", "first_entry")),
		"birth_region_id": str(current_life_config.get("birth_region_id", "")),
		"birth_location_id": str(current_life_config.get("birth_location_id", "")),
		"appearance_profile_id": str(current_life_config.get("appearance_profile_id", "mvp_placeholder")),
		"initial_material_package_ids": _string_array(current_life_config.get("initial_material_package_ids", [])),
		"has_secular_background_identity": bool(current_life_config.get("has_secular_background_identity", false)),
	}

	lifespan_state = {
		"age": age,
		"lifespan_limit": lifespan_limit,
		"lifespan_extension_sources": [],
	}

	base_attributes = {
		"base_physique": _attribute_record(int(base_config.get("base_physique", 10))),
		"base_vigor": _attribute_record(int(base_config.get("base_vigor", 10))),
	}

	aptitude_profile = {
		"aptitude_bone": _attribute_record(int(aptitude_config.get("aptitude_bone", 10))),
		"aptitude_comprehension": _attribute_record(int(aptitude_config.get("aptitude_comprehension", 10))),
		"aptitude_root": {
			"innate_value": int(aptitude_config.get("aptitude_root", 1)),
			"effective_value": int(aptitude_config.get("aptitude_root", 1)),
		},
		"root_affinity_tags": _string_array(aptitude_config.get("root_affinity_tags", [])),
		"aptitude_rating_visibility": str(aptitude_config.get("aptitude_rating_visibility", "revealed")),
	}

	derived_bars = {
		"vitality": _bar_record(int(bars_config.get("bar_vitality_max", 100))),
		"qi": _bar_record(int(bars_config.get("bar_qi_max", 80))),
		"mind": _bar_record(int(bars_config.get("bar_mind_max", 60))),
	}

	cultivation_state = {
		"character_id": character_id,
		"realm": str(cultivation_config.get("realm", "qi_refining")),
		"minor_stage": str(cultivation_config.get("minor_stage", "qi_refining_1")),
		"current_realm_segment_id": str(cultivation_config.get("current_realm_segment_id", "qi_refining_1")),
		"cultivation_points": float(cultivation_config.get("cultivation_points", 0.0)),
		"normalized_segment_progress": float(cultivation_config.get("normalized_segment_progress", 0.0)),
		"bottleneck_state": str(cultivation_config.get("bottleneck_state", "none")),
		"foundation_quality": float(cultivation_config.get("foundation_quality", 0.5)),
		"meridian_pressure": float(cultivation_config.get("meridian_pressure", 0.0)),
		"resource_aura_input": 0.0,
		"last_settled_world_day": int(world_time.get("world_day", 1)),
		"last_settled_world_hour": int(world_time.get("world_hour", 0)),
	}

	initial_logs = [
		"True spirit initialized: %s." % true_spirit_state.get("true_name", ""),
		"Current life initialized without secular background identity.",
	]

	return {
		"ok": true,
		"code": "character_initialized",
		"character_id": character_id,
		"true_spirit_id": true_spirit_id,
		"summary": summary(),
	}


func summary() -> String:
	if not initialized:
		return "No current-life character initialized."
	return "%s | %s %s | age %d/%d | CP %.1f" % [
		identity.get("character_name", ""),
		cultivation_state.get("realm", ""),
		cultivation_state.get("minor_stage", ""),
		lifespan_state.get("age", 0),
		lifespan_state.get("lifespan_limit", 0),
		cultivation_state.get("cultivation_points", 0.0),
	]


func to_dict() -> Dictionary:
	return {
		"character_id": character_id,
		"true_spirit_id": true_spirit_id,
		"initialized": initialized,
		"true_spirit_state": true_spirit_state.duplicate(true),
		"identity": identity.duplicate(true),
		"base_attributes": base_attributes.duplicate(true),
		"aptitude_profile": aptitude_profile.duplicate(true),
		"derived_bars": derived_bars.duplicate(true),
		"lifespan_state": lifespan_state.duplicate(true),
		"cultivation_state": cultivation_state.duplicate(true),
		"initial_logs": initial_logs.duplicate(),
	}


static func from_dict(data: Dictionary):
	var state = load("res://src/runtime/character_state.gd").new()
	state.character_id = str(data.get("character_id", ""))
	state.true_spirit_id = str(data.get("true_spirit_id", ""))
	state.initialized = bool(data.get("initialized", false))

	var true_spirit_data = data.get("true_spirit_state", {})
	if typeof(true_spirit_data) == TYPE_DICTIONARY:
		state.true_spirit_state = true_spirit_data.duplicate(true)

	var identity_data = data.get("identity", {})
	if typeof(identity_data) == TYPE_DICTIONARY:
		state.identity = identity_data.duplicate(true)

	var base_data = data.get("base_attributes", {})
	if typeof(base_data) == TYPE_DICTIONARY:
		state.base_attributes = base_data.duplicate(true)

	var aptitude_data = data.get("aptitude_profile", {})
	if typeof(aptitude_data) == TYPE_DICTIONARY:
		state.aptitude_profile = aptitude_data.duplicate(true)

	var bars_data = data.get("derived_bars", {})
	if typeof(bars_data) == TYPE_DICTIONARY:
		state.derived_bars = bars_data.duplicate(true)

	var lifespan_data = data.get("lifespan_state", {})
	if typeof(lifespan_data) == TYPE_DICTIONARY:
		state.lifespan_state = lifespan_data.duplicate(true)

	var cultivation_data = data.get("cultivation_state", {})
	if typeof(cultivation_data) == TYPE_DICTIONARY:
		state.cultivation_state = cultivation_data.duplicate(true)

	var logs_data = data.get("initial_logs", [])
	if typeof(logs_data) == TYPE_ARRAY:
		for item in logs_data:
			state.initial_logs.append(str(item))

	return state


static func _attribute_record(innate_value: int) -> Dictionary:
	return {
		"innate_value": innate_value,
		"acquired_permanent_delta": 0,
		"temporary_modifiers_total": 0,
		"effective_value": innate_value,
	}


static func _bar_record(max_value: int) -> Dictionary:
	if max_value < 1:
		max_value = 1
	return {
		"current": max_value,
		"max": max_value,
		"reserve": 0,
	}


static func _dict_value(data: Dictionary, key: String) -> Dictionary:
	var value = data.get(key, {})
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	return value


static func _string_array(value) -> Array[String]:
	var output: Array[String] = []
	if typeof(value) != TYPE_ARRAY:
		return output
	for item in value:
		output.append(str(item))
	return output
