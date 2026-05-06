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

	var route := ContentLoader.route_between(content, "node_qinghe_village", "node_market_town")
	if route.is_empty():
		failures.append("Missing route node_qinghe_village -> node_market_town.")

	var queue := [
		PersonalActionInstruction.make_move_to_node(DemoConstants.LOCAL_CHARACTER_ID, 1, route),
		PersonalActionInstruction.make_node_action("ask_for_rumor", DemoConstants.LOCAL_CHARACTER_ID, 2, "node_market_town", 110)
	]
	runtime["pending_player_decisions"][DemoConstants.LOCAL_PLAYER_ID] = queue

	var validation := ActionValidator.validate_queue(runtime, content, DemoConstants.LOCAL_PLAYER_ID, queue)
	if not validation["ok"]:
		failures.append("Validation failed unexpectedly: %s" % str(validation["errors"]))

	TurnPhaseMachine.transition_to(runtime, "waiting_lock")
	TurnPhaseMachine.transition_to(runtime, "settlement")
	var settlement := SettlementService.settle_turn(runtime, content, DemoConstants.LOCAL_PLAYER_ID)
	if not settlement["ok"]:
		failures.append("Settlement failed unexpectedly: %s" % str(settlement["validation"]))

	ResultPackageMerger.merge(runtime, settlement["packages"])

	var character: Dictionary = runtime["incarnations"][DemoConstants.LOCAL_CHARACTER_ID]
	if str(character.get("current_location", "")) != "node_market_town":
		failures.append("Expected character to arrive at node_market_town, got %s." % str(character.get("current_location", "")))

	var report: Dictionary = runtime.get("last_report", {})
	if report.is_empty():
		failures.append("OriginalVsActualSummary missing.")
	else:
		if report.get("interruptions", []).is_empty():
			failures.append("Expected road_minor_delay interruption in report.")
		if not _actual_entries_include(report.get("actual_actions", []), "inserted_event:road_minor_delay"):
			failures.append("Expected inserted_event:road_minor_delay actual entry.")
		if not _actual_entries_include_partial(report.get("actual_actions", []), "ask_for_rumor"):
			failures.append("Expected ask_for_rumor to be partially executed after movement delay.")

	var market_state: Dictionary = runtime.get("node_states", {}).get("node_market_town", {})
	if str(market_state.get("visibility_state", "")) != "known":
		failures.append("Expected node_market_town visibility_state=known.")

	var training_state: Dictionary = runtime.get("node_states", {}).get("node_training_hall", {})
	if str(training_state.get("visibility_state", "")) != "known":
		failures.append("Expected node_training_hall to be revealed by market rumor.")

	if runtime.get("rumor_pool", []).is_empty():
		failures.append("Expected rumor_pool entry from ask_for_rumor.")

	var replay_result := SaveManager.write_replay(settlement["turn_replay"])
	if not replay_result["ok"]:
		failures.append("Replay write failed: %s" % replay_result["error"])

	var save_result := SaveManager.save_game(runtime, "phase_b_self_test")
	if not save_result["ok"]:
		failures.append("Save failed: %s" % save_result["error"])

	if failures.is_empty():
		print("Phase B self-test passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _actual_entries_include(entries: Array, action_id: String) -> bool:
	for entry in entries:
		if typeof(entry) == TYPE_DICTIONARY and str(entry.get("action_id", "")) == action_id:
			return true
	return false

func _actual_entries_include_partial(entries: Array, action_id: String) -> bool:
	for entry in entries:
		if typeof(entry) == TYPE_DICTIONARY and str(entry.get("action_id", "")) == action_id and str(entry.get("status", "")) == "partial":
			return true
	return false
