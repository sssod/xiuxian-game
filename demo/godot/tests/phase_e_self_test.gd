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

	var ready_runtime := _make_breakthrough_ready_runtime(content, failures)
	if not failures.is_empty():
		_finish(failures)
		return

	var success_runtime := ready_runtime.duplicate(true)
	_settle_queue(success_runtime, content, [
		PersonalActionInstruction.make_attempt_breakthrough(DemoConstants.LOCAL_CHARACTER_ID, 1, "node_outer_sect_room", true, "stabilize_foundation")
	], failures, "attempt_breakthrough_success")
	if str(_character(success_runtime).get("cultivation", {}).get("current_stage_code", "")) != "B-1":
		failures.append("Expected successful breakthrough to move character to B-1.")
	if str(success_runtime.get("demo_summary", {}).get("status", "")) != "completed":
		failures.append("Expected demo_summary.status=completed after first breakthrough.")
	if success_runtime.get("ledger_states", {}).get("ledger_local_stub", {}).get("entries", []).is_empty():
		failures.append("Expected ledger stub entry after breakthrough.")
	if not _logs_include(success_runtime.get("asset_logs", []), "breakthrough_key_consumed"):
		failures.append("Expected asset log for breakthrough key item consumption.")
	if not _logs_include(success_runtime.get("sect_logs", []), "sect_breakthrough_summary"):
		failures.append("Expected sect summary log for breakthrough result.")
	if success_runtime.get("last_report", {}).get("breakthrough_outcomes", []).is_empty():
		failures.append("Expected breakthrough_outcomes in turn report.")
	if not _key_instances_consumed(success_runtime):
		failures.append("Expected key item instances to remain traceable and marked consumed.")

	var survived_runtime := ready_runtime.duplicate(true)
	_settle_queue(survived_runtime, content, [
		PersonalActionInstruction.make_attempt_breakthrough(DemoConstants.LOCAL_CHARACTER_ID, 1, "node_outer_sect_room", false, "force_meridian")
	], failures, "attempt_breakthrough_failure_survived")
	if _last_breakthrough_result(survived_runtime) != "failure_survived":
		failures.append("Expected force_meridian path without stability_talisman to fail but survive, got %s." % _last_breakthrough_result(survived_runtime))
	if _last_fail_tags(survived_runtime).is_empty():
		failures.append("Expected failure_survived path to include fail_reason_tags.")

	var severe_runtime := ready_runtime.duplicate(true)
	severe_runtime["incarnations"][DemoConstants.LOCAL_CHARACTER_ID]["derived_bars"]["bar_mind_current"] = 20.0
	var severe_action := PersonalActionInstruction.make_attempt_breakthrough(DemoConstants.LOCAL_CHARACTER_ID, 1, "node_outer_sect_room", false, "force_meridian")
	severe_action["breakthrough_choices"].append("abandon_guard")
	_settle_queue(severe_runtime, content, [severe_action], failures, "attempt_breakthrough_severe")
	if _last_breakthrough_result(severe_runtime) != "severe_injury_interrupted":
		failures.append("Expected low-mind reckless path to be severe_injury_interrupted, got %s." % _last_breakthrough_result(severe_runtime))
	if _character(severe_runtime).get("injuries_and_conditions", []).is_empty():
		failures.append("Expected severe interruption to write injury condition.")

	var save_result := SaveManager.save_game(success_runtime, "phase_e_self_test")
	if not save_result["ok"]:
		failures.append("Save failed: %s" % save_result["error"])
	var load_result := SaveManager.load_game("phase_e_self_test")
	if not load_result["ok"]:
		failures.append("Load failed: %s" % load_result["error"])
	else:
		RoomFactory.ensure_phase_e_runtime_state(load_result["runtime"], content)
		if str(load_result["runtime"].get("demo_summary", {}).get("status", "")) != "completed":
			failures.append("Loaded save did not preserve Phase E demo summary.")
		if load_result["runtime"].get("ledger_states", {}).get("ledger_local_stub", {}).get("entries", []).is_empty():
			failures.append("Loaded save did not preserve ledger breakthrough entry.")

	_finish(failures)

