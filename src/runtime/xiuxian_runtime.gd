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


func enqueue_command(
		room,
		action_type: String,
		planned_duration_hours: int,
		resource_inputs: Array = [],
		options: Dictionary = {}
) -> Dictionary:
	var command = room.command_queue.create_player_command(
		action_type,
		planned_duration_hours,
		room.world_time.to_dict(),
		room.character_state.character_id,
		resource_inputs,
		options
	)
	var validation = settlement_engine.validate_command(room, data_registry, command, "enqueue")
	command["last_validation"] = validation.duplicate(true)
	command["f1_eligible"] = bool(validation.get("f1_eligible", false))
	if not bool(validation.get("ok", false)):
		return {
			"ok": false,
			"code": validation.get("code", "command_invalid"),
			"error": validation.get("error", ""),
			"command": command,
			"validation": validation,
		}

	var queue_result = room.command_queue.add_command(command)
	if bool(queue_result.get("ok", false)):
		room.replay_log.append_event(
			"command_enqueued",
			room.world_time.to_dict(),
			{
				"command": command.duplicate(true),
				"queue_result": queue_result.duplicate(true),
			}
		)
	queue_result["command"] = command
	queue_result["validation"] = validation
	return queue_result


func enqueue_active_breathing(room, planned_duration_hours: int = 4) -> Dictionary:
	return enqueue_command(room, "active_breathing", planned_duration_hours)


func enqueue_seclusion_cultivation(room, planned_duration_hours: int = 24) -> Dictionary:
	return enqueue_command(room, "seclusion_cultivation", planned_duration_hours)


func enqueue_method_study(room, planned_duration_hours: int = 4, target_method_id: String = "") -> Dictionary:
	var selected_target = target_method_id
	if selected_target.is_empty():
		selected_target = data_registry.get_default_method_study_target()
	return enqueue_command(
		room,
		"method_study",
		planned_duration_hours,
		[],
		{"target_method_id": selected_target}
	)


func enqueue_consolidation(room, planned_duration_hours: int = 4) -> Dictionary:
	return enqueue_command(room, "consolidation", planned_duration_hours)


func enqueue_managed_action(room, planned_duration_hours: int = 8) -> Dictionary:
	return enqueue_command(room, "managed_action", planned_duration_hours)


func enqueue_recovery(room, planned_duration_hours: int = 4) -> Dictionary:
	return enqueue_command(room, "rest", planned_duration_hours)


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
	var initial_command = enqueue_active_breathing(room, data_registry.get_smoke_post_load_f1_hours())
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
	var post_load_command = enqueue_active_breathing(loaded_room, f1_hours)
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
		and bool(initial_command.get("ok", false))
		and bool(post_load_command.get("ok", false))
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
		"commands": {
			"initial_active_breathing": initial_command,
			"post_load_active_breathing": post_load_command,
		},
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
			"cultivation_points": loaded_room.character_state.cultivation_state.get("cultivation_points", 0.0),
			"normalized_segment_progress": loaded_room.character_state.cultivation_state.get("normalized_segment_progress", 0.0),
			"current_command": loaded_room.command_queue.current_command.duplicate(true),
		},
		"ui_state": ui_adapter.from_room(loaded_room, post_load_results.back()),
	}


