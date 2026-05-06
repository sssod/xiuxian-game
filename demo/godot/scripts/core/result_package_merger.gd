extends RefCounted

const DemoConstants = preload("res://scripts/core/demo_constants.gd")

static func merge(runtime: Dictionary, packages: Array) -> Dictionary:
	var applied_package_ids := []
	for package in packages:
		if typeof(package) != TYPE_DICTIONARY:
			continue
		applied_package_ids.append(package.get("package_id", "unknown_package"))
		_apply_room_state_delta(runtime, package.get("state_deltas", {}).get("room_state", {}))
		_apply_character_deltas(runtime, package.get("state_deltas", {}).get("character_states", {}))
		_apply_node_deltas(runtime, package.get("state_deltas", {}).get("node_states", {}))
		_append_state_entries(runtime, "rumor_pool", package.get("state_deltas", {}).get("rumor_pool_entries", []))
		_clear_pending_decisions(runtime, package.get("state_deltas", {}).get("clear_pending_player_decisions", []))
		_apply_player_lock_delta(runtime, package.get("state_deltas", {}).get("player_lock_state", {}))
		_append_logs(runtime, "world_logs", package.get("hidden_world_logs", []))
		_append_logs(runtime, "visible_logs", package.get("visible_logs", []))
		_append_logs(runtime, "debug_logs", package.get("debug_logs", []))
		if package.has("original_vs_actual_summary"):
			runtime["last_report"] = package["original_vs_actual_summary"]

	runtime["last_result_packages"] = packages
	_trim_debug_logs(runtime)
	return {
		"applied_package_ids": applied_package_ids,
		"state_version": runtime.get("room_state", {}).get("world_state_version", 0)
	}

static func _apply_room_state_delta(runtime: Dictionary, room_delta: Dictionary) -> void:
	if room_delta.is_empty():
		return
	var room_state: Dictionary = runtime.get("room_state", {})
	for key in room_delta.keys():
		if key == "world_state_version_increment":
			room_state["world_state_version"] = int(room_state.get("world_state_version", 0)) + int(room_delta[key])
		else:
			room_state[key] = room_delta[key]
	runtime["room_state"] = room_state

static func _apply_character_deltas(runtime: Dictionary, character_deltas: Dictionary) -> void:
	if character_deltas.is_empty():
		return
	var incarnations: Dictionary = runtime.get("incarnations", {})
	for character_id in character_deltas.keys():
		if not incarnations.has(character_id):
			incarnations[character_id] = {"character_id": character_id}
		var delta: Dictionary = character_deltas[character_id]
		for key in delta.keys():
			incarnations[character_id][key] = delta[key]
	runtime["incarnations"] = incarnations

static func _apply_node_deltas(runtime: Dictionary, node_deltas: Dictionary) -> void:
	if node_deltas.is_empty():
		return
	var node_states: Dictionary = runtime.get("node_states", {})
	for node_id in node_deltas.keys():
		if not node_states.has(node_id):
			node_states[node_id] = {"node_id": node_id}
		var delta: Dictionary = node_deltas[node_id]
		for key in delta.keys():
			if key == "append_state_tags":
				if not node_states[node_id].has("state_tags"):
					node_states[node_id]["state_tags"] = []
				for tag in delta[key]:
					if not node_states[node_id]["state_tags"].has(tag):
						node_states[node_id]["state_tags"].append(tag)
			elif key == "append_world_log_refs":
				if not node_states[node_id].has("world_log_refs"):
					node_states[node_id]["world_log_refs"] = []
				for log_ref in delta[key]:
					node_states[node_id]["world_log_refs"].append(log_ref)
			else:
				node_states[node_id][key] = delta[key]
	runtime["node_states"] = node_states

static func _append_state_entries(runtime: Dictionary, key: String, entries: Array) -> void:
	if entries.is_empty():
		return
	if not runtime.has(key):
		runtime[key] = []
	for entry in entries:
		runtime[key].append(entry)

static func _clear_pending_decisions(runtime: Dictionary, player_ids: Array) -> void:
	var pending: Dictionary = runtime.get("pending_player_decisions", {})
	for player_id in player_ids:
		pending[str(player_id)] = []
	runtime["pending_player_decisions"] = pending

static func _apply_player_lock_delta(runtime: Dictionary, lock_delta: Dictionary) -> void:
	if lock_delta.is_empty():
		return
	var player_id := str(lock_delta.get("player_id", ""))
	if player_id == "":
		return
	if not runtime.get("players", {}).has(player_id):
		return
	runtime["players"][player_id]["lock_state"] = str(lock_delta.get("lock_state", "unlocked"))

static func _append_logs(runtime: Dictionary, key: String, new_entries: Array) -> void:
	if not runtime.has(key):
		runtime[key] = []
	for entry in new_entries:
		runtime[key].append(entry)

static func _trim_debug_logs(runtime: Dictionary) -> void:
	var debug_logs: Array = runtime.get("debug_logs", [])
	while debug_logs.size() > DemoConstants.DEBUG_LOG_LIMIT:
		debug_logs.pop_front()
	runtime["debug_logs"] = debug_logs
