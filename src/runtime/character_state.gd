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
var inventory: Dictionary = {}
var active_resource_effects: Dictionary = {}
var resource_use_logs: Array[Dictionary] = []
var next_resource_effect_sequence = 1
var next_resource_log_sequence = 1
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
	var inventory_config = _dict_value(config, "inventory")

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
	inventory = _inventory_from_config(inventory_config)
	active_resource_effects = {}
	resource_use_logs = []
	next_resource_effect_sequence = 1
	next_resource_log_sequence = 1

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


func get_inventory_item(resource_item_template_id: String) -> Dictionary:
	var items = inventory.get("items", {})
	if typeof(items) != TYPE_DICTIONARY:
		return {}
	var item = items.get(resource_item_template_id, {})
	if typeof(item) != TYPE_DICTIONARY:
		return {}
	return item.duplicate(true)


func get_inventory_quantity(resource_item_template_id: String) -> int:
	var item = get_inventory_item(resource_item_template_id)
	if item.is_empty():
		return 0
	return int(item.get("quantity", 0))


func has_active_resource_stacking_group(stacking_group: String) -> bool:
	if stacking_group.is_empty():
		return false
	for effect_id in active_resource_effects.keys():
		var effect = active_resource_effects.get(effect_id, {})
		if typeof(effect) != TYPE_DICTIONARY:
			continue
		if str(effect.get("stacking_group", "")) != stacking_group:
			continue
		var state = str(effect.get("state", "active"))
		if state == "active" or state == "suspended" or state == "decaying":
			return true
	return false


func active_resource_effect_summary() -> String:
	var summaries: Array[String] = []
	for effect_id in active_resource_effects.keys():
		var effect = active_resource_effects.get(effect_id, {})
		if typeof(effect) != TYPE_DICTIONARY:
			continue
		summaries.append("%s %.1fh %s" % [
			effect.get("display_name", effect_id),
			float(effect.get("remaining_effective_hours", 0.0)),
			effect.get("state", "active"),
		])
	if summaries.is_empty():
		return "No active resource effects."
	return ", ".join(summaries)


func validate_resource_input_binding(
		raw_input: Dictionary,
		inventory_item: Dictionary,
		effect_template: Dictionary,
		action_profile: Dictionary,
		command: Dictionary
) -> Dictionary:
	var resource_item_template_id = str(raw_input.get("resource_item_template_id", raw_input.get("resource_id", "")))
	if resource_item_template_id.is_empty():
		return _resource_validation_error("missing_resource_item_template_id", "Resource input is missing resource_item_template_id.")

	var quantity = int(raw_input.get("quantity", 1))
	if quantity != 1:
		return _resource_validation_error(
			"resource_input_quantity_unsupported",
			"MVP P3 supports one unit per resource input binding.",
			{"quantity": quantity}
		)

	if inventory_item.is_empty() or int(inventory_item.get("quantity", 0)) < quantity:
		return _resource_validation_error(
			"resource_not_owned",
			"Resource input is not available in the character inventory.",
			{"resource_item_template_id": resource_item_template_id}
		)

	var effect_template_id = str(raw_input.get("resource_effect_template_id", inventory_item.get("resource_effect_template_id", "")))
	if effect_template_id.is_empty():
		return _resource_validation_error(
			"missing_resource_effect_template",
			"Resource input has no effect template.",
			{"resource_item_template_id": resource_item_template_id}
		)

	if str(effect_template.get("resource_effect_template_id", "")) != effect_template_id:
		return _resource_validation_error(
			"resource_effect_template_mismatch",
			"Resource input effect template does not match the item.",
			{
				"resource_item_template_id": resource_item_template_id,
				"resource_effect_template_id": effect_template_id,
			}
		)

	if str(effect_template.get("use_mode", "")) != "action_resource_input":
		return _resource_validation_error(
			"resource_use_mode_not_supported",
			"Resource input must use action_resource_input mode.",
			{"use_mode": effect_template.get("use_mode", "")}
		)

	var effect_type = str(effect_template.get("effect_type", ""))
	var compatible_effect_types = _string_array(action_profile.get("compatible_resource_effect_types", []))
	if not compatible_effect_types.has(effect_type):
		return _resource_validation_error(
			"resource_effect_type_not_compatible",
			"Resource effect type is not compatible with this action.",
			{
				"effect_type": effect_type,
				"action_type": command.get("action_type", ""),
			}
		)

	if not _effect_template_supports_action(effect_template, action_profile, str(command.get("action_type", ""))):
		return _resource_validation_error(
			"resource_action_tag_not_compatible",
			"Resource effect is not compatible with this action tag.",
			{
				"resource_effect_template_id": effect_template_id,
				"action_type": command.get("action_type", ""),
			}
		)

	var stacking_group = str(effect_template.get("stacking_group", effect_template_id))
	if has_active_resource_stacking_group(stacking_group):
		return _resource_validation_error(
			"resource_stacking_limit",
			"An active resource effect in the same stacking group already exists.",
			{"stacking_group": stacking_group}
		)

	return {
		"ok": true,
		"code": "resource_input_valid",
		"resource_item_template_id": resource_item_template_id,
		"resource_effect_template_id": effect_template_id,
		"effect_type": effect_type,
		"stacking_group": stacking_group,
	}


