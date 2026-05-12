extends RefCounted
class_name XiuxianRuntime

const RuntimeConstantsScript = preload("res://src/runtime/runtime_constants.gd")
const DataRegistryScript = preload("res://src/runtime/data_registry.gd")
const SettlementEngineScript = preload("res://src/runtime/settlement_engine.gd")
const UiStateAdapterScript = preload("res://src/runtime/ui_state_adapter.gd")
const RoomStateScript = preload("res://src/runtime/room_state.gd")
const SaveRepositoryScript = preload("res://src/runtime/save_repository.gd")

var data_registry = DataRegistryScript.new()
var settlement_engine = SettlementEngineScript.new()
var ui_adapter = UiStateAdapterScript.new()
var save_repository = SaveRepositoryScript.new()


func load_config(path: String = RuntimeConstantsScript.DEFAULT_CONFIG_PATH) -> Dictionary:
	return data_registry.load_config(path)


func create_single_player_room(room_name: String = "", seed_value: int = -1):
	var selected_name = room_name
	if selected_name.is_empty():
		selected_name = data_registry.get_smoke_room_name()

	var selected_seed = seed_value
	if selected_seed < 0:
		selected_seed = data_registry.get_default_world_seed()

	var room = RoomStateScript.create_single_local(selected_name, selected_seed)
	var character_init = room.character_state.initialize_first_entry(
		data_registry.get_character_init_config(),
		selected_seed,
		room.world_time.to_dict()
	)
	if bool(character_init.get("ok", false)):
		room.replay_log.append_event(
			"character_initialized",
			room.world_time.to_dict(),
			{
				"character_id": character_init.get("character_id", ""),
				"true_spirit_id": character_init.get("true_spirit_id", ""),
				"init_context": "first_entry",
				"has_secular_background_identity": room.character_state.identity.get("has_secular_background_identity", true),
			}
		)
	return room


func advance_one_hour(room):
	return settlement_engine.advance_one_hour(room, data_registry)


func advance_hours(room, hours: int, speed_state: String = "") -> Array:
	return settlement_engine.advance_hours(room, data_registry, hours, speed_state)


func save_room(room, path: String = SaveRepositoryScript.DEFAULT_SAVE_PATH) -> Dictionary:
	return save_repository.save_room(room, path)


func diagnose_save_slot(path: String = SaveRepositoryScript.DEFAULT_SAVE_PATH) -> Dictionary:
	return save_repository.diagnose_save_slot(path)


func load_room(path: String = SaveRepositoryScript.DEFAULT_SAVE_PATH) -> Dictionary:
	return save_repository.load_room(path)


func run_empty_room_smoke() -> Dictionary:
	var config_status = load_config()
	var room = create_single_player_room()
	var result = advance_one_hour(room)

	return {
		"ok": bool(config_status.get("ok", false)) and room.character_state.initialized,
		"app_version": RuntimeConstantsScript.APP_VERSION,
		"godot_version_target": RuntimeConstantsScript.GODOT_VERSION_TARGET,
		"config": config_status,
		"room": room.to_dict(),
		"ui_state": ui_adapter.from_room(room, result),
		"result_package": result.to_dict(),
	}


