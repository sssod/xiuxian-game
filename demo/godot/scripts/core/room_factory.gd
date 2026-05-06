extends RefCounted

const DemoConstants = preload("res://scripts/core/demo_constants.gd")
const LogUtils = preload("res://scripts/core/log_utils.gd")

static func create_local_room(content_summary := {}, content := {}) -> Dictionary:
	var turn_config := DemoConstants.default_turn_config()
	var time_state := DemoConstants.make_time_state(1, 1, 0)
	var room_state := {
		"room_id": "local_demo_room",
		"room_mode": "local_single_player_demo",
		"world_seed": DemoConstants.DEFAULT_WORLD_SEED,
		"current_turn_id": time_state["turn_id"],
		"current_year": 1,
		"current_world_day": time_state["world_day"],
		"current_world_hour": time_state["world_hour"],
		"current_hour_tick": time_state["hour_tick"],
		"current_macro_period_id": time_state["macro_period_id"],
		"turn_config": turn_config,
		"current_phase": "turn_start",
		"player_slots": [DemoConstants.LOCAL_PLAYER_ID],
		"active_players": [DemoConstants.LOCAL_PLAYER_ID],
		"ai_controlled_factions": [],
		"world_state_version": 1,
		"pending_player_decisions": {},
		"settlement_status": "idle",
		"save_version": DemoConstants.SCHEMA_VERSION,
		"schema_version": DemoConstants.SCHEMA_VERSION,
		"content_version": DemoConstants.CONTENT_VERSION,
		"migration_notes": []
	}

	var runtime := {
		"runtime_kind": "RuntimeWorldState.phase_a_demo",
		"schema_version": DemoConstants.SCHEMA_VERSION,
		"content_version": DemoConstants.CONTENT_VERSION,
		"room_state": room_state,
		"players": {
			DemoConstants.LOCAL_PLAYER_ID: {
				"player_id": DemoConstants.LOCAL_PLAYER_ID,
				"display_name": "本地测试玩家",
				"controlled_spirit_id": DemoConstants.LOCAL_SPIRIT_ID,
				"current_character_id": DemoConstants.LOCAL_CHARACTER_ID,
				"connection_state": "local",
				"lock_state": "unlocked",
				"autopilot_preference": {},
				"visibility_cache_refs": []
			}
		},
		"true_spirits": {
			DemoConstants.LOCAL_SPIRIT_ID: {
				"spirit_id": DemoConstants.LOCAL_SPIRIT_ID,
				"true_name": "未命名真灵",
				"incarnation_count": 1,
				"reincarnation_ledger_refs": []
			}
		},
		"incarnations": {
			DemoConstants.LOCAL_CHARACTER_ID: {
				"character_id": DemoConstants.LOCAL_CHARACTER_ID,
				"spirit_id": DemoConstants.LOCAL_SPIRIT_ID,
				"current_name": "青禾村少年",
				"current_location": "node_qinghe_village",
				"death_state": "alive"
			}
		},
		"pending_player_decisions": {
			DemoConstants.LOCAL_PLAYER_ID: []
		},
		"visible_logs": [],
		"debug_logs": [],
		"last_result_packages": [],
		"last_report": {},
		"last_replay": {},
		"map_graph": _make_map_graph(content),
		"node_states": _make_node_states(content),
		"world_logs": [],
		"rumor_pool": [],
		"content_summary": content_summary
	}

	runtime["visible_logs"].append(LogUtils.visible("room_created", "本地 demo 房间已创建。", 1, 1, 0))
	runtime["debug_logs"].append(LogUtils.debug("room_initialized", "RoomState initialized for Phase A skeleton.", 1, 0, room_state.duplicate(true)))
	return runtime

static func set_phase(runtime: Dictionary, phase: String) -> void:
	if not DemoConstants.PHASES.has(phase):
		return
	runtime["room_state"]["current_phase"] = phase

static func ensure_phase_b_runtime_state(runtime: Dictionary, content: Dictionary) -> void:
	if not runtime.has("map_graph"):
		runtime["map_graph"] = _make_map_graph(content)
	if not runtime.has("node_states"):
		runtime["node_states"] = _make_node_states(content)
	if not runtime.has("world_logs"):
		runtime["world_logs"] = []
	if not runtime.has("rumor_pool"):
		runtime["rumor_pool"] = []

static func _make_map_graph(content: Dictionary) -> Dictionary:
	var routes := {}
	for route_id in content.get("tables", {}).get("routes", {}).keys():
		var route: Dictionary = content["tables"]["routes"][route_id]
		routes[route_id] = {
			"route_id": route_id,
			"from_node": route.get("from_node", ""),
			"to_node": route.get("to_node", ""),
			"base_travel_hours": int(route.get("base_travel_hours", 0)),
			"risk_tags": route.get("risk_tags", []),
			"state_tags": route.get("state_tags", []),
			"hidden_state": route.get("hidden_state", "known")
		}
	return {
		"routes": routes,
		"route_states": {}
	}

static func _make_node_states(content: Dictionary) -> Dictionary:
	var node_states := {}
	for node_id in content.get("tables", {}).get("nodes", {}).keys():
		var node: Dictionary = content["tables"]["nodes"][node_id]
		node_states[node_id] = {
			"node_id": node_id,
			"display_name": node.get("display_name", node_id),
			"node_type": node.get("node_type", ""),
			"region_id": node.get("region_id", ""),
			"zone_tier": node.get("zone_tier", ""),
			"visibility_state": node.get("visibility_state", "hidden"),
			"danger_profile": node.get("danger_profile", {}),
			"aura_profile": node.get("aura_profile", {}),
			"control_owner": node.get("control_owner", "none"),
			"resource_slots": node.get("resource_slots", []),
			"route_connections": node.get("route_connections", []),
			"state_tags": node.get("state_tags", []),
			"world_log_refs": []
		}
	return node_states