func activate_resource_inputs(command: Dictionary, world_time: Dictionary) -> Dictionary:
	var resource_inputs = command.get("resource_inputs", [])
	if typeof(resource_inputs) != TYPE_ARRAY or resource_inputs.is_empty():
		return {
			"ok": true,
			"resource_inputs": [],
			"activated_effects": [],
			"resource_use_log_refs": [],
		}

	var updated_inputs: Array[Dictionary] = []
	var activated_effects: Array[Dictionary] = []
	var log_refs: Array[String] = []
	for input in resource_inputs:
		if typeof(input) != TYPE_DICTIONARY:
			return _resource_validation_error("invalid_resource_input", "Resource input must be a dictionary.")
		var binding = input.duplicate(true)
		if int(binding.get("consumed_at_world_day", 0)) > 0:
			updated_inputs.append(binding)
			continue

		var resource_item_template_id = str(binding.get("resource_item_template_id", ""))
		var quantity = int(binding.get("quantity", 1))
		var item = get_inventory_item(resource_item_template_id)
		if item.is_empty() or int(item.get("quantity", 0)) < quantity:
			return _resource_validation_error(
				"resource_not_owned_at_start",
				"Resource input is no longer available when the action starts.",
				{"resource_item_template_id": resource_item_template_id}
			)

		item["quantity"] = int(item.get("quantity", 0)) - quantity
		var items = inventory.get("items", {})
		if typeof(items) != TYPE_DICTIONARY:
			items = {}
		items[resource_item_template_id] = item.duplicate(true)
		inventory["items"] = items

		var log_entry = _append_resource_log(
			"resource_input_consumed",
			world_time,
			{
				"command_id": command.get("command_id", ""),
				"binding_id": binding.get("binding_id", ""),
				"resource_item_template_id": resource_item_template_id,
				"resource_effect_template_id": binding.get("resource_effect_template_id", ""),
				"quantity": quantity,
				"remaining_quantity": item.get("quantity", 0),
			}
		)
		log_refs.append(str(log_entry.get("log_id", "")))

		binding["consumed_at_world_day"] = int(world_time.get("world_day", 1))
		binding["consumed_at_world_hour"] = int(world_time.get("world_hour", 0))
		binding["resource_use_log_refs"] = [str(log_entry.get("log_id", ""))]
		var active_effect = _active_resource_effect_from_binding(binding, command, world_time, str(log_entry.get("log_id", "")))
		binding["active_effect_ref"] = active_effect.get("effect_id", "")
		active_resource_effects[str(active_effect.get("effect_id", ""))] = active_effect.duplicate(true)
		activated_effects.append(active_effect.duplicate(true))
		updated_inputs.append(binding)

	return {
		"ok": true,
		"resource_inputs": updated_inputs,
		"activated_effects": activated_effects,
		"resource_use_log_refs": log_refs,
	}


