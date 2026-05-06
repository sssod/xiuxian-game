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

	if action_queue.size() > 3:
		errors.append("Phase B demo supports up to 3 planned personal actions per turn.")

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

		var resource_bindings = action.get("resource_bindings", [])
		if typeof(resource_bindings) != TYPE_ARRAY:
			errors.append("%s resource_bindings must be an array." % action_id)

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
			var route := ContentLoader.route_between(content, from_node, target_node)
			if route.is_empty():
				errors.append("No route from %s to %s for move_to_node." % [from_node, target_node])
			else:
				var required_hours := int(route.get("base_travel_hours", 0))
				if duration < required_hours:
					errors.append("move_to_node planned_duration_hours must cover route time: %dh required." % required_hours)
				simulated_locations[actor_id] = target_node
		elif action_id in ["ask_for_rumor", "explore_node", "gather_resource", "active_cultivation"]:
			var action_node := ""
			if typeof(target) == TYPE_DICTIONARY:
				action_node = str(target.get("target_id", ""))
			var expected_node := str(simulated_locations.get(actor_id, ""))
			if action_node != "" and expected_node != "" and action_node != expected_node:
				errors.append("%s target must match planned location %s, got %s." % [action_id, expected_node, action_node])

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