func run_active_breathing_smoke() -> Dictionary:
	var config_status = load_config()
	var room = create_single_player_room()
	var queue_result = enqueue_active_breathing(room, 31)
	var before_cp = float(room.character_state.cultivation_state.get("cultivation_points", 0.0))
	var results = advance_hours(room, 31, RuntimeConstantsScript.SPEED_F1)
	var after_cp = float(room.character_state.cultivation_state.get("cultivation_points", 0.0))
	var current_stage = str(room.character_state.cultivation_state.get("minor_stage", ""))
	var active_command = room.command_queue.current_command
	var fallback_running = bool(active_command.get("is_fallback", false))
	var minor_advanced = current_stage == "qi_refining_2"
	var cp_increased = after_cp > before_cp
	var result_count_ok = results.size() == 31
	var fallback_after_completion = fallback_running and room.speed_state == RuntimeConstantsScript.SPEED_N1
	var result_has_cultivation_tick = false
	if not results.is_empty():
		var last_result = results.back()
		result_has_cultivation_tick = last_result.deltas.get("command", {}).get("tick", {}).has("tick")
	var ok = (
		bool(config_status.get("ok", false))
		and bool(queue_result.get("ok", false))
		and cp_increased
		and minor_advanced
		and result_count_ok
		and fallback_after_completion
		and result_has_cultivation_tick
	)

	return {
		"ok": ok,
		"config": config_status,
		"queue": queue_result,
		"checks": {
			"before_cp": before_cp,
			"after_cp": after_cp,
			"minor_stage": current_stage,
			"result_count": results.size(),
			"fallback_after_completion": fallback_after_completion,
			"speed_state": room.speed_state,
			"result_has_cultivation_tick": result_has_cultivation_tick,
			"replay_entries": room.replay_log.entries.size(),
			"result_packages": room.result_history.size(),
		},
		"ui_state": ui_adapter.from_room(room, results.back()),
	}