func settle_resource_effects_for_action(
		action_type: String,
		action_profile: Dictionary,
		world_time: Dictionary,
		compatible_hours: float
) -> Dictionary:
	var applied_effects: Array[Dictionary] = []
	var idle_effects: Array[Dictionary] = []
	var exhausted_effects: Array[Dictionary] = []
	var total_cultivation_aura = 0.0
	var total_cp_gain = 0.0
	var pressure_delta = 0.0

	for effect_id in active_resource_effects.keys():
		var effect = active_resource_effects.get(effect_id, {})
		if typeof(effect) != TYPE_DICTIONARY:
			continue

		var is_compatible = _effect_supports_action(effect, action_profile, action_type)
		if is_compatible and compatible_hours > 0.0:
			var applied_hours = minf(compatible_hours, float(effect.get("remaining_effective_hours", 0.0)))
			if applied_hours <= 0.0:
				continue
			var actual_unit_rate = float(effect.get("actual_unit_effect_rate", effect.get("unit_effect_rate", 0.0)))
			var amount = actual_unit_rate * applied_hours
			var cp_ratio = float(effect.get("resource_to_cp_ratio", 1.0))
			var cp_gain = amount * cp_ratio
			var before_hours = float(effect.get("remaining_effective_hours", 0.0))
			var after_hours = maxf(before_hours - applied_hours, 0.0)
			effect["remaining_effective_hours"] = after_hours
			effect["remaining_effect_amount"] = actual_unit_rate * after_hours
			effect["last_applied_world_day"] = int(world_time.get("world_day", 1))
			effect["last_applied_world_hour"] = int(world_time.get("world_hour", 0))
			effect["state"] = "active" if after_hours > 0.0 else "exhausted"
			total_cultivation_aura += amount
			total_cp_gain += cp_gain
			pressure_delta += float(effect.get("pressure_per_applied_hour", 0.0)) * applied_hours

			var applied = {
				"effect_id": effect.get("effect_id", ""),
				"display_name": effect.get("display_name", ""),
				"effect_type": effect.get("effect_type", ""),
				"applied_effective_hours": applied_hours,
				"applied_amount": amount,
				"cultivation_points_gain": cp_gain,
				"remaining_effective_hours_before": before_hours,
				"remaining_effective_hours_after": after_hours,
			}
			applied_effects.append(applied)
			if after_hours <= 0.0:
				exhausted_effects.append(effect.duplicate(true))
			else:
				active_resource_effects[effect_id] = effect.duplicate(true)
		else:
			effect["idle_world_hours"] = int(effect.get("idle_world_hours", 0)) + 1
			effect["state"] = "suspended"
			active_resource_effects[effect_id] = effect.duplicate(true)
			idle_effects.append({
				"effect_id": effect.get("effect_id", ""),
				"display_name": effect.get("display_name", ""),
				"idle_world_hours": effect.get("idle_world_hours", 0),
				"remaining_effective_hours": effect.get("remaining_effective_hours", 0.0),
				"residual_policy": effect.get("residual_policy", ""),
			})

	for effect in exhausted_effects:
		active_resource_effects.erase(str(effect.get("effect_id", "")))
		_append_resource_log(
			"resource_effect_exhausted",
			world_time,
			{
				"effect_id": effect.get("effect_id", ""),
				"resource_effect_template_id": effect.get("resource_effect_template_id", ""),
				"source_command_id": effect.get("source_command_id", ""),
			}
		)

	return {
		"cultivation_resource_aura_input": total_cultivation_aura,
		"cultivation_points_gain": total_cp_gain,
		"meridian_pressure_delta": pressure_delta,
		"applied_effects": applied_effects,
		"idle_effects": idle_effects,
		"exhausted_effects": exhausted_effects,
		"active_effects_after": active_resource_effects.duplicate(true),
	}


