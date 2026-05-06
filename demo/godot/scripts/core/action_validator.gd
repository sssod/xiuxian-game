extends RefCounted

const DemoConstants = preload("res://scripts/core/demo_constants.gd")
const ContentLoader = preload("res://scripts/core/content_loader.gd")

static func validate_queue(runtime: Dictionary, content: Dictionary, player_id: String, action_queue: Array) -> Dictionary:
	var errors := []
	var planned_hours := 0
	var room_state: Dictionary = runtime.get("room_state", {})
	var turn_config: Dictionary = room_state.get("turn_config", DemoConstants.default_turn_config())
	var budget_hours := DemoConstants.turn_total_hours(turn_config)
	var simulated_locations := {}

	for index in action_queue.size():
		var action = action_queue[index]
		if typeof(action) != TYPE_DICTIONARY:
			errors.append("Action %d is not a dictionary." % index)
			continue

		var action_id := str(action.get("action_id", ""))
		var template := ContentLoader.action_template(content, action_id)
		if template.is_empty():
			errors.append("Unknown action_id: %s" % action_id)

		var duration := int(action.get("planned_duration_hours", 0))
		if duration <= 0:
			errors.append("%s planned_duration_hours must be positive." % action_id)
		planned_hours += max(duration, 0)

		if not action.has("actor_id") or str(action["actor_id"]) == "":
			errors.append("%s missing actor_id." % action_id)

		var actor_id := str(action.get("actor_id", ""))
		if actor_id != "" and not simulated_locations.has(actor_id):
			simulated_locations[actor_id] = _actor_current_location(runtime, actor_id)

		var resource_bindings = _resource_bindings(action)
		if typeof(resource_bindings) != TYPE_ARRAY:
			errors.append("%s resource_bindings must be an array." % action_id)
		else:
			var used_channels := []
			for binding in resource_bindings:
				if typeof(binding) != TYPE_DICTIONARY:
					errors.append("%s contains invalid ActionResourceInputBinding." % action_id)
					continue
				var effect_channel := str(binding.get("effect_channel", ""))
				if effect_channel != "" and used_channels.has(effect_channel):
					errors.append("%s uses more than one resource input for effect_channel=%s." % [action_id, effect_channel])
				used_channels.append(effect_channel)
				if not _resource_binding_is_available(runtime, content, actor_id, action_id, binding):
					errors.append("%s resource input is unavailable or invalid: %s." % [action_id, str(binding.get("resource_ref", ""))])

		var target = action.get("target", {})
		if typeof(target) != TYPE_DICTIONARY:
			errors.append("%s target must be a dictionary." % action_id)
		elif target.get("target_type", "") == "node":
			var node_id := str(target.get("target_id", ""))
			if ContentLoader.node_template(content, node_id).is_empty():
				errors.append("%s target node does not exist: %s" % [action_id, node_id])
			elif _node_visibility(runtime, content, node_id) == "hidden":
				errors.append("%s target node is still hidden: %s" % [action_id, node_id])

		if action_id == "move_to_node":
			var target_node := ""
			if typeof(target) == TYPE_DICTIONARY:
				target_node = str(target.get("target_id", ""))
			var from_node := str(simulated_locations.get(actor_id, ""))
			var route := ContentLoader.route_path_between(content, from_node, target_node, _visible_node_ids(runtime, content))
			if route.is_empty():
				errors.append("No visible route path from %s to %s for move_to_node." % [from_node, target_node])
			else:
				var required_hours := int(route.get("base_travel_hours", 0))
				if duration < required_hours:
					errors.append("move_to_node planned_duration_hours must cover route path time: %dh required." % required_hours)
				simulated_locations[actor_id] = target_node
		elif action_id in ["ask_for_rumor", "explore_node", "gather_resource", "active_cultivation", "study_method", "join_sect_event", "prepare_breakthrough", "attempt_breakthrough"]:
			var action_node := ""
			if typeof(target) == TYPE_DICTIONARY:
				action_node = str(target.get("target_id", ""))
			var expected_node := str(simulated_locations.get(actor_id, ""))
			if action_node != "" and expected_node != "" and action_node != expected_node:
				errors.append("%s target must match planned location %s, got %s." % [action_id, expected_node, action_node])
			if action_id == "join_sect_event" and action_node != "node_yunlu_gate":
				errors.append("join_sect_event must target node_yunlu_gate.")
			if action_id == "study_method" and not _has_method_carrier(runtime, actor_id, "basic_dao_method_carrier"):
				errors.append("study_method requires a complete MethodCarrierItem in character inventory.")
			if action_id == "active_cultivation" and not _has_main_dao_method(runtime, actor_id):
				errors.append("active_cultivation requires an existing MethodState set as main_dao_method_ref.")
			if action_id == "gather_resource" and not _node_has_available_resource_slot(runtime, action_node):
				errors.append("gather_resource requires an available ResourceSlotState at %s." % action_node)
			if action_id == "prepare_breakthrough" and not _has_main_dao_method(runtime, actor_id):
				errors.append("prepare_breakthrough requires an existing MethodState set as main_dao_method_ref.")
			if action_id == "prepare_breakthrough" and not _is_demo_bottleneck_reached(runtime, actor_id):
				errors.append("prepare_breakthrough requires demo bottleneck state before key preparation.")
			if action_id == "attempt_breakthrough":
				var fixed_duration := int(template.get("fixed_duration_hours", template.get("default_duration_hours", 48)))
				if duration != fixed_duration:
					errors.append("attempt_breakthrough must use fixed_duration_hours=%dh." % fixed_duration)
				var valid_locations: Array = template.get("valid_location_ids", [])
				if not valid_locations.has(action_node):
					errors.append("attempt_breakthrough location is invalid for Phase E demo: %s." % action_node)
				for missing_ref in _breakthrough_gap_refs(runtime, actor_id):
					errors.append("attempt_breakthrough missing prerequisite: %s." % missing_ref)
		elif action_id == "request_sect_resource":
			if typeof(target) != TYPE_DICTIONARY or str(target.get("target_type", "")) != "sect":
				errors.append("request_sect_resource target must be a sect target.")
			else:
				var sect_id := str(target.get("target_id", ""))
				var item_template_id := str(target.get("item_template_id", ""))
				var amount := int(target.get("amount", 1))
				if ContentLoader.sect_template(content, sect_id).is_empty():
					errors.append("request_sect_resource target sect does not exist: %s." % sect_id)
				if not _character_has_sect_permission(runtime, actor_id, sect_id, "request_resources"):
					errors.append("request_sect_resource requires request_resources permission in %s." % sect_id)
				if item_template_id == "" or ContentLoader.item_template(content, item_template_id).is_empty():
					errors.append("request_sect_resource item_template_id is invalid: %s." % item_template_id)
				var allowed_items: Array = template.get("allowed_item_template_ids", [])
				if not allowed_items.is_empty() and not allowed_items.has(item_template_id):
					errors.append("request_sect_resource item is not allowed in Phase D demo: %s." % item_template_id)
				if amount <= 0:
					errors.append("request_sect_resource amount must be positive.")
				if not _container_has_stack(runtime, _sect_storage_container_id(runtime, content, sect_id), item_template_id, amount):
					errors.append("request_sect_resource sect storage lacks %s x%d." % [item_template_id, amount])

	if planned_hours > budget_hours:
		errors.append("Action budget exceeded: %dh planned / %dh available." % [planned_hours, budget_hours])

	return {
		"ok": errors.is_empty(),
		"errors": errors,
		"player_id": player_id,
		"planned_hours": planned_hours,
		"budget_hours": budget_hours
	}