func run_command_template_smoke() -> Dictionary:
	var config_status = load_config()

	var resource_room = create_single_player_room()
	var resource_rejection = enqueue_command(
		resource_room,
		"active_breathing",
		1,
		[{"resource_id": "mvp_missing_pill", "quantity": 1}]
	)
	var resource_rejection_ok = (
		not bool(resource_rejection.get("ok", false))
		and resource_rejection.get("code", "") == "resource_inputs_not_supported"
	)

	var seclusion_room = create_single_player_room()
	var seclusion_queue = enqueue_seclusion_cultivation(seclusion_room, data_registry.get_action_min_duration("seclusion_cultivation", 24))
	var seclusion_before_cp = float(seclusion_room.character_state.cultivation_state.get("cultivation_points", 0.0))
	var seclusion_results = advance_hours(seclusion_room, 2, RuntimeConstantsScript.SPEED_F1)
	var seclusion_after_cp = float(seclusion_room.character_state.cultivation_state.get("cultivation_points", 0.0))
	var seclusion_ok = (
		bool(seclusion_queue.get("ok", false))
		and seclusion_results.size() == 2
		and seclusion_after_cp > seclusion_before_cp
		and str(seclusion_room.command_queue.current_command.get("action_type", "")) == "seclusion_cultivation"
	)

	var consolidation_room = create_single_player_room()
	consolidation_room.character_state.cultivation_state["meridian_pressure"] = 0.25
	consolidation_room.character_state.cultivation_state["foundation_quality"] = 0.50
	var consolidation_before_cp = float(consolidation_room.character_state.cultivation_state.get("cultivation_points", 0.0))
	var consolidation_queue = enqueue_consolidation(consolidation_room, 2)
	var consolidation_results = advance_hours(consolidation_room, 2, RuntimeConstantsScript.SPEED_F1)
	var consolidation_after_pressure = float(consolidation_room.character_state.cultivation_state.get("meridian_pressure", 0.0))
	var consolidation_after_foundation = float(consolidation_room.character_state.cultivation_state.get("foundation_quality", 0.0))
	var consolidation_after_cp = float(consolidation_room.character_state.cultivation_state.get("cultivation_points", 0.0))
	var consolidation_ok = (
		bool(consolidation_queue.get("ok", false))
		and consolidation_results.size() == 2
		and consolidation_after_pressure < 0.25
		and consolidation_after_foundation > 0.50
		and is_equal_approx(consolidation_after_cp, consolidation_before_cp)
	)

	var method_room = create_single_player_room()
	var target_method_id = data_registry.get_default_method_study_target()
	var method_before = method_room.character_state.get_method_state(target_method_id)
	var method_before_cp = float(method_room.character_state.cultivation_state.get("cultivation_points", 0.0))
	var method_queue = enqueue_method_study(method_room, 3, target_method_id)
	var method_results = advance_hours(method_room, 3, RuntimeConstantsScript.SPEED_F1)
	var method_after = method_room.character_state.get_method_state(target_method_id)
	var method_after_cp = float(method_room.character_state.cultivation_state.get("cultivation_points", 0.0))
	var method_ok = (
		bool(method_queue.get("ok", false))
		and method_results.size() == 3
		and int(method_after.get("mastery_level", 1)) > int(method_before.get("mastery_level", 1))
		and is_equal_approx(method_after_cp, method_before_cp)
	)

	var managed_room = create_single_player_room()
	var managed_queue = enqueue_managed_action(managed_room, 2)
	var managed_first_results = advance_hours(managed_room, 1, RuntimeConstantsScript.SPEED_F1)
	var managed_state_during = managed_room.command_queue.managed_action_state.duplicate(true)
	var managed_second_results = advance_hours(managed_room, 1, RuntimeConstantsScript.SPEED_F1)
	var managed_ok = (
		bool(managed_queue.get("ok", false))
		and managed_first_results.size() == 1
		and managed_second_results.size() == 1
		and not managed_state_during.is_empty()
		and managed_room.command_queue.managed_action_state.is_empty()
		and managed_room.command_queue.is_current_fallback()
		and managed_room.speed_state == RuntimeConstantsScript.SPEED_N1
	)

	var rest_room = create_single_player_room()
	rest_room.character_state.cultivation_state["meridian_pressure"] = 0.20
	rest_room.character_state.derived_bars["qi"]["current"] = 20
	rest_room.character_state.derived_bars["mind"]["current"] = 10
	var rest_queue = enqueue_recovery(rest_room, 2)
	var rest_results = advance_hours(rest_room, 2, RuntimeConstantsScript.SPEED_F1)
	var rest_ok = (
		bool(rest_queue.get("ok", false))
		and bool(rest_queue.get("validation", {}).get("f1_eligible", false))
		and rest_results.size() == 2
		and float(rest_room.character_state.cultivation_state.get("meridian_pressure", 0.0)) < 0.20
		and float(rest_room.character_state.derived_bars.get("qi", {}).get("current", 0.0)) > 20.0
		and float(rest_room.character_state.derived_bars.get("mind", {}).get("current", 0.0)) > 10.0
	)

	var ok = (
		bool(config_status.get("ok", false))
		and resource_rejection_ok
		and seclusion_ok
		and consolidation_ok
		and method_ok
		and managed_ok
		and rest_ok
	)

	return {
		"ok": ok,
		"config": config_status,
		"resource_rejection": {
			"ok": resource_rejection_ok,
			"code": resource_rejection.get("code", ""),
			"validation": resource_rejection.get("validation", {}),
		},
		"seclusion": {
			"ok": seclusion_ok,
			"queue": seclusion_queue,
			"cp_before": seclusion_before_cp,
			"cp_after": seclusion_after_cp,
			"current_command": seclusion_room.command_queue.current_command.duplicate(true),
		},
		"consolidation": {
			"ok": consolidation_ok,
			"queue": consolidation_queue,
			"pressure_after": consolidation_after_pressure,
			"foundation_after": consolidation_after_foundation,
			"cp_after": consolidation_after_cp,
		},
		"method_study": {
			"ok": method_ok,
			"queue": method_queue,
			"before": method_before,
			"after": method_after,
			"cp_after": method_after_cp,
		},
		"managed_action": {
			"ok": managed_ok,
			"queue": managed_queue,
			"state_during": managed_state_during,
			"state_after": managed_room.command_queue.managed_action_state.duplicate(true),
			"current_command": managed_room.command_queue.current_command.duplicate(true),
		},
		"rest": {
			"ok": rest_ok,
			"queue": rest_queue,
			"pressure_after": rest_room.character_state.cultivation_state.get("meridian_pressure", 0.0),
			"bars_after": rest_room.character_state.derived_bars.duplicate(true),
		},
		"ui_state": ui_adapter.from_room(method_room, method_results.back()),
	}