func settle_residual_effects_by_consolidation(
		action_profile: Dictionary,
		command: Dictionary,
		world_time: Dictionary,
		compatible_hours: float
) -> Dictionary:
	if compatible_hours <= 0.0 or not bool(command.get("settle_residual_effects", false)):
		return {
			"residual_effect_clearance": [],
			"settled_amount": 0.0,
			"cleared_effects": [],
		}

	var clearance: Array[Dictionary] = []
	var cleared_effects: Array[Dictionary] = []
	var settled_amount = 0.0
	for effect_id in active_resource_effects.keys():
		var effect = active_resource_effects.get(effect_id, {})
		if typeof(effect) != TYPE_DICTIONARY:
			continue
		if not bool(effect.get("can_be_settled_by_consolidation", false)):
			continue

		var settled_hours = minf(compatible_hours, float(effect.get("remaining_effective_hours", 0.0)))
		if settled_hours <= 0.0:
			continue

		var actual_unit_rate = float(effect.get("actual_unit_effect_rate", effect.get("unit_effect_rate", 0.0)))
		var amount = actual_unit_rate * settled_hours
		var before_hours = float(effect.get("remaining_effective_hours", 0.0))
		var after_hours = maxf(before_hours - settled_hours, 0.0)
		settled_amount += amount
		effect["remaining_effective_hours"] = after_hours
		effect["remaining_effect_amount"] = actual_unit_rate * after_hours
		effect["last_applied_world_day"] = int(world_time.get("world_day", 1))
		effect["last_applied_world_hour"] = int(world_time.get("world_hour", 0))
		effect["state"] = "active" if after_hours > 0.0 else "resolved"

		var cleared = {
			"effect_id": effect.get("effect_id", ""),
			"display_name": effect.get("display_name", ""),
			"settled_effective_hours": settled_hours,
			"settled_amount": amount,
			"remaining_effective_hours_before": before_hours,
			"remaining_effective_hours_after": after_hours,
			"settlement_policy": effect.get("settlement_policy", "suppress_side_effect"),
		}
		clearance.append(cleared)
		if after_hours <= 0.0:
			cleared_effects.append(effect.duplicate(true))
		else:
			active_resource_effects[effect_id] = effect.duplicate(true)

	for effect in cleared_effects:
		active_resource_effects.erase(str(effect.get("effect_id", "")))
		_append_resource_log(
			"resource_effect_cleared_by_consolidation",
			world_time,
			{
				"effect_id": effect.get("effect_id", ""),
				"resource_effect_template_id": effect.get("resource_effect_template_id", ""),
				"command_id": command.get("command_id", ""),
			}
		)

	return {
		"residual_effect_clearance": clearance,
		"settled_amount": settled_amount,
		"cleared_effects": cleared_effects,
		"active_effects_after": active_resource_effects.duplicate(true),
		"pressure_prevention": settled_amount * float(action_profile.get("residual_settlement_pressure_prevention_ratio", 0.0)),
	}


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
	var resource_effect_summary = {}
	var residual_settlement_summary = {}

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

	if action_type == "consolidation":
		residual_settlement_summary = settle_residual_effects_by_consolidation(action_profile, command, world_time, 1.0)
	else:
		resource_effect_summary = settle_resource_effects_for_action(
			action_type,
			action_profile,
			world_time,
			compatible_hours
		)
		cp_gain += float(resource_effect_summary.get("cultivation_points_gain", 0.0))
		pressure_delta += float(resource_effect_summary.get("meridian_pressure_delta", 0.0))

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
		"resource_effects_consumed": _resource_inputs_consumed_from_command(command),
		"active_resource_effect_delta": resource_effect_summary,
		"residual_settlement_delta": residual_settlement_summary,
		"resource_use_log_refs": _log_refs_from_command(command),
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
			"cultivation_resource_aura_input": float(resource_effect_summary.get("cultivation_resource_aura_input", 0.0)),
			"resource_inputs_supported": bool(action_profile.get("resource_inputs_supported", false)),
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
		"inventory": inventory.duplicate(true),
		"active_resource_effects": active_resource_effects.duplicate(true),
		"resource_use_logs": resource_use_logs.duplicate(true),
		"next_resource_effect_sequence": next_resource_effect_sequence,
		"next_resource_log_sequence": next_resource_log_sequence,
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

	var inventory_data = data.get("inventory", {})
	if typeof(inventory_data) == TYPE_DICTIONARY:
		state.inventory = inventory_data.duplicate(true)

	var active_resource_data = data.get("active_resource_effects", {})
	if typeof(active_resource_data) == TYPE_DICTIONARY:
		state.active_resource_effects = active_resource_data.duplicate(true)

	var resource_logs_data = data.get("resource_use_logs", [])
	if typeof(resource_logs_data) == TYPE_ARRAY:
		for item in resource_logs_data:
			if typeof(item) == TYPE_DICTIONARY:
				state.resource_use_logs.append(item.duplicate(true))

	state.next_resource_effect_sequence = int(data.get("next_resource_effect_sequence", 1))
	if state.next_resource_effect_sequence < 1:
		state.next_resource_effect_sequence = 1

	state.next_resource_log_sequence = int(data.get("next_resource_log_sequence", 1))
	if state.next_resource_log_sequence < 1:
		state.next_resource_log_sequence = 1

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