static func _actor_current_location(runtime: Dictionary, actor_id: String) -> String:
	return str(runtime.get("incarnations", {}).get(actor_id, {}).get("current_location", ""))

static func _node_visibility(runtime: Dictionary, content: Dictionary, node_id: String) -> String:
	if runtime.get("node_states", {}).has(node_id):
		return str(runtime["node_states"][node_id].get("visibility_state", "hidden"))
	return str(ContentLoader.node_template(content, node_id).get("visibility_state", "hidden"))

static func _visible_node_ids(runtime: Dictionary, content: Dictionary) -> Array:
	var node_ids := []
	for node_id in content.get("tables", {}).get("nodes", {}).keys():
		if _node_visibility(runtime, content, str(node_id)) != "hidden":
			node_ids.append(str(node_id))
	return node_ids

static func _resource_bindings(action: Dictionary) -> Array:
	if action.has("resource_bindings"):
		return action.get("resource_bindings", [])
	return action.get("resource_inputs", [])

static func _resource_binding_is_available(runtime: Dictionary, content: Dictionary, actor_id: String, action_id: String, binding: Dictionary) -> bool:
	var resource_ref := str(binding.get("resource_ref", ""))
	if resource_ref == "":
		return false
	var template := ContentLoader.item_template(content, resource_ref)
	if template.is_empty():
		return false
	if not template.get("allowed_action_ids", [action_id]).has(action_id):
		return false
	var source_container_ref: Dictionary = binding.get("source_container_ref", {})
	var source_container_id := str(source_container_ref.get("container_id", _inventory_container_id(runtime, actor_id)))
	return _container_has_stack(runtime, source_container_id, resource_ref, 1)

