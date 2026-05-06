extends RefCounted

const DemoConstants = preload("res://scripts/core/demo_constants.gd")
const LogUtils = preload("res://scripts/core/log_utils.gd")

static func create_local_room(content_summary := {}, content := {}) -> Dictionary:
	var turn_config := DemoConstants.default_turn_config()
	var time_state := DemoConstants.make_time_state(1, 1, 0)
	var character_inventory_id := "container_character_local_inventory"
	var sect_storage_id := "container_sect_yunlu_storage"
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
			DemoConstants.LOCAL_SPIRIT_ID: _default_true_spirit()
		},
		"incarnations": {
			DemoConstants.LOCAL_CHARACTER_ID: _default_character(character_inventory_id)
		},
		"asset_containers": {
			character_inventory_id: _default_character_inventory(character_inventory_id),
			sect_storage_id: _default_sect_storage(sect_storage_id, "sect_yunlu")
		},
		"item_stacks": _make_initial_sect_item_stacks(content),
		"item_instances": {},
		"method_states": {},
		"active_resource_effects": {},
		"sect_states": _make_sect_states(content),
		"resource_slot_states": _make_resource_slot_states(content),
		"pending_player_decisions": {
			DemoConstants.LOCAL_PLAYER_ID: []
		},
		"visible_logs": [],
		"debug_logs": [],
		"asset_logs": [],
		"character_logs": [],
		"sect_logs": [],
		"last_result_packages": [],
		"last_report": {},
		"last_replay": {},
		"map_graph": _make_map_graph(content),
		"node_states": _make_node_states(content),
		"world_logs": [],
		"rumor_pool": [],
		"newbie_quest_state": {
			"quest_id": "newbie_entry_chain",
			"step_id": "start_at_qinghe_village",
			"completed_steps": [],
			"flags": {}
		},
		"ledger_states": {
			"ledger_local_stub": {
				"ledger_id": "ledger_local_stub",
				"spirit_id": DemoConstants.LOCAL_SPIRIT_ID,
				"entries": [],
				"status": "placeholder"
			}
		},
		"content_summary": content_summary
	}

	runtime["visible_logs"].append(LogUtils.visible("room_created", "本地 demo 房间已创建。", 1, 1, 0))
	runtime["character_logs"].append(LogUtils.visible("character_created", "第一世角色出生于青禾村。", 1, 1, 0))
	runtime["debug_logs"].append(LogUtils.debug("room_initialized", "RoomState initialized for Phase D demo skeleton.", 1, 0, room_state.duplicate(true)))
	return runtime

static func set_phase(runtime: Dictionary, phase: String) -> void:
	if not DemoConstants.PHASES.has(phase):
		return
	runtime["room_state"]["current_phase"] = phase

static func ensure_phase_b_runtime_state(runtime: Dictionary, content: Dictionary) -> void:
	if not runtime.has("map_graph"):
		runtime["map_graph"] = _make_map_graph(content)
	if not runtime.has("node_states"):
		runtime["node_states"] = _make_node_states(content)
	if not runtime.has("world_logs"):
		runtime["world_logs"] = []
	if not runtime.has("rumor_pool"):
		runtime["rumor_pool"] = []

static func ensure_phase_c_runtime_state(runtime: Dictionary, content: Dictionary) -> void:
	ensure_phase_b_runtime_state(runtime, content)
	if not runtime.has("asset_containers"):
		runtime["asset_containers"] = {}
	if not runtime["asset_containers"].has("container_character_local_inventory"):
		runtime["asset_containers"]["container_character_local_inventory"] = _default_character_inventory("container_character_local_inventory")
	for key in ["item_stacks", "item_instances", "method_states", "active_resource_effects"]:
		if not runtime.has(key):
			runtime[key] = {}
	for key in ["asset_logs", "character_logs"]:
		if not runtime.has(key):
			runtime[key] = []
	if not runtime.has("newbie_quest_state"):
		runtime["newbie_quest_state"] = {
			"quest_id": "newbie_entry_chain",
			"step_id": "start_at_qinghe_village",
			"completed_steps": [],
			"flags": {}
		}
	if not runtime.has("ledger_states"):
		runtime["ledger_states"] = {}
	if not runtime["ledger_states"].has("ledger_local_stub"):
		runtime["ledger_states"]["ledger_local_stub"] = {
			"ledger_id": "ledger_local_stub",
			"spirit_id": DemoConstants.LOCAL_SPIRIT_ID,
			"entries": [],
			"status": "placeholder"
		}
	if runtime.get("true_spirits", {}).has(DemoConstants.LOCAL_SPIRIT_ID):
		_merge_missing(runtime["true_spirits"][DemoConstants.LOCAL_SPIRIT_ID], _default_true_spirit())
	if runtime.get("incarnations", {}).has(DemoConstants.LOCAL_CHARACTER_ID):
		_merge_missing(runtime["incarnations"][DemoConstants.LOCAL_CHARACTER_ID], _default_character("container_character_local_inventory"))