func run_save_load_recovery_smoke() -> Dictionary:
	var config_status = load_config()
	var room = create_single_player_room()
	var first_result = advance_one_hour(room)
	var save_result = save_room(room)
	if not bool(save_result.get("ok", false)):
		return {
			"ok": false,
			"config": config_status,
			"save": save_result,
			"stage": "save",
		}

	var slot_diagnostic_result = diagnose_save_slot()
	var slot_diagnostic_ok = (
		bool(slot_diagnostic_result.get("ok", false))
		and bool(slot_diagnostic_result.get("can_continue", false))
		and slot_diagnostic_result.get("code", "") == "save_available"
		and slot_diagnostic_result.get("mode", "") == RuntimeConstantsScript.ROOM_MODE_SINGLE_LOCAL
		and slot_diagnostic_result.get("save_lineage", "") == RuntimeConstantsScript.SAVE_LINEAGE_SINGLE
	)

	var missing_load_result = load_room("user://missing_save_diagnostic_%d.json" % Time.get_ticks_usec())
	var missing_load_diagnostic_ok = (
		not bool(missing_load_result.get("ok", false))
		and missing_load_result.get("code", "") == "save_missing"
	)

	var invalid_json_result = save_repository.deserialize_room("{")
	var invalid_json_diagnostic_ok = (
		not bool(invalid_json_result.get("ok", false))
		and invalid_json_result.get("code", "") == "invalid_json"
	)

	var malformed_snapshot = room.to_dict()
	malformed_snapshot.erase("world_time")
	var malformed_load_result = save_repository.deserialize_room(JSON.stringify(malformed_snapshot))
	var malformed_diagnostic_ok = (
		not bool(malformed_load_result.get("ok", false))
		and malformed_load_result.get("code", "") == "missing_required_field"
		and malformed_load_result.get("field", "") == "world_time"
	)

	var unsupported_version_snapshot = room.to_dict()
	unsupported_version_snapshot["save_version"] = RuntimeConstantsScript.SAVE_SCHEMA_VERSION + 1
	var unsupported_version_load_result = save_repository.deserialize_room(JSON.stringify(unsupported_version_snapshot))
	var unsupported_version_diagnostic_ok = (
		not bool(unsupported_version_load_result.get("ok", false))
		and unsupported_version_load_result.get("code", "") == "unsupported_save_version"
	)

	var unsupported_mode_snapshot = room.to_dict()
	unsupported_mode_snapshot["mode"] = "private_hosted"
	var unsupported_mode_load_result = save_repository.deserialize_room(JSON.stringify(unsupported_mode_snapshot))
	var unsupported_mode_diagnostic_ok = (
		not bool(unsupported_mode_load_result.get("ok", false))
		and unsupported_mode_load_result.get("code", "") == "unsupported_room_mode"
	)

	var unsupported_lineage_snapshot = room.to_dict()
	unsupported_lineage_snapshot["save_lineage"] = "multiplayer_only"
	var unsupported_lineage_load_result = save_repository.deserialize_room(JSON.stringify(unsupported_lineage_snapshot))
	var unsupported_lineage_diagnostic_ok = (
		not bool(unsupported_lineage_load_result.get("ok", false))
		and unsupported_lineage_load_result.get("code", "") == "unsupported_save_lineage"
	)

	var unsupported_state_snapshot = room.to_dict()
	unsupported_state_snapshot["active_state"] = "paused_by_unknown_future_state"
	var unsupported_state_load_result = save_repository.deserialize_room(JSON.stringify(unsupported_state_snapshot))
	var unsupported_state_diagnostic_ok = (
		not bool(unsupported_state_load_result.get("ok", false))
		and unsupported_state_load_result.get("code", "") == "unsupported_active_state"
	)

	var interrupted_snapshot = room.to_dict()
	interrupted_snapshot["active_state"] = RuntimeConstantsScript.ROOM_SETTLEMENT_IN_PROGRESS_STATE
	var interrupted_load_result = save_repository.deserialize_room(JSON.stringify(interrupted_snapshot))
	var interrupted_room = interrupted_load_result.get("room", null)
	var interrupted_recovery = interrupted_load_result.get("recovery", {})
	var interrupted_recovery_ok = (
		bool(interrupted_load_result.get("ok", false))
		and interrupted_room != null
		and bool(interrupted_recovery.get("recovered", false))
		and interrupted_room.active_state == RuntimeConstantsScript.ROOM_ACTIVE_STATE
	)

	var load_result = load_room()
	if not bool(load_result.get("ok", false)):
		return {
			"ok": false,
			"config": config_status,
			"save": save_result,
			"load": load_result,
			"stage": "load",
		}

	var loaded_room = load_result.get("room")
	var preserved_result_history = loaded_room.result_history.size() == room.result_history.size()
	var preserved_character = (
		loaded_room.character_state.initialized
		and loaded_room.character_state.character_id == room.character_state.character_id
		and loaded_room.character_state.true_spirit_id == room.character_state.true_spirit_id
		and loaded_room.character_state.identity.get("has_secular_background_identity", true) == false
	)
	var preserved = (
		loaded_room.room_id == room.room_id
		and loaded_room.mode == room.mode
		and loaded_room.save_lineage == room.save_lineage
		and loaded_room.world_seed == room.world_seed
		and loaded_room.world_time.world_day == room.world_time.world_day
		and loaded_room.world_time.world_hour == room.world_time.world_hour
		and preserved_result_history
		and preserved_character
	)

	var f1_hours = data_registry.get_smoke_post_load_f1_hours()
	var post_load_results = advance_hours(
		loaded_room,
		f1_hours,
		RuntimeConstantsScript.SPEED_F1
	)
	var second_save_result = save_room(loaded_room)
	var ok = (
		bool(config_status.get("ok", false))
		and preserved
		and slot_diagnostic_ok
		and missing_load_diagnostic_ok
		and invalid_json_diagnostic_ok
		and malformed_diagnostic_ok
		and unsupported_version_diagnostic_ok
		and unsupported_mode_diagnostic_ok
		and unsupported_lineage_diagnostic_ok
		and unsupported_state_diagnostic_ok
		and interrupted_recovery_ok
		and post_load_results.size() == f1_hours
		and bool(second_save_result.get("ok", false))
	)

	return {
		"ok": ok,
		"app_version": RuntimeConstantsScript.APP_VERSION,
		"godot_version_target": RuntimeConstantsScript.GODOT_VERSION_TARGET,
		"config": config_status,
		"save": save_result,
		"save_slot": slot_diagnostic_result,
		"load": {
			"ok": load_result.get("ok", false),
			"path": load_result.get("path", ""),
			"recovery": load_result.get("recovery", {}),
		},
		"second_save": second_save_result,
		"diagnostics": {
			"missing_load": {
				"ok": missing_load_diagnostic_ok,
				"code": missing_load_result.get("code", ""),
				"error": missing_load_result.get("error", ""),
			},
			"invalid_json": {
				"ok": invalid_json_diagnostic_ok,
				"code": invalid_json_result.get("code", ""),
				"error": invalid_json_result.get("error", ""),
			},
			"malformed_shape": {
				"ok": malformed_diagnostic_ok,
				"code": malformed_load_result.get("code", ""),
				"field": malformed_load_result.get("field", ""),
				"error": malformed_load_result.get("error", ""),
			},
			"unsupported_save_version": {
				"ok": unsupported_version_diagnostic_ok,
				"code": unsupported_version_load_result.get("code", ""),
				"save_version": unsupported_version_load_result.get("save_version", -1),
				"supported_save_version": unsupported_version_load_result.get("supported_save_version", -1),
			},
			"unsupported_room_mode": {
				"ok": unsupported_mode_diagnostic_ok,
				"code": unsupported_mode_load_result.get("code", ""),
				"mode": unsupported_mode_load_result.get("mode", ""),
			},
			"unsupported_save_lineage": {
				"ok": unsupported_lineage_diagnostic_ok,
				"code": unsupported_lineage_load_result.get("code", ""),
				"save_lineage": unsupported_lineage_load_result.get("save_lineage", ""),
			},
			"unsupported_active_state": {
				"ok": unsupported_state_diagnostic_ok,
				"code": unsupported_state_load_result.get("code", ""),
				"active_state": unsupported_state_load_result.get("active_state", ""),
			},
			"interrupted_settlement_recovery": {
				"ok": interrupted_recovery_ok,
				"recovery": interrupted_recovery,
				"active_state": interrupted_room.active_state if interrupted_room != null else "",
			},
		},
		"checks": {
			"first_result_id": first_result.result_id,
			"save_load_preserved": preserved,
			"character_preserved": preserved_character,
			"result_history_preserved": preserved_result_history,
			"f1_tick_result_count": post_load_results.size(),
			"expected_f1_tick_result_count": f1_hours,
			"result_packages": loaded_room.result_history.size(),
			"replay_entries": loaded_room.replay_log.entries.size(),
			"speed_state": loaded_room.speed_state,
			"world_time": loaded_room.world_time.to_dict(),
		},
		"ui_state": ui_adapter.from_room(loaded_room, post_load_results.back()),
	}
