extends RefCounted
class_name XiuxianRuntime

const RuntimeConstantsScript = preload("res://src/runtime/runtime_constants.gd")
const DataRegistryScript = preload("res://src/runtime/data_registry.gd")
const SettlementEngineScript = preload("res://src/runtime/settlement_engine.gd")
const UiStateAdapterScript = preload("res://src/runtime/ui_state_adapter.gd")
const RoomStateScript = preload("res://src/runtime/room_state.gd")

var data_registry = DataRegistryScript.new()
var settlement_engine = SettlementEngineScript.new()
var ui_adapter = UiStateAdapterScript.new()


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