static func ensure_phase_d_runtime_state(runtime: Dictionary, content: Dictionary) -> void:
	ensure_phase_c_runtime_state(runtime, content)
	if not runtime.has("sect_states"):
		runtime["sect_states"] = _make_sect_states(content)
	else:
		for sect_id in _make_sect_states(content).keys():
			if not runtime["sect_states"].has(sect_id):
				runtime["sect_states"][sect_id] = _default_sect_state(content, sect_id)
			else:
				_merge_missing(runtime["sect_states"][sect_id], _default_sect_state(content, sect_id))
	if not runtime.has("resource_slot_states"):
		runtime["resource_slot_states"] = _make_resource_slot_states(content)
	else:
		for slot_id in _make_resource_slot_states(content).keys():
			if not runtime["resource_slot_states"].has(slot_id):
				runtime["resource_slot_states"][slot_id] = _make_resource_slot_states(content)[slot_id]
	if not runtime.has("sect_logs"):
		runtime["sect_logs"] = []
	if not runtime["asset_containers"].has("container_sect_yunlu_storage"):
		runtime["asset_containers"]["container_sect_yunlu_storage"] = _default_sect_storage("container_sect_yunlu_storage", "sect_yunlu")
	var initial_stacks := _make_initial_sect_item_stacks(content)
	for stack_id in initial_stacks.keys():
		if not runtime["item_stacks"].has(stack_id):
			runtime["item_stacks"][stack_id] = initial_stacks[stack_id]
		var storage: Dictionary = runtime["asset_containers"]["container_sect_yunlu_storage"]
		if not storage.get("item_stack_refs", []).has(stack_id):
			storage["item_stack_refs"].append(stack_id)
		runtime["asset_containers"]["container_sect_yunlu_storage"] = storage

static func _make_map_graph(content: Dictionary) -> Dictionary:
	var routes := {}
	for route_id in content.get("tables", {}).get("routes", {}).keys():
		var route: Dictionary = content["tables"]["routes"][route_id]
		routes[route_id] = {
			"route_id": route_id,
			"from_node": route.get("from_node", ""),
			"to_node": route.get("to_node", ""),
			"base_travel_hours": int(route.get("base_travel_hours", 0)),
			"risk_tags": route.get("risk_tags", []),
			"state_tags": route.get("state_tags", []),
			"hidden_state": route.get("hidden_state", "known")
		}
	return {
		"routes": routes,
		"route_states": {}
	}

static func _make_node_states(content: Dictionary) -> Dictionary:
	var node_states := {}
	for node_id in content.get("tables", {}).get("nodes", {}).keys():
		var node: Dictionary = content["tables"]["nodes"][node_id]
		node_states[node_id] = {
			"node_id": node_id,
			"display_name": node.get("display_name", node_id),
			"node_type": node.get("node_type", ""),
			"region_id": node.get("region_id", ""),
			"zone_tier": node.get("zone_tier", ""),
			"visibility_state": node.get("visibility_state", "hidden"),
			"danger_profile": node.get("danger_profile", {}),
			"aura_profile": node.get("aura_profile", {}),
			"control_owner": node.get("control_owner", "none"),
			"resource_slots": node.get("resource_slots", []),
			"route_connections": node.get("route_connections", []),
			"state_tags": node.get("state_tags", []),
			"world_log_refs": []
		}
	return node_states

static func _make_sect_states(content: Dictionary) -> Dictionary:
	var sect_states := {}
	for sect_id in content.get("tables", {}).get("sects", {}).keys():
		sect_states[sect_id] = _default_sect_state(content, str(sect_id))
	return sect_states

