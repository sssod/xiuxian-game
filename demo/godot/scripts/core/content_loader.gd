extends RefCounted

const DemoConstants = preload("res://scripts/core/demo_constants.gd")

const TABLE_FILES := {
	"actions": "actions.json",
	"nodes": "nodes.json",
	"routes": "routes.json",
	"events": "events.json",
	"items": "items.json",
	"sects": "sects.json",
	"ai_actions": "ai_actions.json"
}

static func load_content(base_path := "res://data") -> Dictionary:
	var content := {
		"schema_version": DemoConstants.SCHEMA_VERSION,
		"content_version": DemoConstants.CONTENT_VERSION,
		"errors": [],
		"tables": {},
		"summary": {}
	}

	for table_name in TABLE_FILES.keys():
		var path := "%s/%s" % [base_path, TABLE_FILES[table_name]]
		var table_result := _load_json_array(path)
		content["tables"][table_name] = _index_by_id(table_result["rows"])
		content["summary"][table_name] = table_result["rows"].size()
		for error in table_result["errors"]:
			content["errors"].append(error)

	return content

static func action_template(content: Dictionary, action_id: String) -> Dictionary:
	return content.get("tables", {}).get("actions", {}).get(action_id, {})

static func node_template(content: Dictionary, node_id: String) -> Dictionary:
	return content.get("tables", {}).get("nodes", {}).get(node_id, {})

static func route_template(content: Dictionary, route_id: String) -> Dictionary:
	return content.get("tables", {}).get("routes", {}).get(route_id, {})

static func event_template(content: Dictionary, event_id: String) -> Dictionary:
	return content.get("tables", {}).get("events", {}).get(event_id, {})

static func item_template(content: Dictionary, item_template_id: String) -> Dictionary:
	return content.get("tables", {}).get("items", {}).get(item_template_id, {})

static func sect_template(content: Dictionary, sect_id: String) -> Dictionary:
	return content.get("tables", {}).get("sects", {}).get(sect_id, {})

static func ai_action_template(content: Dictionary, action_id: String) -> Dictionary:
	return content.get("tables", {}).get("ai_actions", {}).get(action_id, {})

static func ai_actions_for_sect(content: Dictionary, sect_id: String) -> Array:
	var actions := []
	for action in content.get("tables", {}).get("ai_actions", {}).values():
		if str(action.get("sect_id", "")) == sect_id:
			actions.append(action)
	actions.sort_custom(func(a, b): return int(a.get("priority", 0)) > int(b.get("priority", 0)))
	return actions

static func route_between(content: Dictionary, from_node: String, to_node: String) -> Dictionary:
	for route in content.get("tables", {}).get("routes", {}).values():
		if str(route.get("from_node", "")) == from_node and str(route.get("to_node", "")) == to_node:
			return route
	return {}

static func route_path_between(content: Dictionary, from_node: String, to_node: String, allowed_node_ids := []) -> Dictionary:
	if from_node == "" or to_node == "" or from_node == to_node:
		return {}

	var allowed_lookup := {}
	for node_id in allowed_node_ids:
		allowed_lookup[str(node_id)] = true

	var queue := [{
		"node_id": from_node,
		"route_path": [],
		"base_travel_hours": 0,
		"risk_tags": []
	}]
	var visited := {from_node: true}

	while not queue.is_empty():
		var current: Dictionary = queue.pop_front()
		var current_node := str(current.get("node_id", ""))
		for route in routes_from_node(content, current_node):
			var next_node := str(route.get("to_node", ""))
			if next_node == "":
				continue
			if not allowed_lookup.is_empty() and not allowed_lookup.has(next_node):
				continue
			if visited.has(next_node):
				continue

			var next_path: Array = current.get("route_path", []).duplicate(true)
			next_path.append(_route_path_step(route))
			var next_hours := int(current.get("base_travel_hours", 0)) + int(route.get("base_travel_hours", 0))
			var next_risk_tags: Array = current.get("risk_tags", []).duplicate(true)
			for risk_tag in route.get("risk_tags", []):
				if not next_risk_tags.has(risk_tag):
					next_risk_tags.append(risk_tag)

			if next_node == to_node:
				return {
					"id": "path_%s_to_%s" % [from_node, to_node],
					"from_node": from_node,
					"to_node": to_node,
					"base_travel_hours": next_hours,
					"risk_tags": next_risk_tags,
					"route_path": next_path
				}

			visited[next_node] = true
			queue.append({
				"node_id": next_node,
				"route_path": next_path,
				"base_travel_hours": next_hours,
				"risk_tags": next_risk_tags
			})

	return {}

static func routes_from_node(content: Dictionary, from_node: String) -> Array:
	var routes := []
	for route in content.get("tables", {}).get("routes", {}).values():
		if str(route.get("from_node", "")) == from_node:
			routes.append(route)
	return routes

static func node_events(content: Dictionary, trigger_scope: String, node_id: String) -> Array:
	var events := []
	for event in content.get("tables", {}).get("events", {}).values():
		if str(event.get("trigger_scope", "")) != trigger_scope:
			continue
		if str(event.get("trigger_node_id", "")) != node_id:
			continue
		events.append(event)
	return events

static func _load_json_array(path: String) -> Dictionary:
	var result := {
		"rows": [],
		"errors": []
	}
	if not FileAccess.file_exists(path):
		result["errors"].append("Missing content file: %s" % path)
		return result

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		result["errors"].append("Cannot read content file: %s" % path)
		return result

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		result["errors"].append("Content file must contain an array: %s" % path)
		return result

	result["rows"] = parsed
	return result

static func _index_by_id(rows: Array) -> Dictionary:
	var indexed := {}
	for row in rows:
		if typeof(row) != TYPE_DICTIONARY:
			continue
		var stable_id := str(row.get("id", row.get("action_id", row.get("node_id", ""))))
		if stable_id == "":
			continue
		indexed[stable_id] = row
	return indexed

static func _route_path_step(route: Dictionary) -> Dictionary:
	return {
		"route_id": str(route.get("id", "")),
		"from_node": str(route.get("from_node", "")),
		"to_node": str(route.get("to_node", "")),
		"base_travel_hours": int(route.get("base_travel_hours", 0)),
		"risk_tags": route.get("risk_tags", [])
	}
