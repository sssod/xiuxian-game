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

static func display_name(action: Dictionary) -> String:
	return "%s (%dh)" % [action.get("action_id", "unknown_action"), int(action.get("planned_duration_hours", 0))]
