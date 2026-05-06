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
	RoomFactory.ensure_phase_d_runtime_state(runtime, content)
	if not runtime.get("sect_states", {}).has("sect_yunlu"):
		failures.append("Expected sect_yunlu SectState at room creation.")
	if not runtime.get("resource_slot_states", {}).has("slot_spirit_grass"):
		failures.append("Expected slot_spirit_grass ResourceSlotState at room creation.")

	var route_outer := ContentLoader.route_between(content, "node_qinghe_village", "node_outer_mountain_road")
	var route_yunlu := ContentLoader.route_between(content, "node_outer_mountain_road", "node_yunlu_mountain_road")
	var route_gate := ContentLoader.route_between(content, "node_yunlu_mountain_road", "node_yunlu_gate")
	_settle_queue(runtime, content, [
		PersonalActionInstruction.make_move_to_node(DemoConstants.LOCAL_CHARACTER_ID, 1, route_outer),
		PersonalActionInstruction.make_move_to_node(DemoConstants.LOCAL_CHARACTER_ID, 2, route_yunlu),
		PersonalActionInstruction.make_move_to_node(DemoConstants.LOCAL_CHARACTER_ID, 3, route_gate)
	], failures, "travel_to_yunlu_gate")

	var active: Dictionary = _sect(runtime).get("active_continuous_action", {})
	if str(active.get("action_id", "")) != "sect_patrol_route":
		failures.append("Expected sect AI to select sect_patrol_route, got %s." % str(active.get("action_id", "")))
	if float(active.get("progress", 0.0)) != 0.0:
		failures.append("Expected newly selected sect AI action to start at 0 progress.")

	_settle_queue(runtime, content, [
		PersonalActionInstruction.make_join_sect_event(DemoConstants.LOCAL_CHARACTER_ID, 1, "node_yunlu_gate", 12)
	], failures, "sect_entry")
	active = _sect(runtime).get("active_continuous_action", {})
	if float(active.get("progress", 0.0)) <= 0.0:
		failures.append("Expected sect AI action to advance across turns.")
	var road_danger := int(runtime.get("node_states", {}).get("node_yunlu_mountain_road", {}).get("danger_profile", {}).get("danger_level", 0))
	if road_danger >= 3:
		failures.append("Expected sect patrol to lower yunlu mountain road danger, got %d." % road_danger)
	if runtime.get("sect_logs", []).is_empty():
		failures.append("Expected sect logs from AI selection/progress.")
	if runtime.get("rumor_pool", []).is_empty():
		failures.append("Expected sect AI progress to produce player-visible rumor.")

	var sect_qingling_before := _sect_stack_amount(runtime, "qingling_pill")
	_settle_queue(runtime, content, [
		PersonalActionInstruction.make_request_sect_resource(DemoConstants.LOCAL_CHARACTER_ID, 1, "sect_yunlu", "qingling_pill", 1, 4)
	], failures, "request_sect_resource")
	if _sect_stack_amount(runtime, "qingling_pill") != sect_qingling_before - 1:
		failures.append("Expected sect qingling_pill stack to decrement after request.")
	if _character_stack_amount(runtime, "qingling_pill") < 2:
		failures.append("Expected character inventory to include entry reward and requested qingling_pill.")
	if not _logs_include(runtime.get("asset_logs", []), "sect_resource_granted"):
		failures.append("Expected asset log for sect_resource_granted.")
	if not _last_packages_include_delta(runtime, "sect_states"):
		failures.append("Expected ResultPackage state_deltas to include sect_states.")

	var route_grass := ContentLoader.route_between(content, "node_outer_sect_room", "node_spirit_grass_slope")
	var abundance_before := int(runtime.get("resource_slot_states", {}).get("slot_spirit_grass", {}).get("abundance", 0))
	_settle_queue(runtime, content, [
		PersonalActionInstruction.make_move_to_node(DemoConstants.LOCAL_CHARACTER_ID, 1, route_grass),
		PersonalActionInstruction.make_gather_resource(DemoConstants.LOCAL_CHARACTER_ID, 2, "node_spirit_grass_slope", 24)
	], failures, "gather_spirit_grass")
	var abundance_after := int(runtime.get("resource_slot_states", {}).get("slot_spirit_grass", {}).get("abundance", 0))
	if abundance_after >= abundance_before:
		failures.append("Expected gather_resource to lower ResourceSlotState abundance.")
	if _character_stack_amount(runtime, "spirit_grass_stack") <= 0:
		failures.append("Expected gather_resource to add spirit_grass_stack to character inventory.")
	if not _logs_include(runtime.get("asset_logs", []), "resource_gathered"):
		failures.append("Expected asset log for resource_gathered.")

	_settle_queue(runtime, content, [
		PersonalActionInstruction.make_rest(DemoConstants.LOCAL_CHARACTER_ID, 1, 24)
	], failures, "advance_maintain_training_site")
	active = _sect(runtime).get("active_continuous_action", {})
	if str(active.get("status", "")) == "none":
		failures.append("Expected sect AI to keep one active or recently completed continuous action.")
	if _active_action_count(_sect(runtime)) > 1:
		failures.append("Expected at most one SectContinuousActionState.")

	var save_result := SaveManager.save_game(runtime, "phase_d_self_test")
	if not save_result["ok"]:
		failures.append("Save failed: %s" % save_result["error"])
	var load_result := SaveManager.load_game("phase_d_self_test")
	if not load_result["ok"]:
		failures.append("Load failed: %s" % load_result["error"])
	else:
		RoomFactory.ensure_phase_d_runtime_state(load_result["runtime"], content)
		if not load_result["runtime"].get("sect_states", {}).has("sect_yunlu"):
			failures.append("Loaded save did not preserve sect_yunlu.")
		if not load_result["runtime"].get("resource_slot_states", {}).has("slot_spirit_grass"):
			failures.append("Loaded save did not preserve ResourceSlotState.")

	if failures.is_empty():
		print("Phase D self-test passed.")
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

