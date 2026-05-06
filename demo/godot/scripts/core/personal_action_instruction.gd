extends RefCounted

const DemoConstants = preload("res://scripts/core/demo_constants.gd")

static func make_rest(actor_id := DemoConstants.LOCAL_CHARACTER_ID, sequence := 1, planned_duration_hours := 24) -> Dictionary:
	return {
		"instruction_id": "rest_or_guard_%02d" % sequence,
		"action_id": "rest_or_guard",
		"actor_id": actor_id,
		"target": {
			"target_type": "self",
			"target_id": actor_id
		},
		"planned_duration_hours": planned_duration_hours,
		"resource_bindings": [],
		"status": "draft"
	}

static func make_move_to_node(actor_id := DemoConstants.LOCAL_CHARACTER_ID, sequence := 1, route := {}) -> Dictionary:
	var to_node := str(route.get("to_node", ""))
	return {
		"instruction_id": "move_to_node_%02d" % sequence,
		"action_id": "move_to_node",
		"actor_id": actor_id,
		"target": {
			"target_type": "node",
			"target_id": to_node
		},
		"planned_duration_hours": int(route.get("base_travel_hours", 0)),
		"resource_bindings": [],
		"route_params": {
			"route_id": str(route.get("id", "")),
			"from_node": str(route.get("from_node", "")),
			"to_node": to_node,
			"risk_tags": route.get("risk_tags", [])
		},
		"status": "draft"
	}

static func make_node_action(action_id: String, actor_id := DemoConstants.LOCAL_CHARACTER_ID, sequence := 1, node_id := "", planned_duration_hours := 8) -> Dictionary:
	return {
		"instruction_id": "%s_%02d" % [action_id, sequence],
		"action_id": action_id,
		"actor_id": actor_id,
		"target": {
			"target_type": "node",
			"target_id": node_id
		},
		"planned_duration_hours": planned_duration_hours,
		"resource_bindings": [],
		"status": "draft"
	}

static func display_name(action: Dictionary) -> String:
	var target = action.get("target", {})
	var target_id := ""
	if typeof(target) == TYPE_DICTIONARY:
		target_id = str(target.get("target_id", ""))
	var suffix := ""
	if target_id != "":
		suffix = " -> %s" % target_id
	return "%s%s (%dh)" % [action.get("action_id", "unknown_action"), suffix, int(action.get("planned_duration_hours", 0))]
