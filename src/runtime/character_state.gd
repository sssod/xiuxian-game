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
var method_states: Dictionary = {}
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
	var method_state_configs = _array_value(config.get("method_states", []))

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

	method_states = _method_states_from_config(method_state_configs, world_time)

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
		"method_states": method_states.duplicate(true),
	}


func summary() -> String:
	if not initialized:
		return "No current-life character initialized."
	return "%s | %s %s | age %d/%d | CP %.1f | progress %.1f%%" % [
		identity.get("character_name", ""),
		cultivation_state.get("realm", ""),
		cultivation_state.get("minor_stage", ""),
		lifespan_state.get("age", 0),
		lifespan_state.get("lifespan_limit", 0),
		cultivation_state.get("cultivation_points", 0.0),
		float(cultivation_state.get("normalized_segment_progress", 0.0)) * 100.0,
	]


func has_method_state(method_id: String) -> bool:
	return method_states.has(method_id)


func get_method_state(method_id: String) -> Dictionary:
	var state = method_states.get(method_id, {})
	if typeof(state) != TYPE_DICTIONARY:
		return {}
	return state.duplicate(true)


func apply_cultivation_tick(
		segment: Dictionary,
		action_profile: Dictionary,
		command: Dictionary,
		world_time: Dictionary
) -> Dictionary:
	if not initialized:
		return {
			"ok": false,
			"code": "character_not_initialized",
			"error": "Cannot settle cultivation without an initialized character.",
		}

	if segment.is_empty():
		return {
			"ok": false,
			"code": "missing_realm_segment",
			"error": "Current realm segment is not configured.",
		}

	if action_profile.is_empty():
		return {
			"ok": false,
			"code": "missing_action_profile",
			"error": "Action profile is not configured.",
		}

	var policy = str(action_profile.get("compatible_hour_policy", "none"))
	var compatible_hours = 1.0 if policy == "full" else 0.0
	var before_cp = float(cultivation_state.get("cultivation_points", 0.0))
	var before_progress = float(cultivation_state.get("normalized_segment_progress", 0.0))
	var before_pressure = float(cultivation_state.get("meridian_pressure", 0.0))
	var before_foundation = float(cultivation_state.get("foundation_quality", 0.5))
	var bar_recovery_summary = {}

	var target_hours = maxf(float(segment.get("target_elapsed_hours_standard", 1.0)), 1.0)
	var expected_ratio = maxf(float(segment.get("expected_cultivation_hour_ratio", 1.0)), 0.01)
	var required_progress = maxf(float(segment.get("required_normalized_progress", 1.0)), 0.01)
	var base_benchmark_rate = required_progress / (target_hours * expected_ratio)
	var calendar_benchmark_rate = required_progress / target_hours
	var raw_efficiency_ratio = float(action_profile.get("base_efficiency_ratio", 0.0))
	var min_efficiency_ratio = float(segment.get("min_efficiency_ratio", 0.0))
	var max_efficiency_ratio = float(segment.get("max_efficiency_ratio", 1.0))
	var clamped_efficiency_ratio = clampf(raw_efficiency_ratio, min_efficiency_ratio, max_efficiency_ratio)
	var normalized_gain = base_benchmark_rate * clamped_efficiency_ratio * compatible_hours
	var raw_required = maxf(float(segment.get("raw_cultivation_required", _segment_cp_width(segment))), 0.0)
	var cp_gain = normalized_gain * raw_required

	var action_type = str(action_profile.get("action_type", command.get("action_type", "")))
	var pressure_delta = 0.0
	var foundation_delta = 0.0
	if policy == "none":
		cp_gain = 0.0
		normalized_gain = 0.0

	if action_type == "consolidation" or action_type == "rest":
		pressure_delta = -float(action_profile.get("pressure_recovery_per_hour", 0.0))
	else:
		var over_rate = maxf(0.0, clamped_efficiency_ratio - 1.0)
		pressure_delta = over_rate * float(action_profile.get("pressure_from_overbenchmark_rate", 0.0))

	if action_type == "consolidation":
		foundation_delta = maxf(float(action_profile.get("foundation_quality_gain_per_hour", 0.0)), 0.0)

	if action_type == "rest":
		bar_recovery_summary = _apply_bar_recovery(action_profile)

	var after_cp = before_cp + cp_gain
	var after_pressure = clampf(before_pressure + pressure_delta, 0.0, 1.0)
	var after_foundation = clampf(before_foundation + foundation_delta, 0.0, 1.0)

	cultivation_state["cultivation_points"] = after_cp
	cultivation_state["normalized_segment_progress"] = _progress_for_segment(segment, after_cp)
	cultivation_state["meridian_pressure"] = after_pressure
	cultivation_state["foundation_quality"] = after_foundation
	cultivation_state["last_settled_world_day"] = int(world_time.get("world_day", 1))
	cultivation_state["last_settled_world_hour"] = int(world_time.get("world_hour", 0))
	cultivation_state["resource_aura_input"] = 0.0

	var visible_summary = "%s settled: +%.2f CP, progress %.1f%%." % [
		str(action_profile.get("display_name", action_type)),
		cp_gain,
		float(cultivation_state.get("normalized_segment_progress", 0.0)) * 100.0,
	]
	if action_type == "consolidation":
		visible_summary = "%s settled: pressure %.1f%% -> %.1f%%, foundation %.1f%% -> %.1f%%." % [
			str(action_profile.get("display_name", action_type)),
			before_pressure * 100.0,
			after_pressure * 100.0,
			before_foundation * 100.0,
			after_foundation * 100.0,
		]
	elif action_type == "rest":
		visible_summary = "%s settled: pressure %.1f%% -> %.1f%%." % [
			str(action_profile.get("display_name", action_type)),
			before_pressure * 100.0,
			after_pressure * 100.0,
		]

	return {
		"ok": true,
		"world_day": int(world_time.get("world_day", 1)),
		"world_hour": int(world_time.get("world_hour", 0)),
		"segment_id": segment.get("segment_id", ""),
		"command_id": command.get("command_id", ""),
		"action_type": action_type,
		"compatible_hours": compatible_hours,
		"base_benchmark_rate": base_benchmark_rate,
		"calendar_benchmark_rate": calendar_benchmark_rate,
		"raw_efficiency_ratio": raw_efficiency_ratio,
		"clamped_efficiency_ratio": clamped_efficiency_ratio,
		"normalized_gain": normalized_gain,
		"cultivation_points_gain": cp_gain,
		"normalized_segment_progress_before": before_progress,
		"normalized_segment_progress_after": cultivation_state.get("normalized_segment_progress", 0.0),
		"cultivation_points_before": before_cp,
		"cultivation_points_after": after_cp,
		"meridian_pressure_delta": after_pressure - before_pressure,
		"method_mastery_delta": 0.0,
		"foundation_quality_delta": float(cultivation_state.get("foundation_quality", 0.0)) - before_foundation,
		"purity_delta": 0.0,
		"bar_recovery_summary": bar_recovery_summary,
		"resource_effects_consumed": [],
		"active_resource_effect_delta": [],
		"resource_use_log_refs": [],
		"node_aura_effect": {},
		"facility_effect": {},
		"sect_support_effect": {},
		"state_pressure_delta": {
			"meridian_pressure_before": before_pressure,
			"meridian_pressure_after": after_pressure,
		},
		"breakthrough_readiness_delta": {
			"can_trigger_major_breakthrough": false,
		},
		"visible_summary": visible_summary,
		"debug_formula_trace": {
			"compatible_hour_benchmark_rate": base_benchmark_rate,
			"raw_efficiency_ratio": raw_efficiency_ratio,
			"clamped_efficiency_ratio": clamped_efficiency_ratio,
			"environment_aura_input": 0.0,
			"cultivation_resource_aura_input": 0.0,
			"resource_inputs_supported": false,
		},
	}


