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

	return RoomStateScript.create_single_local(selected_name, selected_seed)


func advance_one_hour(room):
	return settlement_engine.advance_one_hour(room, data_registry)


func advance_hours(room, hours: int, speed_state: String = "") -> Array:
	return settlement_engine.advance_hours(room, data_registry, hours, speed_state)


func save_room(room, path: String = SaveRepositoryScript.DEFAULT_SAVE_PATH) -> Dictionary:
	return save_repository.save_room(room, path)


func load_room(path: String = SaveRepositoryScript.DEFAULT_SAVE_PATH) -> Dictionary:
	return save_repository.load_room(path)


func run_empty_room_smoke() -> Dictionary:
	var config_status = load_config()
	var room = create_single_player_room()
	var result = advance_one_hour(room)

	return {
		"ok": bool(config_status.get("ok", false)),
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

	var missing_load_result = load_room("user://missing_save_diagnostic_%d.json" % Time.get_ticks_usec())
	var missing_load_diagnostic_ok = (
		not bool(missing_load_result.get("ok", false))
		and missing_load_result.get("code", "") == "save_missing"
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
	var preserved = (
		loaded_room.room_id == room.room_id
		and loaded_room.mode == room.mode
		and loaded_room.save_lineage == room.save_lineage
		and loaded_room.world_seed == room.world_seed
		and loaded_room.world_time.world_day == room.world_time.world_day
		and loaded_room.world_time.world_hour == room.world_time.world_hour
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
		and missing_load_diagnostic_ok
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
			"interrupted_settlement_recovery": {
				"ok": interrupted_recovery_ok,
				"recovery": interrupted_recovery,
				"active_state": interrupted_room.active_state if interrupted_room != null else "",
			},
		},
		"checks": {
			"first_result_id": first_result.result_id,
			"save_load_preserved": preserved,
			"f1_tick_result_count": post_load_results.size(),
			"expected_f1_tick_result_count": f1_hours,
			"result_packages": loaded_room.result_history.size(),
			"replay_entries": loaded_room.replay_log.entries.size(),
			"speed_state": loaded_room.speed_state,
			"world_time": loaded_room.world_time.to_dict(),
		},
		"ui_state": ui_adapter.from_room(loaded_room, post_load_results.back()),
	}
