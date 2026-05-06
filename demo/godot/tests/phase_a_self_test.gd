extends SceneTree

const DemoConstants = preload("res://scripts/core/demo_constants.gd")
const ContentLoader = preload("res://scripts/core/content_loader.gd")
const RoomFactory = preload("res://scripts/core/room_factory.gd")
const TurnPhaseMachine = preload("res://scripts/core/turn_phase_machine.gd")
const PersonalActionInstruction = preload("res://scripts/core/personal_action_instruction.gd")
const ActionValidator = preload("res://scripts/core/action_validator.gd")
const SettlementService = preload("res://scripts/core/settlement_service.gd")
const ResultPackageMerger = preload("res://scripts/core/result_package_merger.gd")
const SaveManager = preload("res://scripts/core/save_manager.gd")

func _init() -> void:
	var failures := []
	var content := ContentLoader.load_content()
	if not content.get("errors", []).is_empty():
		failures.append("Content loading errors: %s" % str(content["errors"]))

	var runtime := RoomFactory.create_local_room(content.get("summary", {}), content)
	var planning_transition := TurnPhaseMachine.transition_to(runtime, "personal_action_planning")
	if not planning_transition["ok"]:
		failures.append("Phase transition to planning failed: %s" % str(planning_transition))

	var queue := [
		PersonalActionInstruction.make_rest(DemoConstants.LOCAL_CHARACTER_ID, 1, 24)
	]
	runtime["pending_player_decisions"][DemoConstants.LOCAL_PLAYER_ID] = queue

	var validation := ActionValidator.validate_queue(runtime, content, DemoConstants.LOCAL_PLAYER_ID, queue)
	if not validation["ok"]:
		failures.append("Validation failed unexpectedly: %s" % str(validation["errors"]))

	var lock_transition := TurnPhaseMachine.transition_to(runtime, "waiting_lock")
	if not lock_transition["ok"]:
		failures.append("Phase transition to waiting_lock failed: %s" % str(lock_transition))
	var settlement_transition := TurnPhaseMachine.transition_to(runtime, "settlement")
	if not settlement_transition["ok"]:
		failures.append("Phase transition to settlement failed: %s" % str(settlement_transition))

	var settlement := SettlementService.settle_turn(runtime, content, DemoConstants.LOCAL_PLAYER_ID)
	if not settlement["ok"]:
		failures.append("Settlement failed unexpectedly: %s" % str(settlement["validation"]))

	ResultPackageMerger.merge(runtime, settlement["packages"])

	var room: Dictionary = runtime["room_state"]
	if int(room["current_turn_id"]) != 2:
		failures.append("Expected current_turn_id=2, got %s" % str(room["current_turn_id"]))
	if int(room["current_world_day"]) != 6:
		failures.append("Expected current_world_day=6, got %s" % str(room["current_world_day"]))
	if int(room["current_world_hour"]) != 120:
		failures.append("Expected current_world_hour=120, got %s" % str(room["current_world_hour"]))
	if runtime.get("last_report", {}).is_empty():
		failures.append("OriginalVsActualSummary missing.")

	var replay_result := SaveManager.write_replay(settlement["turn_replay"])
	if not replay_result["ok"]:
		failures.append("Replay write failed: %s" % replay_result["error"])

	var save_result := SaveManager.save_game(runtime, "phase_a_self_test")
	if not save_result["ok"]:
		failures.append("Save failed: %s" % save_result["error"])

	var load_result := SaveManager.load_game("phase_a_self_test")
	if not load_result["ok"]:
		failures.append("Load failed: %s" % load_result["error"])
	else:
		var loaded_room: Dictionary = load_result["runtime"]["room_state"]
		if int(loaded_room["current_turn_id"]) != 2:
			failures.append("Loaded save did not preserve current_turn_id=2.")

	if failures.is_empty():
		print("Phase A self-test passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