func _sect(runtime: Dictionary) -> Dictionary:
	return runtime.get("sect_states", {}).get("sect_yunlu", {})

func _inventory(runtime: Dictionary) -> Dictionary:
	var container_id := str(_character(runtime).get("inventory_container_ref", {}).get("container_id", ""))
	return runtime.get("asset_containers", {}).get(container_id, {})

func _character_stack_amount(runtime: Dictionary, item_template_id: String) -> int:
	var amount := 0
	for stack_id in _inventory(runtime).get("item_stack_refs", []):
		var stack: Dictionary = runtime.get("item_stacks", {}).get(str(stack_id), {})
		if str(stack.get("item_template_id", "")) == item_template_id:
			amount += int(stack.get("amount", 0))
	return amount

func _sect_stack_amount(runtime: Dictionary, item_template_id: String) -> int:
	var sect := _sect(runtime)
	var storage_id := str(sect.get("storage_container_ref", {}).get("container_id", ""))
	var storage: Dictionary = runtime.get("asset_containers", {}).get(storage_id, {})
	var amount := 0
	for stack_id in storage.get("item_stack_refs", []):
		var stack: Dictionary = runtime.get("item_stacks", {}).get(str(stack_id), {})
		if str(stack.get("item_template_id", "")) == item_template_id:
			amount += int(stack.get("amount", 0))
	return amount

func _logs_include(logs: Array, kind: String) -> bool:
	for entry in logs:
		if typeof(entry) == TYPE_DICTIONARY and str(entry.get("kind", "")) == kind:
			return true
	return false

func _last_packages_include_delta(runtime: Dictionary, state_delta_key: String) -> bool:
	for package in runtime.get("last_result_packages", []):
		if typeof(package) == TYPE_DICTIONARY and package.get("state_deltas", {}).has(state_delta_key):
			return true
	return false

func _active_action_count(sect: Dictionary) -> int:
	var active: Dictionary = sect.get("active_continuous_action", {})
	if active.is_empty() or str(active.get("status", "none")) == "none":
		return 0
	return 1