static func _default_sect_state(content: Dictionary, sect_id: String) -> Dictionary:
	var template: Dictionary = content.get("tables", {}).get("sects", {}).get(sect_id, {})
	var initial_stock: Dictionary = template.get("initial_stock", {})
	return {
		"sect_id": sect_id,
		"display_name": template.get("display_name", sect_id),
		"home_node_id": template.get("home_node_id", ""),
		"identity_ranks": template.get("identity_ranks", ["outer", "inner"]),
		"permissions_by_rank": template.get("permissions_by_rank", {}),
		"storage_container_ref": {
			"container_type": "SectStorage",
			"container_id": template.get("storage_container_id", "container_%s_storage" % sect_id)
		},
		"sect_resource_stock": {
			"sect_id": sect_id,
			"spirit_stone": int(initial_stock.get("spirit_stone", 0)),
			"cultivation_resource": int(initial_stock.get("cultivation_resource", 0)),
			"material_stock": int(initial_stock.get("material_stock", 0)),
			"manpower": int(initial_stock.get("manpower", 0)),
			"sect_reputation": int(initial_stock.get("sect_reputation", 0)),
			"reserved_resources": [],
			"income_sources": [],
			"expense_records": [],
			"stock_logs": []
		},
		"active_continuous_action": {
			"action_id": "",
			"sect_id": sect_id,
			"action_type": "none",
			"target_node_id": "",
			"status": "none",
			"started_turn_id": 0,
			"started_world_day": 0,
			"expected_duration_turns": 0,
			"expected_duration_hours": 0,
			"accumulated_hours": 0,
			"progress": 0.0,
			"resource_budget": {},
			"manpower_budget": 0,
			"ai_reason_tags": [],
			"interruption_rules": {},
			"related_event_refs": [],
			"visible_summary_key": "",
			"world_log_refs": []
		},
		"sect_logs": []
	}

static func _default_sect_storage(container_id: String, sect_id: String) -> Dictionary:
	return {
		"container_id": container_id,
		"container_type": "SectStorage",
		"owner_ref": sect_id,
		"location_ref": "sect:%s" % sect_id,
		"access_rules": {"sect_permission": "request_resources"},
		"visibility_state": "member_visible",
		"item_stack_refs": _initial_sect_stack_refs(sect_id),
		"item_instance_refs": [],
		"currency_refs": [],
		"log_refs": []
	}

static func _make_initial_sect_item_stacks(content: Dictionary) -> Dictionary:
	var stacks := {}
	for sect_id in content.get("tables", {}).get("sects", {}).keys():
		var template: Dictionary = content["tables"]["sects"][sect_id]
		for stack_entry in template.get("initial_item_stacks", []):
			if typeof(stack_entry) != TYPE_DICTIONARY:
				continue
			var item_template_id := str(stack_entry.get("item_template_id", ""))
			if item_template_id == "":
				continue
			var stack_id := "stack_%s_%s" % [sect_id, item_template_id]
			stacks[stack_id] = {
				"stack_id": stack_id,
				"item_template_id": item_template_id,
				"tier_code": "M0",
				"quality_code": "common",
				"amount": int(stack_entry.get("amount", 0)),
				"key_state_tags": ["sect_storage"],
				"bind_state": "unbound",
				"owner_container_ref": {
					"container_type": "SectStorage",
					"container_id": template.get("storage_container_id", "container_%s_storage" % str(sect_id))
				}
			}
	return stacks

static func _initial_sect_stack_refs(sect_id: String) -> Array:
	return [
		"stack_%s_qingling_pill" % sect_id,
		"stack_%s_stability_talisman" % sect_id,
		"stack_%s_spirit_stone_stack" % sect_id
	]

static func _make_resource_slot_states(content: Dictionary) -> Dictionary:
	var slot_states := {}
	for node_id in content.get("tables", {}).get("nodes", {}).keys():
		var node: Dictionary = content["tables"]["nodes"][node_id]
		for slot_id in node.get("resource_slots", []):
			var slot := str(slot_id)
			var item_template_id := "spirit_grass_stack"
			var abundance := 5
			var max_abundance := 8
			if slot == "slot_blackstone_ore":
				item_template_id = "blackstone_ore_stack"
				abundance = 4
				max_abundance = 10
			slot_states[slot] = {
				"slot_id": slot,
				"node_id": str(node_id),
				"resource_item_template_id": item_template_id,
				"discovery_state": node.get("visibility_state", "hidden"),
				"abundance": abundance,
				"max_abundance": max_abundance,
				"regeneration_per_turn": 1,
				"control_or_influence_tags": [node.get("control_owner", "none")],
				"state_tags": []
			}
	return slot_states