func apply_method_study_tick(
		action_profile: Dictionary,
		command: Dictionary,
		world_time: Dictionary
) -> Dictionary:
	if not initialized:
		return {
			"ok": false,
			"code": "character_not_initialized",
			"error": "Cannot settle method study without an initialized character.",
		}

	if action_profile.is_empty():
		return {
			"ok": false,
			"code": "missing_action_profile",
			"error": "Action profile is not configured.",
		}

	var target_method_id = str(command.get("target_method_id", action_profile.get("default_target_method_id", "")))
	if target_method_id.is_empty():
		target_method_id = _first_method_state_id()
	if target_method_id.is_empty() or not method_states.has(target_method_id):
		return {
			"ok": false,
			"code": "method_state_not_found",
			"error": "Method study target is not learned: %s" % target_method_id,
			"target_method_id": target_method_id,
		}

	var method_state = method_states.get(target_method_id, {}).duplicate(true)
	var policy = str(action_profile.get("compatible_hour_policy", "none"))
	var compatible_hours = 1.0 if policy == "full" else 0.0
	var comprehension_record = aptitude_profile.get("aptitude_comprehension", {})
	var comprehension_value = 10
	if typeof(comprehension_record) == TYPE_DICTIONARY:
		comprehension_value = int(comprehension_record.get("effective_value", comprehension_record.get("innate_value", 10)))
	var comprehension_factor = maxf(float(comprehension_value) / 10.0, 0.1)
	var base_exp_per_hour = maxf(float(action_profile.get("method_mastery_exp_per_hour", 0.0)), 0.0)
	var exp_gain = base_exp_per_hour * comprehension_factor * compatible_hours

	var before_level = int(method_state.get("mastery_level", 1))
	var before_exp = float(method_state.get("mastery_exp", 0.0))
	var max_level = maxi(int(method_state.get("max_mastery_level", action_profile.get("max_mastery_level", 5))), 1)
	var exp_to_next = maxf(float(method_state.get("mastery_exp_to_next", action_profile.get("mastery_exp_per_level", 10.0))), 0.01)
	var after_level = before_level
	var after_exp = before_exp + exp_gain
	while after_level < max_level and after_exp >= exp_to_next:
		after_exp -= exp_to_next
		after_level += 1

	if after_level >= max_level:
		after_level = max_level
		after_exp = 0.0

	var mastery_norm = clampf((float(after_level) + (after_exp / exp_to_next if after_level < max_level else 0.0)) / float(max_level), 0.0, 1.0)
	method_state["mastery_level"] = after_level
	method_state["mastery_exp"] = after_exp
	method_state["mastery_exp_to_next"] = exp_to_next
	method_state["max_mastery_level"] = max_level
	method_state["mastery_norm"] = mastery_norm
	method_state["last_practiced_world_day"] = int(world_time.get("world_day", 1))
	method_state["last_practiced_world_hour"] = int(world_time.get("world_hour", 0))
	method_states[target_method_id] = method_state.duplicate(true)

	var display_name = str(method_state.get("display_name", target_method_id))
	var visible_summary = "%s settled: +%.2f mastery exp on %s, level %d." % [
		str(action_profile.get("display_name", "Method Study")),
		exp_gain,
		display_name,
		after_level,
	]

	return {
		"ok": true,
		"world_day": int(world_time.get("world_day", 1)),
		"world_hour": int(world_time.get("world_hour", 0)),
		"command_id": command.get("command_id", ""),
		"action_type": str(action_profile.get("action_type", command.get("action_type", ""))),
		"target_method_id": target_method_id,
		"compatible_hours": compatible_hours,
		"method_mastery_exp_gain": exp_gain,
		"method_mastery_delta": {
			"method_id": target_method_id,
			"display_name": display_name,
			"mastery_level_before": before_level,
			"mastery_level_after": after_level,
			"mastery_exp_before": before_exp,
			"mastery_exp_after": after_exp,
			"mastery_norm_after": mastery_norm,
		},
		"cultivation_points_gain": 0.0,
		"resource_effects_consumed": [],
		"active_resource_effect_delta": [],
		"resource_use_log_refs": [],
		"visible_summary": visible_summary,
		"debug_formula_trace": {
			"base_exp_per_hour": base_exp_per_hour,
			"comprehension_value": comprehension_value,
			"comprehension_factor": comprehension_factor,
			"resource_inputs_supported": false,
		},
	}