static func _has_method_carrier(runtime: Dictionary, actor_id: String, item_template_id: String) -> bool:
	var container_id := _inventory_container_id(runtime, actor_id)
	for item_id in runtime.get("asset_containers", {}).get(container_id, {}).get("item_instance_refs", []):
		var instance: Dictionary = runtime.get("item_instances", {}).get(str(item_id), {})
		if str(instance.get("item_template_id", "")) == item_template_id:
			return true
	return false

static func _has_main_dao_method(runtime: Dictionary, actor_id: String) -> bool:
	var character: Dictionary = runtime.get("incarnations", {}).get(actor_id, {})
	var main_method_ref := str(character.get("cultivation", {}).get("main_dao_method_ref", ""))
	return main_method_ref != "" and runtime.get("method_states", {}).has(main_method_ref)

static func _breakthrough_gap_refs(runtime: Dictionary, actor_id: String) -> Array:
	var gaps := []
	var character: Dictionary = runtime.get("incarnations", {}).get(actor_id, {})
	var cultivation: Dictionary = character.get("cultivation", {})
	if str(cultivation.get("current_stage_code", "")) != "A-2" or float(cultivation.get("cultivation_progress", 0.0)) < 120.0:
		gaps.append("demo_bottleneck_not_reached")
	if str(cultivation.get("bottleneck_state", "")) != "breakthrough_required":
		gaps.append("breakthrough_required_state_missing")
	var main_method_ref := str(cultivation.get("main_dao_method_ref", ""))
	var method_state: Dictionary = runtime.get("method_states", {}).get(main_method_ref, {})
	if str(method_state.get("current_effective_cap_stage", "")) != "A-3":
		gaps.append("main_method_cap_below_A-3")
	if not _has_item_instance_available(runtime, actor_id, "trial_token_instance"):
		gaps.append("trial_token_instance")
	if not _has_item_instance_available(runtime, actor_id, "breakthrough_catalyst_instance"):
		gaps.append("breakthrough_catalyst_instance")
	return gaps

static func _is_demo_bottleneck_reached(runtime: Dictionary, actor_id: String) -> bool:
	var cultivation: Dictionary = runtime.get("incarnations", {}).get(actor_id, {}).get("cultivation", {})
	return str(cultivation.get("current_stage_code", "")) == "A-2" and float(cultivation.get("cultivation_progress", 0.0)) >= 120.0 and str(cultivation.get("bottleneck_state", "")) == "breakthrough_required"

static func _has_item_instance_available(runtime: Dictionary, actor_id: String, item_template_id: String) -> bool:
	var container_id := _inventory_container_id(runtime, actor_id)
	for item_id in runtime.get("asset_containers", {}).get(container_id, {}).get("item_instance_refs", []):
		var instance: Dictionary = runtime.get("item_instances", {}).get(str(item_id), {})
		if str(instance.get("item_template_id", "")) != item_template_id:
			continue
		var instance_state: Dictionary = instance.get("instance_state", {})
		if bool(instance_state.get("consumed", false)):
			continue
		return true
	return false

static func _inventory_container_id(runtime: Dictionary, actor_id: String) -> String:
	return str(runtime.get("incarnations", {}).get(actor_id, {}).get("inventory_container_ref", {}).get("container_id", ""))

static func _container_has_stack(runtime: Dictionary, container_id: String, item_template_id: String, amount: int) -> bool:
	if container_id == "":
		return false
	var container: Dictionary = runtime.get("asset_containers", {}).get(container_id, {})
	for stack_id in container.get("item_stack_refs", []):
		var stack: Dictionary = runtime.get("item_stacks", {}).get(str(stack_id), {})
		if str(stack.get("item_template_id", "")) == item_template_id and int(stack.get("amount", 0)) >= amount:
			return true
	return false

static func _character_has_sect_permission(runtime: Dictionary, actor_id: String, sect_id: String, permission: String) -> bool:
	var identity: Dictionary = runtime.get("incarnations", {}).get(actor_id, {}).get("sect_identity", {})
	if str(identity.get("sect_id", "")) != sect_id:
		return false
	return identity.get("permissions", []).has(permission)

static func _sect_storage_container_id(runtime: Dictionary, content: Dictionary, sect_id: String) -> String:
	if runtime.get("sect_states", {}).has(sect_id):
		return str(runtime["sect_states"][sect_id].get("storage_container_ref", {}).get("container_id", ""))
	return str(ContentLoader.sect_template(content, sect_id).get("storage_container_id", ""))

static func _node_has_available_resource_slot(runtime: Dictionary, node_id: String) -> bool:
	for slot_state in runtime.get("resource_slot_states", {}).values():
		if str(slot_state.get("node_id", "")) == node_id and int(slot_state.get("abundance", 0)) > 0:
			return true
	return false
