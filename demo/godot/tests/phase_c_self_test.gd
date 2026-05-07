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

	var route_outer := ContentLoader.route_between(content, "node_qinghe_village", "node_outer_mountain_road")
	var route_yunlu := ContentLoader.route_between(content, "node_outer_mountain_road", "node_yunlu_mountain_road")
	var route_gate := ContentLoader.route_between(content, "node_yunlu_mountain_road", "node_yunlu_gate")
	_settle_queue(runtime, content, [
		PersonalActionInstruction.make_move_to_node(DemoConstants.LOCAL_CHARACTER_ID, 1, route_outer),
		PersonalActionInstruction.make_move_to_node(DemoConstants.LOCAL_CHARACTER_ID, 2, route_yunlu),
		PersonalActionInstruction.make_move_to_node(DemoConstants.LOCAL_CHARACTER_ID, 3, route_gate)
	], failures, "travel_to_yunlu_gate")
	if _character(runtime).get("current_location", "") != "node_yunlu_gate":
		failures.append("Expected character at node_yunlu_gate before sect entry.")

	_settle_queue(runtime, content, [
		PersonalActionInstruction.make_join_sect_event(DemoConstants.LOCAL_CHARACTER_ID, 1, "node_yunlu_gate", 12)
	], failures, "sect_entry")
	var character := _character(runtime)
	if character.get("current_location", "") != "node_outer_sect_room":
		failures.append("Expected sect entry to move character to node_outer_sect_room.")
	if character.get("sect_identity", {}).get("rank", "") != "outer":
		failures.append("Expected outer sect identity after sect_entry_test.")
	if character.get("aptitude_profile", {}).get("aptitude_rating_visibility", "") != "revealed_by_sect_entry_test":
		failures.append("Expected aptitude profile to be revealed by sect entry.")
	if not _has_item_instance(runtime, "basic_dao_method_carrier"):
		failures.append("Expected basic_dao_method_carrier MethodCarrierItem after sect entry.")
	if not _has_item_stack(runtime, "qingling_pill", 1):
		failures.append("Expected one qingling_pill stack after sect entry.")
	if runtime.get("node_states", {}).get("node_outer_sect_room", {}).get("visibility_state", "") != "known":
		failures.append("Expected node_outer_sect_room to be revealed.")

	_settle_queue(runtime, content, [
		PersonalActionInstruction.make_study_method(DemoConstants.LOCAL_CHARACTER_ID, 1, "node_outer_sect_room", 24)
	], failures, "study_method")
	character = _character(runtime)
	var main_method_ref := str(character.get("cultivation", {}).get("main_dao_method_ref", ""))
	if main_method_ref == "" or not runtime.get("method_states", {}).has(main_method_ref):
		failures.append("Expected study_method to create MethodState and set main_dao_method_ref.")

	var route_grass := ContentLoader.route_between(content, "node_outer_sect_room", "node_spirit_grass_slope")
	_settle_queue(runtime, content, [
		PersonalActionInstruction.make_move_to_node(DemoConstants.LOCAL_CHARACTER_ID, 1, route_grass),
		PersonalActionInstruction.make_active_cultivation(DemoConstants.LOCAL_CHARACTER_ID, 2, "node_spirit_grass_slope", 114, true)
	], failures, "active_cultivation_with_qingling")
	character = _character(runtime)
	var cultivation: Dictionary = character.get("cultivation", {})
	if str(cultivation.get("current_stage_code", "")) != "A-2":
		failures.append("Expected active cultivation to raise demo stage to A-2, got %s." % str(cultivation.get("current_stage_code", "")))
	if _has_item_stack(runtime, "qingling_pill", 1):
		failures.append("Expected qingling_pill to be consumed only after active_cultivation started.")
	if runtime.get("active_resource_effects", {}).is_empty():
		failures.append("Expected residual ActiveResourceEffect from qingling_pill.")
	if character.get("active_resource_effect_refs", []).is_empty():
		failures.append("Expected character active_resource_effect_refs to preserve residual effect.")
	if not _actual_entries_include_partial(runtime.get("last_report", {}).get("actual_actions", []), "active_cultivation"):
		failures.append("Expected active_cultivation to be partial after inserted movement delay.")
	if not _asset_logs_include(runtime.get("asset_logs", []), "resource_consumed"):
		failures.append("Expected asset log for qingling_pill resource consumption.")

	_settle_queue(runtime, content, [
		PersonalActionInstruction.make_request_sect_resource(DemoConstants.LOCAL_CHARACTER_ID, 1, "sect_yunlu", "qingling_pill", 2, 4)
	], failures, "request_two_qingling")
	var effect_count_before: int = runtime.get("active_resource_effects", {}).size()
	_settle_queue(runtime, content, [
		PersonalActionInstruction.make_active_cultivation(DemoConstants.LOCAL_CHARACTER_ID, 1, "node_spirit_grass_slope", 24, true),
		PersonalActionInstruction.make_active_cultivation(DemoConstants.LOCAL_CHARACTER_ID, 2, "node_spirit_grass_slope", 24, true)
	], failures, "continuous_qingling_residuals")
	if runtime.get("active_resource_effects", {}).size() < effect_count_before + 2:
		failures.append("Expected consecutive qingling_pill use to create distinct ActiveResourceEffect entries.")
	if _active_qingling_effect_refs(runtime).size() < 2:
		failures.append("Expected previous and new qingling_pill residual effects to remain traceable instead of being overwritten.")

	var save_result := SaveManager.save_game(runtime, "phase_c_self_test")
	if not save_result["ok"]:
		failures.append("Save failed: %s" % save_result["error"])
	var load_result := SaveManager.load_game("phase_c_self_test")
	if not load_result["ok"]:
		failures.append("Load failed: %s" % load_result["error"])
	elif load_result["runtime"].get("active_resource_effects", {}).is_empty():
		failures.append("Loaded save did not preserve ActiveResourceEffect.")

	if failures.is_empty():
		print("Phase C self-test passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

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

func _has_item_stack(runtime: Dictionary, item_template_id: String, amount: int) -> bool:
	for stack_id in _inventory(runtime).get("item_stack_refs", []):
		var stack: Dictionary = runtime.get("item_stacks", {}).get(str(stack_id), {})
		if str(stack.get("item_template_id", "")) == item_template_id and int(stack.get("amount", 0)) >= amount:
			return true
	return false

func _has_item_instance(runtime: Dictionary, item_template_id: String) -> bool:
	for item_id in _inventory(runtime).get("item_instance_refs", []):
		var instance: Dictionary = runtime.get("item_instances", {}).get(str(item_id), {})
		if str(instance.get("item_template_id", "")) == item_template_id:
			return true
	return false

func _actual_entries_include_partial(entries: Array, action_id: String) -> bool:
	for entry in entries:
		if typeof(entry) == TYPE_DICTIONARY and str(entry.get("action_id", "")) == action_id and str(entry.get("status", "")) == "partial":
			return true
	return false

func _asset_logs_include(entries: Array, kind: String) -> bool:
	for entry in entries:
		if typeof(entry) == TYPE_DICTIONARY and str(entry.get("kind", "")) == kind:
			return true
	return false

func _active_qingling_effect_refs(runtime: Dictionary) -> Array:
	var refs := []
	for effect_id in _character(runtime).get("active_resource_effect_refs", []):
		var effect: Dictionary = runtime.get("active_resource_effects", {}).get(str(effect_id), {})
		if str(effect.get("source_resource_ref", "")) == "qingling_pill" and str(effect.get("state", "active")) != "exhausted" and float(effect.get("remaining_effect_hours", 0.0)) > 0.0:
			refs.append(str(effect_id))
	return refs