func apply_minor_stage_gate(current_segment: Dictionary, next_segment: Dictionary, world_time: Dictionary) -> Dictionary:
	var current_cp = float(cultivation_state.get("cultivation_points", 0.0))
	var upper_bound = float(current_segment.get("cp_upper_bound", current_cp))
	if current_cp < upper_bound:
		return {
			"advanced": false,
			"bottleneck_reached": false,
		}

	var next_segment_id = str(current_segment.get("next_segment_id", ""))
	if next_segment_id.is_empty() or next_segment.is_empty():
		cultivation_state["normalized_segment_progress"] = 1.0
		cultivation_state["bottleneck_state"] = "reached"
		return {
			"advanced": false,
			"bottleneck_reached": true,
			"segment_id": current_segment.get("segment_id", ""),
			"world_time": world_time.duplicate(true),
		}

	var before_stage = str(cultivation_state.get("minor_stage", ""))
	cultivation_state["realm"] = str(current_segment.get("realm_to", cultivation_state.get("realm", "")))
	cultivation_state["minor_stage"] = str(current_segment.get("minor_stage_to", cultivation_state.get("minor_stage", "")))
	cultivation_state["current_realm_segment_id"] = next_segment_id
	cultivation_state["normalized_segment_progress"] = _progress_for_segment(next_segment, current_cp)
	cultivation_state["bottleneck_state"] = "none"

	return {
		"advanced": true,
		"bottleneck_reached": false,
		"from_minor_stage": before_stage,
		"to_minor_stage": cultivation_state.get("minor_stage", ""),
		"next_segment_id": next_segment_id,
		"world_time": world_time.duplicate(true),
	}


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
		"method_states": method_states.duplicate(true),
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

	var method_data = data.get("method_states", {})
	if typeof(method_data) == TYPE_DICTIONARY:
		state.method_states = method_data.duplicate(true)

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