func _inventory_from_config(config: Dictionary) -> Dictionary:
	var container_id = str(config.get("container_id", "character_bag"))
	var items = {}
	var item_configs = _array_value(config.get("items", []))
	for item_config in item_configs:
		if typeof(item_config) != TYPE_DICTIONARY:
			continue
		var item = _inventory_item_record(item_config, container_id)
		var item_template_id = str(item.get("resource_item_template_id", ""))
		if not item_template_id.is_empty():
			items[item_template_id] = item
	return {
		"container_id": container_id,
		"items": items,
	}


func _inventory_item_record(config: Dictionary, fallback_container_id: String) -> Dictionary:
	var quantity = int(config.get("quantity", 0))
	if quantity < 0:
		quantity = 0
	return {
		"resource_item_template_id": str(config.get("resource_item_template_id", config.get("item_template_id", ""))),
		"display_name": str(config.get("display_name", config.get("resource_item_template_id", ""))),
		"quantity": quantity,
		"source_container_id": str(config.get("source_container_id", fallback_container_id)),
		"resource_effect_template_id": str(config.get("resource_effect_template_id", "")),
		"tags": _string_array(config.get("tags", [])),
	}


func _active_resource_effect_from_binding(
		binding: Dictionary,
		command: Dictionary,
		world_time: Dictionary,
		log_ref: String
) -> Dictionary:
	var actual_unit_rate = float(binding.get("actual_unit_effect_rate", binding.get("unit_effect_rate", 0.0)))
	var max_effective_hours = maxf(float(binding.get("max_effective_hours", 0.0)), 0.0)
	return {
		"effect_id": _next_resource_effect_id(),
		"character_id": character_id,
		"source_binding_id": str(binding.get("binding_id", "")),
		"source_command_id": str(command.get("command_id", "")),
		"resource_item_template_id": str(binding.get("resource_item_template_id", "")),
		"resource_effect_template_id": str(binding.get("resource_effect_template_id", "")),
		"display_name": str(binding.get("display_name", binding.get("resource_item_template_id", ""))),
		"effect_type": str(binding.get("effect_type", "")),
		"unit_effect_rate": float(binding.get("unit_effect_rate", 0.0)),
		"actual_unit_effect_rate": actual_unit_rate,
		"resource_to_cp_ratio": float(binding.get("resource_to_cp_ratio", 1.0)),
		"pressure_per_applied_hour": float(binding.get("pressure_per_applied_hour", 0.0)),
		"remaining_effective_hours": max_effective_hours,
		"remaining_effect_amount": actual_unit_rate * max_effective_hours,
		"compatible_action_tags": _string_array(binding.get("compatible_action_tags", [])),
		"compatible_context_tags": _string_array(binding.get("compatible_context_tags", [])),
		"effect_tick_mode": str(binding.get("effect_tick_mode", "compatible_action_hours")),
		"residual_policy": str(binding.get("residual_policy", "stable_suspend")),
		"residual_stability_hours_remaining": float(binding.get("residual_stability_hours", 0.0)),
		"idle_world_hours": 0,
		"can_be_settled_by_consolidation": bool(binding.get("can_be_settled_by_consolidation", false)),
		"settlement_policy": str(binding.get("settlement_policy", "none")),
		"stacking_group": str(binding.get("stacking_group", "")),
		"created_world_day": int(world_time.get("world_day", 1)),
		"created_world_hour": int(world_time.get("world_hour", 0)),
		"last_applied_world_day": 0,
		"last_applied_world_hour": 0,
		"state": "active",
		"log_refs": [log_ref],
	}