static func _default_true_spirit() -> Dictionary:
	return {
		"spirit_id": DemoConstants.LOCAL_SPIRIT_ID,
		"true_name": "未命名真灵",
		"spirit_strength": 1,
		"true_name_visibility": "hidden",
		"incarnation_count": 1,
		"highest_stage_reached": "A-1",
		"dao_rhyme_tags": [],
		"obsession_capacity": 1,
		"formal_contingency_slots": 0,
		"reincarnation_ledger_refs": ["ledger_local_stub"],
		"long_term_tags": []
	}

static func _default_character(inventory_container_id: String) -> Dictionary:
	return {
		"character_id": DemoConstants.LOCAL_CHARACTER_ID,
		"spirit_id": DemoConstants.LOCAL_SPIRIT_ID,
		"current_name": "青禾村少年",
		"age": 16,
		"lifespan": {
			"age_years": 16,
			"lifespan_limit": 80,
			"lifespan_pressure_state": "safe"
		},
		"body_template": "qinghe_mortal_body",
		"cultivation": {
			"current_stage_code": "A-1",
			"cultivation_progress": 0.0,
			"cultivation_purity": 1.0,
			"purity_visibility_state": "hidden",
			"bottleneck_state": "none",
			"main_dao_method_ref": "",
			"major_method_record_refs": {},
			"progress_cap_context": {
				"cap_source": "none",
				"theoretical_max_cap_stage": "",
				"current_effective_cap_stage": "A-1",
				"required_mastery_level": 0,
				"missing_condition_refs": ["basic_dao_method_required"],
				"suggested_actions": ["join_sect_event", "study_method"]
			}
		},
		"base_attributes": {
			"base_physique": 8,
			"base_vigor": 7
		},
		"derived_bars": {
			"bar_vitality_current": 100.0,
			"bar_vitality_max": 100.0,
			"bar_qi_current": 35.0,
			"bar_qi_max": 50.0,
			"bar_mind_current": 80.0,
			"bar_mind_max": 80.0
		},
		"aptitude_profile": {
			"aptitude_bone": 0,
			"aptitude_comprehension": 0,
			"aptitude_root": 0,
			"root_affinity_tags": [],
			"root_affinity_profile": {},
			"aptitude_rating_visibility": "hidden"
		},
		"talent_tags": ["mortal_origin"],
		"special_traits": [],
		"current_location": "node_qinghe_village",
		"current_route_state": {},
		"active_continuous_action_refs": [],
		"active_resource_effect_refs": [],
		"known_info_refs": ["node_qinghe_village"],
		"inventory_container_ref": {
			"container_type": "CharacterInventory",
			"container_id": inventory_container_id
		},
		"sect_identity": {
			"sect_id": "",
			"rank": "none",
			"positions": [],
			"permissions": [],
			"member_reputation": 0,
			"contribution_records": [],
			"special_authorizations": []
		},
		"social_relations": [],
		"injuries_and_conditions": [],
		"death_state": "alive",
		"character_log_refs": []
	}

static func _default_character_inventory(container_id: String) -> Dictionary:
	return {
		"container_id": container_id,
		"container_type": "CharacterInventory",
		"owner_ref": DemoConstants.LOCAL_CHARACTER_ID,
		"location_ref": "character:%s" % DemoConstants.LOCAL_CHARACTER_ID,
		"access_rules": {"owner_only": true},
		"visibility_state": "owner_visible",
		"item_stack_refs": [],
		"item_instance_refs": [],
		"currency_refs": [],
		"log_refs": []
	}

static func _merge_missing(target: Dictionary, defaults: Dictionary) -> void:
	for key in defaults.keys():
		if not target.has(key):
			target[key] = defaults[key]
		elif typeof(target[key]) == TYPE_DICTIONARY and typeof(defaults[key]) == TYPE_DICTIONARY:
			_merge_missing(target[key], defaults[key])