func _method_states_from_config(method_state_configs: Array, world_time: Dictionary) -> Dictionary:
	var output = {}
	for item in method_state_configs:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var record = _method_state_record(item, world_time)
		var method_id = str(record.get("method_id", ""))
		if not method_id.is_empty():
			output[method_id] = record
	return output


func _method_state_record(config: Dictionary, world_time: Dictionary) -> Dictionary:
	var max_level = maxi(int(config.get("max_mastery_level", 5)), 1)
	var mastery_level = clampi(int(config.get("mastery_level", 1)), 1, max_level)
	var exp_to_next = maxf(float(config.get("mastery_exp_to_next", 10.0)), 0.01)
	var mastery_exp = maxf(float(config.get("mastery_exp", 0.0)), 0.0)
	var mastery_norm = clampf(float(config.get("mastery_norm", float(mastery_level) / float(max_level))), 0.0, 1.0)
	return {
		"method_state_id": str(config.get("method_state_id", "method_state_%s" % config.get("method_id", ""))),
		"character_id": character_id,
		"method_id": str(config.get("method_id", "")),
		"method_type": str(config.get("method_type", "technique_method")),
		"display_name": str(config.get("display_name", config.get("method_id", ""))),
		"learned_from_carrier_id": str(config.get("learned_from_carrier_id", "")),
		"mastery_level": mastery_level,
		"mastery_exp": mastery_exp,
		"mastery_exp_to_next": exp_to_next,
		"max_mastery_level": max_level,
		"mastery_norm": mastery_norm,
		"unlocked_action_tags": _string_array(config.get("unlocked_action_tags", [])),
		"unlocked_combat_commands": _string_array(config.get("unlocked_combat_commands", [])),
		"unlocked_event_option_tags": _string_array(config.get("unlocked_event_option_tags", [])),
		"unlocked_effect_refs": _string_array(config.get("unlocked_effect_refs", [])),
		"last_practiced_world_day": int(world_time.get("world_day", 1)),
		"last_practiced_world_hour": int(world_time.get("world_hour", 0)),
	}


func _first_method_state_id() -> String:
	for key in method_states.keys():
		return str(key)
	return ""


func _apply_bar_recovery(action_profile: Dictionary) -> Dictionary:
	var rates = action_profile.get("bar_recovery_per_hour", {})
	if typeof(rates) != TYPE_DICTIONARY:
		return {}

	var output = {}
	for bar_name in rates.keys():
		var recovery = float(rates.get(bar_name, 0.0))
		if recovery <= 0.0:
			continue
		var delta = _recover_bar(str(bar_name), recovery)
		if not delta.is_empty():
			output[str(bar_name)] = delta
	return output


func _recover_bar(bar_name: String, amount: float) -> Dictionary:
	var bar = derived_bars.get(bar_name, {})
	if typeof(bar) != TYPE_DICTIONARY:
		return {}
	var before = float(bar.get("current", 0.0))
	var max_value = maxf(float(bar.get("max", before)), 0.0)
	var after = clampf(before + amount, 0.0, max_value)
	bar["current"] = after
	derived_bars[bar_name] = bar.duplicate(true)
	return {
		"before": before,
		"after": after,
		"delta": after - before,
		"max": max_value,
	}


static func _dict_value(data: Dictionary, key: String) -> Dictionary:
	var value = data.get(key, {})
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	return value


static func _array_value(value) -> Array:
	if typeof(value) != TYPE_ARRAY:
		return []
	return value.duplicate(true)


static func _string_array(value) -> Array[String]:
	var output: Array[String] = []
	if typeof(value) != TYPE_ARRAY:
		return output
	for item in value:
		output.append(str(item))
	return output


static func _segment_cp_width(segment: Dictionary) -> float:
	return maxf(
		float(segment.get("cp_upper_bound", 0.0)) - float(segment.get("cp_lower_bound", 0.0)),
		0.0
	)


static func _progress_for_segment(segment: Dictionary, cultivation_points: float) -> float:
	var lower_bound = float(segment.get("cp_lower_bound", 0.0))
	var width = _segment_cp_width(segment)
	if width <= 0.0:
		return 0.0
	return clampf((cultivation_points - lower_bound) / width, 0.0, 1.0)