func _make_breakthrough_ready_runtime(content: Dictionary, failures: Array) -> Dictionary:
	var runtime := RoomFactory.create_local_room(content.get("summary", {}), content)
	RoomFactory.ensure_phase_e_runtime_state(runtime, content)
	var route_outer := ContentLoader.route_between(content, "node_qinghe_village", "node_outer_mountain_road")
	var route_yunlu := ContentLoader.route_between(content, "node_outer_mountain_road", "node_yunlu_mountain_road")
	var route_gate := ContentLoader.route_between(content, "node_yunlu_mountain_road", "node_yunlu_gate")
	_settle_queue(runtime, content, [
		PersonalActionInstruction.make_move_to_node(DemoConstants.LOCAL_CHARACTER_ID, 1, route_outer),
		PersonalActionInstruction.make_move_to_node(DemoConstants.LOCAL_CHARACTER_ID, 2, route_yunlu),
		PersonalActionInstruction.make_move_to_node(DemoConstants.LOCAL_CHARACTER_ID, 3, route_gate)
	], failures, "travel_to_yunlu_gate")
	_settle_queue(runtime, content, [
		PersonalActionInstruction.make_join_sect_event(DemoConstants.LOCAL_CHARACTER_ID, 1, "node_yunlu_gate", 12)
	], failures, "sect_entry")
	_settle_queue(runtime, content, [
		PersonalActionInstruction.make_study_method(DemoConstants.LOCAL_CHARACTER_ID, 1, "node_outer_sect_room", 72)
	], failures, "study_to_A3_cap")
	_settle_queue(runtime, content, [
		PersonalActionInstruction.make_request_sect_resource(DemoConstants.LOCAL_CHARACTER_ID, 1, "sect_yunlu", "stability_talisman", 1, 4)
	], failures, "request_stability_talisman")
	_settle_queue(runtime, content, [
		PersonalActionInstruction.make_active_cultivation(DemoConstants.LOCAL_CHARACTER_ID, 1, "node_outer_sect_room", 120, false)
	], failures, "cultivate_to_A2")
	_settle_queue(runtime, content, [
		PersonalActionInstruction.make_active_cultivation(DemoConstants.LOCAL_CHARACTER_ID, 1, "node_outer_sect_room", 120, false)
	], failures, "cultivate_to_A3")
	_settle_queue(runtime, content, [
		PersonalActionInstruction.make_active_cultivation(DemoConstants.LOCAL_CHARACTER_ID, 1, "node_outer_sect_room", 120, false)
	], failures, "cultivate_to_A3_bottleneck")
	var cultivation: Dictionary = _character(runtime).get("cultivation", {})
	if str(cultivation.get("current_stage_code", "")) != "A-3":
		failures.append("Expected demo bottleneck stage A-3 before preparation, got %s." % str(cultivation.get("current_stage_code", "")))
	if str(cultivation.get("bottleneck_state", "")) != "breakthrough_required":
		failures.append("Expected demo bottleneck before preparation, got %s." % str(cultivation.get("bottleneck_state", "")))
	_settle_queue(runtime, content, [
		PersonalActionInstruction.make_prepare_breakthrough(DemoConstants.LOCAL_CHARACTER_ID, 1, "node_outer_sect_room", 24)
	], failures, "prepare_breakthrough")
	if not _has_available_item_instance(runtime, "trial_token_instance") or not _has_available_item_instance(runtime, "breakthrough_catalyst_instance"):
		failures.append("Expected prepare_breakthrough to grant traceable key item instances.")
	if not _character(runtime).get("sect_identity", {}).get("special_authorizations", []).has("demo_breakthrough_support"):
		failures.append("Expected prepare_breakthrough to record sect breakthrough support authorization.")
	return runtime

func _settle_queue(runtime: Dictionary, content: Dictionary, queue: Array, failures: Array, label: String) -> void:
	var transition := TurnPhaseMachine.transition_to(runtime, "personal_action_planning")
	if not transition["ok"]:
		failures.append("%s: phase transition to planning failed: %s" % [label, str(transition)])
	runtime["pending_player_decisions"][DemoConstants.LOCAL_PLAYER_ID] = queue
	var validation := ActionValidator.validate_queue(runtime, content, DemoConstants.LOCAL_PLAYER_ID, queue)
	if not validation["ok"]:
		failures.append("%s: validation failed: %s" % [label, str(validation["errors"])])
		return
	TurnPhaseMachine.transition_to(runtime, "waiting_lock")
	TurnPhaseMachine.transition_to(runtime, "settlement")
	var settlement := SettlementService.settle_turn(runtime, content, DemoConstants.LOCAL_PLAYER_ID)
	if not settlement["ok"]:
		failures.append("%s: settlement failed: %s" % [label, str(settlement["validation"])])
		return
	ResultPackageMerger.merge(runtime, settlement["packages"])
	runtime["last_replay"] = settlement["turn_replay"]

func _character(runtime: Dictionary) -> Dictionary:
	return runtime.get("incarnations", {}).get(DemoConstants.LOCAL_CHARACTER_ID, {})

func _inventory(runtime: Dictionary) -> Dictionary:
	var container_id := str(_character(runtime).get("inventory_container_ref", {}).get("container_id", ""))
	return runtime.get("asset_containers", {}).get(container_id, {})

func _has_available_item_instance(runtime: Dictionary, item_template_id: String) -> bool:
	for item_id in _inventory(runtime).get("item_instance_refs", []):
		var instance: Dictionary = runtime.get("item_instances", {}).get(str(item_id), {})
		if str(instance.get("item_template_id", "")) == item_template_id and not bool(instance.get("instance_state", {}).get("consumed", false)):
			return true
	return false

func _key_instances_consumed(runtime: Dictionary) -> bool:
	var consumed := 0
	for item_id in _inventory(runtime).get("item_instance_refs", []):
		var instance: Dictionary = runtime.get("item_instances", {}).get(str(item_id), {})
		if str(instance.get("item_template_id", "")) in ["trial_token_instance", "breakthrough_catalyst_instance"] and bool(instance.get("instance_state", {}).get("consumed", false)):
			consumed += 1
	return consumed == 2

func _last_breakthrough_result(runtime: Dictionary) -> String:
	var outcomes: Array = runtime.get("last_report", {}).get("breakthrough_outcomes", [])
	if outcomes.is_empty():
		return ""
	return str(outcomes[outcomes.size() - 1].get("result", ""))

func _last_fail_tags(runtime: Dictionary) -> Array:
	var outcomes: Array = runtime.get("last_report", {}).get("breakthrough_outcomes", [])
	if outcomes.is_empty():
		return []
	return outcomes[outcomes.size() - 1].get("fail_reason_tags", [])

func _logs_include(logs: Array, kind: String) -> bool:
	for entry in logs:
		if typeof(entry) == TYPE_DICTIONARY and str(entry.get("kind", "")) == kind:
			return true
	return false

func _finish(failures: Array) -> void:
	if failures.is_empty():
		print("Phase E self-test passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
