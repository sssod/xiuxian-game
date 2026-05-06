extends RefCounted

const DemoConstants = preload("res://scripts/core/demo_constants.gd")
const LogUtils = preload("res://scripts/core/log_utils.gd")

static func create_local_room(content_summary := {}) -> Dictionary:
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
		"content_summary": content_summary
	}

	runtime["visible_logs"].append(LogUtils.visible("room_created", "本地 demo 房间已创建。", 1, 1, 0))
	runtime["debug_logs"].append(LogUtils.debug("room_initialized", "RoomState initialized for Phase A skeleton.", 1, 0, room_state.duplicate(true)))
	return runtime

static func set_phase(runtime: Dictionary, phase: String) -> void:
	if not DemoConstants.PHASES.has(phase):
		return
	runtime["room_state"]["current_phase"] = phase
