extends RefCounted

const DemoConstants = preload("res://scripts/core/demo_constants.gd")
const ContentLoader = preload("res://scripts/core/content_loader.gd")

static func validate_queue(runtime: Dictionary, content: Dictionary, player_id: String, action_queue: Array) -> Dictionary:
	var errors := []
	var planned_hours := 0
	var room_state: Dictionary = runtime.get("room_state", {})
	var turn_config: Dictionary = room_state.get("turn_config", DemoConstants.default_turn_config())
	var budget_hours := DemoConstants.turn_total_hours(turn_config)

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

	if planned_hours > budget_hours:
		errors.append("Action budget exceeded: %dh planned / %dh available." % [planned_hours, budget_hours])

	return {
		"ok": errors.is_empty(),
		"errors": errors,
		"player_id": player_id,
		"planned_hours": planned_hours,
		"budget_hours": budget_hours
	}
