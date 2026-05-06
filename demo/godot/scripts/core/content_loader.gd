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