func _append_resource_log(event_type: String, world_time: Dictionary, payload: Dictionary) -> Dictionary:
	var log_entry = {
		"log_id": _next_resource_log_id(),
		"event_type": event_type,
		"world_day": int(world_time.get("world_day", 1)),
		"world_hour": int(world_time.get("world_hour", 0)),
		"payload": payload.duplicate(true),
	}
	resource_use_logs.append(log_entry.duplicate(true))
	return log_entry


func _next_resource_effect_id() -> String:
	var effect_id = "resource_effect_%04d" % next_resource_effect_sequence
	next_resource_effect_sequence += 1
	return effect_id


func _next_resource_log_id() -> String:
	var log_id = "resource_log_%04d" % next_resource_log_sequence
	next_resource_log_sequence += 1
	return log_id


func _resource_validation_error(code: String, error: String, extra: Dictionary = {}) -> Dictionary:
	var result = {
		"ok": false,
		"code": code,
		"error": error,
	}
	for key in extra.keys():
		result[key] = extra.get(key)
	return result


func _effect_template_supports_action(effect_template: Dictionary, action_profile: Dictionary, action_type: String) -> bool:
	var effect_tags = _string_array(effect_template.get("compatible_action_tags", []))
	if effect_tags.has(action_type):
		return true
	var action_tags = _string_array(action_profile.get("action_tags", []))
	for tag in action_tags:
		if effect_tags.has(tag):
			return true
	return false


func _effect_supports_action(effect: Dictionary, action_profile: Dictionary, action_type: String) -> bool:
	if str(effect.get("effect_tick_mode", "compatible_action_hours")) != "compatible_action_hours":
		return false
	var effect_tags = _string_array(effect.get("compatible_action_tags", []))
	if effect_tags.has(action_type):
		return true
	var action_tags = _string_array(action_profile.get("action_tags", []))
	for tag in action_tags:
		if effect_tags.has(tag):
			return true
	return false


func _resource_inputs_consumed_from_command(command: Dictionary) -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	var resource_inputs = command.get("resource_inputs", [])
	if typeof(resource_inputs) != TYPE_ARRAY:
		return output
	for input in resource_inputs:
		if typeof(input) == TYPE_DICTIONARY and int(input.get("consumed_at_world_day", 0)) > 0:
			output.append(input.duplicate(true))
	return output


func _log_refs_from_command(command: Dictionary) -> Array[String]:
	var refs: Array[String] = []
	var resource_inputs = command.get("resource_inputs", [])
	if typeof(resource_inputs) != TYPE_ARRAY:
		return refs
	for input in resource_inputs:
		if typeof(input) != TYPE_DICTIONARY:
			continue
		var input_refs = _string_array(input.get("resource_use_log_refs", []))
		for ref in input_refs:
			refs.append(ref)
	return refs


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
