extends Control

const DemoConstants = preload("res://scripts/core/demo_constants.gd")
const ContentLoader = preload("res://scripts/core/content_loader.gd")
const RoomFactory = preload("res://scripts/core/room_factory.gd")
const TurnPhaseMachine = preload("res://scripts/core/turn_phase_machine.gd")
const PersonalActionInstruction = preload("res://scripts/core/personal_action_instruction.gd")
const ActionValidator = preload("res://scripts/core/action_validator.gd")
const SettlementService = preload("res://scripts/core/settlement_service.gd")
const ResultPackageMerger = preload("res://scripts/core/result_package_merger.gd")
const SaveManager = preload("res://scripts/core/save_manager.gd")

var content := {}
var runtime := {}

var header_label: Label
var validation_label: Label
var queue_text: RichTextLabel
var report_text: RichTextLabel
var visible_log_text: RichTextLabel
var debug_log_text: RichTextLabel
var character_text: RichTextLabel
var sect_text: RichTextLabel
var content_label: Label
var budget_label: Label
var map_button_grid: GridContainer
var node_context_text: RichTextLabel
var add_move_button: Button
var add_rumor_button: Button
var join_sect_button: Button
var study_method_button: Button
var cultivation_button: Button
var cultivation_with_pill_button: Button
var request_qingling_button: Button
var gather_resource_button: Button
var selected_node_id := ""

func _ready() -> void:
	content = ContentLoader.load_content()
	runtime = RoomFactory.create_local_room(content.get("summary", {}), content)
	selected_node_id = _current_or_planned_location()
	_build_ui()
	_refresh()

func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.name = "DemoRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	add_child(root)

	var toolbar := HBoxContainer.new()
	root.add_child(toolbar)

	var new_button := Button.new()
	new_button.text = "新建本地房间"
	new_button.pressed.connect(_on_new_room_pressed)
	toolbar.add_child(new_button)

	var add_rest_button := Button.new()
	add_rest_button.text = "添加休整 1 天"
	add_rest_button.pressed.connect(_on_add_rest_pressed)
	toolbar.add_child(add_rest_button)

	add_move_button = Button.new()
	add_move_button.text = "前往所选节点"
	add_move_button.pressed.connect(_on_add_move_pressed)
	toolbar.add_child(add_move_button)

	add_rumor_button = Button.new()
	add_rumor_button.text = "打听当前位置"
	add_rumor_button.pressed.connect(_on_add_rumor_pressed)
	toolbar.add_child(add_rumor_button)

	join_sect_button = Button.new()
	join_sect_button.text = "入门云麓宗"
	join_sect_button.pressed.connect(_on_add_join_sect_pressed)
	toolbar.add_child(join_sect_button)

	study_method_button = Button.new()
	study_method_button.text = "研习功法"
	study_method_button.pressed.connect(_on_add_study_method_pressed)
	toolbar.add_child(study_method_button)

	cultivation_button = Button.new()
	cultivation_button.text = "吐纳 1 天"
	cultivation_button.pressed.connect(_on_add_cultivation_pressed.bind(false))
	toolbar.add_child(cultivation_button)

	cultivation_with_pill_button = Button.new()
	cultivation_with_pill_button.text = "吐纳 + 清灵丹"
	cultivation_with_pill_button.pressed.connect(_on_add_cultivation_pressed.bind(true))
	toolbar.add_child(cultivation_with_pill_button)

	request_qingling_button = Button.new()
	request_qingling_button.text = "申请清灵丹"
	request_qingling_button.pressed.connect(_on_add_request_qingling_pressed)
	toolbar.add_child(request_qingling_button)

	gather_resource_button = Button.new()
	gather_resource_button.text = "采集资源"
	gather_resource_button.pressed.connect(_on_add_gather_resource_pressed)
	toolbar.add_child(gather_resource_button)

	var clear_button := Button.new()
	clear_button.text = "清空预案"
	clear_button.pressed.connect(_on_clear_actions_pressed)
	toolbar.add_child(clear_button)

	var lock_button := Button.new()
	lock_button.text = "锁定并结算"
	lock_button.pressed.connect(_on_lock_and_settle_pressed)
	toolbar.add_child(lock_button)

	var save_button := Button.new()
	save_button.text = "保存"
	save_button.pressed.connect(_on_save_pressed)
	toolbar.add_child(save_button)

	var load_button := Button.new()
	load_button.text = "读取"
	load_button.pressed.connect(_on_load_pressed)
	toolbar.add_child(load_button)

	header_label = Label.new()
	header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toolbar.add_child(header_label)

	validation_label = Label.new()
	validation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(validation_label)

	content_label = Label.new()
	content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(content_label)

	budget_label = Label.new()
	budget_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(budget_label)

	var map_row := HBoxContainer.new()
	map_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_row.add_theme_constant_override("separation", 8)
	root.add_child(map_row)

	var map_panel := PanelContainer.new()
	map_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_row.add_child(map_panel)

	var map_box := VBoxContainer.new()
	map_box.add_theme_constant_override("separation", 6)
	map_panel.add_child(map_box)

	var map_title := Label.new()
	map_title.text = "大地图"
	map_box.add_child(map_title)

	map_button_grid = GridContainer.new()
	map_button_grid.columns = 5
	map_button_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_box.add_child(map_button_grid)

	node_context_text = _make_panel(map_row, "节点上下文")

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 8)
	root.add_child(columns)

	visible_log_text = _make_panel(columns, "玩家可见日志")
	queue_text = _make_panel(columns, "当前行动预案")
	character_text = _make_panel(columns, "角色 / 功法 / 背包")
	sect_text = _make_panel(columns, "宗门 / 资源 / AI")
	report_text = _make_panel(columns, "回合报告")
	debug_log_text = _make_panel(columns, "Debug")

func _make_panel(parent: Node, title: String) -> RichTextLabel:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	var label := Label.new()
	label.text = title
	box.add_child(label)

	var text := RichTextLabel.new()
	text.bbcode_enabled = false
	text.fit_content = false
	text.scroll_active = true
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(text)
	return text

func _on_new_room_pressed() -> void:
	runtime = RoomFactory.create_local_room(content.get("summary", {}), content)
	selected_node_id = _current_or_planned_location()
	_refresh()

func _on_add_rest_pressed() -> void:
	var queue := _current_queue()
	queue.append(PersonalActionInstruction.make_rest(DemoConstants.LOCAL_CHARACTER_ID, queue.size() + 1, 24))
	runtime["pending_player_decisions"][DemoConstants.LOCAL_PLAYER_ID] = queue
	TurnPhaseMachine.transition_to(runtime, "personal_action_planning")
	_refresh()

func _on_add_move_pressed() -> void:
	var queue := _current_queue()
	var from_node := _planned_location_after_queue(queue)
	if selected_node_id == "":
		validation_label.text = "未选择目标节点。"
		return
	if selected_node_id == from_node:
		validation_label.text = "角色已经位于%s。" % _node_display_name(selected_node_id)
		return
	var route := ContentLoader.route_between(content, from_node, selected_node_id)
	if route.is_empty():
		validation_label.text = "没有可用路线：%s → %s。" % [_node_display_name(from_node), _node_display_name(selected_node_id)]
		return
	queue.append(PersonalActionInstruction.make_move_to_node(DemoConstants.LOCAL_CHARACTER_ID, queue.size() + 1, route))
	runtime["pending_player_decisions"][DemoConstants.LOCAL_PLAYER_ID] = queue
	TurnPhaseMachine.transition_to(runtime, "personal_action_planning")
	_refresh()

func _on_add_rumor_pressed() -> void:
	var queue := _current_queue()
	var node_id := _planned_location_after_queue(queue)
	var template := ContentLoader.action_template(content, "ask_for_rumor")
	var duration := int(template.get("default_duration_hours", 8))
	queue.append(PersonalActionInstruction.make_node_action("ask_for_rumor", DemoConstants.LOCAL_CHARACTER_ID, queue.size() + 1, node_id, duration))
	runtime["pending_player_decisions"][DemoConstants.LOCAL_PLAYER_ID] = queue
	selected_node_id = node_id
	TurnPhaseMachine.transition_to(runtime, "personal_action_planning")
	_refresh()

func _on_add_join_sect_pressed() -> void:
	var queue := _current_queue()
	var template := ContentLoader.action_template(content, "join_sect_event")
	var duration := int(template.get("default_duration_hours", 12))
	queue.append(PersonalActionInstruction.make_join_sect_event(DemoConstants.LOCAL_CHARACTER_ID, queue.size() + 1, "node_yunlu_gate", duration))
	runtime["pending_player_decisions"][DemoConstants.LOCAL_PLAYER_ID] = queue
	selected_node_id = "node_yunlu_gate"
	TurnPhaseMachine.transition_to(runtime, "personal_action_planning")
	_refresh()

func _on_add_study_method_pressed() -> void:
	var queue := _current_queue()
	var node_id := _planned_location_after_queue(queue)
	var template := ContentLoader.action_template(content, "study_method")
	var duration := int(template.get("default_duration_hours", 24))
	queue.append(PersonalActionInstruction.make_study_method(DemoConstants.LOCAL_CHARACTER_ID, queue.size() + 1, node_id, duration))
	runtime["pending_player_decisions"][DemoConstants.LOCAL_PLAYER_ID] = queue
	selected_node_id = node_id
	TurnPhaseMachine.transition_to(runtime, "personal_action_planning")
	_refresh()

func _on_add_cultivation_pressed(use_qingling_pill: bool) -> void:
	var queue := _current_queue()
	var node_id := _planned_location_after_queue(queue)
	var template := ContentLoader.action_template(content, "active_cultivation")
	var duration := int(template.get("default_duration_hours", 24))
	queue.append(PersonalActionInstruction.make_active_cultivation(DemoConstants.LOCAL_CHARACTER_ID, queue.size() + 1, node_id, duration, use_qingling_pill))
	runtime["pending_player_decisions"][DemoConstants.LOCAL_PLAYER_ID] = queue
	selected_node_id = node_id
	TurnPhaseMachine.transition_to(runtime, "personal_action_planning")
	_refresh()

func _on_add_request_qingling_pressed() -> void:
	var queue := _current_queue()
	var template := ContentLoader.action_template(content, "request_sect_resource")
	var duration := int(template.get("default_duration_hours", 4))
	queue.append(PersonalActionInstruction.make_request_sect_resource(DemoConstants.LOCAL_CHARACTER_ID, queue.size() + 1, "sect_yunlu", "qingling_pill", 1, duration))
	runtime["pending_player_decisions"][DemoConstants.LOCAL_PLAYER_ID] = queue
	TurnPhaseMachine.transition_to(runtime, "personal_action_planning")
	_refresh()

func _on_add_gather_resource_pressed() -> void:
	var queue := _current_queue()
	var node_id := _planned_location_after_queue(queue)
	var template := ContentLoader.action_template(content, "gather_resource")
	var duration := int(template.get("default_duration_hours", 24))
	queue.append(PersonalActionInstruction.make_gather_resource(DemoConstants.LOCAL_CHARACTER_ID, queue.size() + 1, node_id, duration))
	runtime["pending_player_decisions"][DemoConstants.LOCAL_PLAYER_ID] = queue
	selected_node_id = node_id
	TurnPhaseMachine.transition_to(runtime, "personal_action_planning")
	_refresh()

func _on_clear_actions_pressed() -> void:
	runtime["pending_player_decisions"][DemoConstants.LOCAL_PLAYER_ID] = []
	_refresh()

func _on_lock_and_settle_pressed() -> void:
	var queue := _current_queue()
	var validation := ActionValidator.validate_queue(runtime, content, DemoConstants.LOCAL_PLAYER_ID, queue)
	if not validation["ok"]:
		validation_label.text = "硬校验失败：%s" % "; ".join(validation["errors"])
		return

	runtime["players"][DemoConstants.LOCAL_PLAYER_ID]["lock_state"] = "locked"
	TurnPhaseMachine.transition_to(runtime, "waiting_lock")
	TurnPhaseMachine.transition_to(runtime, "settlement")
	var settlement_result := SettlementService.settle_turn(runtime, content, DemoConstants.LOCAL_PLAYER_ID)
	ResultPackageMerger.merge(runtime, settlement_result["packages"])
	if settlement_result["ok"]:
		runtime["last_replay"] = settlement_result["turn_replay"]
		var replay_result := SaveManager.write_replay(settlement_result["turn_replay"])
		var save_result := SaveManager.save_game(runtime)
		runtime["debug_logs"].append({
			"kind": "persistence",
			"message": "Saved runtime and replay.",
			"turn_id": runtime["room_state"]["current_turn_id"],
			"world_hour": runtime["room_state"]["current_world_hour"],
			"payload": {"save": save_result, "replay": replay_result}
		})
	_refresh()

func _on_save_pressed() -> void:
	var result := SaveManager.save_game(runtime)
	validation_label.text = "保存：%s" % result.get("path", result.get("error", "unknown"))
	_refresh()

func _on_load_pressed() -> void:
	var result := SaveManager.load_game()
	if result["ok"]:
		runtime = result["runtime"]
		RoomFactory.ensure_phase_d_runtime_state(runtime, content)
		selected_node_id = _current_or_planned_location()
		validation_label.text = "读取：%s" % result["path"]
	else:
		validation_label.text = "读取失败：%s" % result["error"]
	_refresh()

func _refresh() -> void:
	if runtime.is_empty():
		return
	RoomFactory.ensure_phase_d_runtime_state(runtime, content)
	if selected_node_id == "":
		selected_node_id = _current_or_planned_location()
	var room: Dictionary = runtime["room_state"]
	var turn_config: Dictionary = room.get("turn_config", DemoConstants.default_turn_config())
	header_label.text = "phase=%s | turn_id=%s | world_day=%s | world_hour=%s | hour_tick=%s | state_version=%s" % [
		room.get("current_phase", ""),
		str(room.get("current_turn_id", "")),
		str(room.get("current_world_day", "")),
		str(room.get("current_world_hour", "")),
		str(room.get("current_hour_tick", "")),
		str(room.get("world_state_version", ""))
	]

	var validation := ActionValidator.validate_queue(runtime, content, DemoConstants.LOCAL_PLAYER_ID, _current_queue())
	if validation["ok"]:
		validation_label.text = "预算：%dh / %dh；倒计时：关闭" % [validation["planned_hours"], validation["budget_hours"]]
	else:
		validation_label.text = "硬校验失败：%s" % "; ".join(validation["errors"])

	content_label.text = "内容表：%s | 每回合 %d 天 / %d 小时" % [str(content.get("summary", {})), int(turn_config.get("turn_duration_days", 5)), DemoConstants.turn_total_hours(turn_config)]
	budget_label.text = _format_budget(validation)
	_render_map()
	node_context_text.text = _format_node_context()
	add_move_button.disabled = selected_node_id == "" or selected_node_id == _planned_location_after_queue(_current_queue()) or ContentLoader.route_between(content, _planned_location_after_queue(_current_queue()), selected_node_id).is_empty()
	join_sect_button.disabled = _planned_location_after_queue(_current_queue()) != "node_yunlu_gate" or _character_rank() != "none"
	study_method_button.disabled = not _has_item_instance("basic_dao_method_carrier")
	cultivation_button.disabled = not _has_main_method()
	cultivation_with_pill_button.disabled = not _has_main_method() or not _has_item_stack("qingling_pill")
	request_qingling_button.disabled = not _has_sect_permission("request_resources") or not _sect_storage_has_stack("sect_yunlu", "qingling_pill")
	gather_resource_button.disabled = not _planned_node_has_resource_slot(_planned_location_after_queue(_current_queue()))
	queue_text.text = _format_queue()
	character_text.text = _format_character_panel()
	sect_text.text = _format_sect_panel()
	visible_log_text.text = _format_logs(runtime.get("visible_logs", []))
	debug_log_text.text = _format_logs(runtime.get("debug_logs", []))
	report_text.text = _format_report(runtime.get("last_report", {}))

func _current_queue() -> Array:
	return runtime.get("pending_player_decisions", {}).get(DemoConstants.LOCAL_PLAYER_ID, [])

func _format_queue() -> String:
	var lines := []
	var queue := _current_queue()
	if queue.is_empty():
		return "无行动预案。锁定后将按空行动路径休整整回合。"
	for index in queue.size():
		var action: Dictionary = queue[index]
		lines.append("%d. %s" % [index + 1, _format_action_line(action)])
	return "\n".join(lines)

func _format_budget(validation: Dictionary) -> String:
	var room: Dictionary = runtime["room_state"]
	var turn_config: Dictionary = room.get("turn_config", DemoConstants.default_turn_config())
	var day_labels := []
	for day_index in int(turn_config.get("turn_duration_days", DemoConstants.DEFAULT_TURN_DURATION_DAYS)):
		day_labels.append("第%d天" % (day_index + 1))
	var queue_bits := []
	for action in _current_queue():
		queue_bits.append("%s %dh" % [str(action.get("action_id", "")), int(action.get("planned_duration_hours", 0))])
	return "预算条：%s | 已排 %dh / %dh | %s" % [
		" ｜ ".join(day_labels),
		int(validation.get("planned_hours", 0)),
		int(validation.get("budget_hours", 0)),
		"；".join(queue_bits)
	]

func _render_map() -> void:
	for child in map_button_grid.get_children():
		child.queue_free()
	var node_ids: Array = content.get("tables", {}).get("nodes", {}).keys()
	node_ids.sort()
	for node_id in node_ids:
		var state := _node_state(str(node_id))
		var visibility := str(state.get("visibility_state", "hidden"))
		var button := Button.new()
		button.text = "%s\n%s" % [state.get("display_name", node_id), visibility]
		button.toggle_mode = true
		button.button_pressed = str(node_id) == selected_node_id
		button.disabled = visibility == "hidden"
		button.custom_minimum_size = Vector2(150, 54)
		button.pressed.connect(_on_node_pressed.bind(str(node_id)))
		map_button_grid.add_child(button)

func _on_node_pressed(node_id: String) -> void:
	selected_node_id = node_id
	_refresh()

func _format_node_context() -> String:
	if selected_node_id == "":
		return "未选择节点。"
	var state := _node_state(selected_node_id)
	var lines := [
		"%s [%s]" % [state.get("display_name", selected_node_id), state.get("visibility_state", "hidden")],
		"type=%s | region=%s | zone=%s" % [state.get("node_type", ""), state.get("region_id", ""), state.get("zone_tier", "")],
		"危险：%s" % str(state.get("danger_profile", {})),
		"灵气：%s" % str(state.get("aura_profile", {})),
		"控制：%s" % str(state.get("control_owner", "none")),
		"资源：%s" % str(state.get("resource_slots", [])),
		"",
		"路线："
	]
	var routes := ContentLoader.routes_from_node(content, selected_node_id)
	if routes.is_empty():
		lines.append("- 无可用路线")
	for route in routes:
		var to_node := str(route.get("to_node", ""))
		var to_visibility := str(_node_state(to_node).get("visibility_state", "hidden"))
		lines.append("- %s %dh risk=%s visibility=%s" % [
			_node_display_name(to_node),
			int(route.get("base_travel_hours", 0)),
			str(route.get("risk_tags", [])),
			to_visibility
		])
	lines.append("")
	lines.append("资源槽：")
	var slot_lines := _resource_slot_lines_for_node(selected_node_id)
	if slot_lines.is_empty():
		lines.append("- 无")
	else:
		lines.append_array(slot_lines)
	lines.append("")
	lines.append("计划位置：%s" % _node_display_name(_planned_location_after_queue(_current_queue())))
	return "\n".join(lines)

func _format_character_panel() -> String:
	var character: Dictionary = runtime.get("incarnations", {}).get(DemoConstants.LOCAL_CHARACTER_ID, {})
	var cultivation: Dictionary = character.get("cultivation", {})
	var aptitude: Dictionary = character.get("aptitude_profile", {})
	var bars: Dictionary = character.get("derived_bars", {})
	var lines := [
		"%s | 位置：%s" % [character.get("current_name", ""), _node_display_name(str(character.get("current_location", "")))],
		"身份：%s / %s" % [str(character.get("sect_identity", {}).get("sect_id", "none")), str(character.get("sect_identity", {}).get("rank", "none"))],
		"境界：%s | 修为 %.1f | 瓶颈：%s" % [str(cultivation.get("current_stage_code", "")), float(cultivation.get("cultivation_progress", 0.0)), str(cultivation.get("bottleneck_state", ""))],
		"主修：%s" % str(cultivation.get("main_dao_method_ref", "")),
		"体魄 %s / 精力 %s | 生机 %.0f/%.0f 元气 %.0f/%.0f 神念 %.0f/%.0f" % [
			str(character.get("base_attributes", {}).get("base_physique", "")),
			str(character.get("base_attributes", {}).get("base_vigor", "")),
			float(bars.get("bar_vitality_current", 0.0)),
			float(bars.get("bar_vitality_max", 0.0)),
			float(bars.get("bar_qi_current", 0.0)),
			float(bars.get("bar_qi_max", 0.0)),
			float(bars.get("bar_mind_current", 0.0)),
			float(bars.get("bar_mind_max", 0.0))
		],
		"资质：根骨 %s / 悟性 %s / 灵根 %s | %s" % [
			str(aptitude.get("aptitude_bone", "?")),
			str(aptitude.get("aptitude_comprehension", "?")),
			str(aptitude.get("aptitude_root", "?")),
			str(aptitude.get("aptitude_rating_visibility", "hidden"))
		],
		"",
		"MethodState:"
	]
	if runtime.get("method_states", {}).is_empty():
		lines.append("- 无")
	for method_state in runtime.get("method_states", {}).values():
		lines.append("- %s mastery=%s cap=%s exp=%.1f" % [
			str(method_state.get("template_id", "")),
			str(method_state.get("mastery_level", "")),
			str(method_state.get("current_effective_cap_stage", "")),
			float(method_state.get("mastery_exp", 0.0))
		])
	lines.append("")
	lines.append("背包:")
	var inventory := _inventory_container()
	for stack_id in inventory.get("item_stack_refs", []):
		var stack: Dictionary = runtime.get("item_stacks", {}).get(str(stack_id), {})
		lines.append("- %s x%s" % [str(stack.get("item_template_id", stack_id)), str(stack.get("amount", ""))])
	for item_id in inventory.get("item_instance_refs", []):
		var instance: Dictionary = runtime.get("item_instances", {}).get(str(item_id), {})
		lines.append("- %s" % str(instance.get("item_template_id", item_id)))
	if inventory.get("item_stack_refs", []).is_empty() and inventory.get("item_instance_refs", []).is_empty():
		lines.append("- 空")
	lines.append("")
	lines.append("ActiveResourceEffect:")
	for effect_id in character.get("active_resource_effect_refs", []):
		var effect: Dictionary = runtime.get("active_resource_effects", {}).get(str(effect_id), {})
		lines.append("- %s remaining=%.1fh channel=%s" % [
			str(effect.get("source_resource_ref", effect_id)),
			float(effect.get("remaining_effect_hours", 0.0)),
			str(effect.get("effect_channel", ""))
		])
	if character.get("active_resource_effect_refs", []).is_empty():
		lines.append("- 无")
	return "\n".join(lines)

func _format_sect_panel() -> String:
	var sect: Dictionary = runtime.get("sect_states", {}).get("sect_yunlu", {})
	if sect.is_empty():
		return "无宗门状态。"
	var stock: Dictionary = sect.get("sect_resource_stock", {})
	var active: Dictionary = sect.get("active_continuous_action", {})
	var lines := [
		"%s | home=%s" % [sect.get("display_name", "sect_yunlu"), _node_display_name(str(sect.get("home_node_id", "")))],
		"权限：%s" % str(runtime.get("incarnations", {}).get(DemoConstants.LOCAL_CHARACTER_ID, {}).get("sect_identity", {}).get("permissions", [])),
		"库存：灵石 %s / 修炼资源 %s / 材料 %s / 人力 %s / 声望 %s" % [
			str(stock.get("spirit_stone", 0)),
			str(stock.get("cultivation_resource", 0)),
			str(stock.get("material_stock", 0)),
			str(stock.get("manpower", 0)),
			str(stock.get("sect_reputation", 0))
		],
		"宗门仓库:"
	]
	var storage_id := str(sect.get("storage_container_ref", {}).get("container_id", ""))
	var storage: Dictionary = runtime.get("asset_containers", {}).get(storage_id, {})
	for stack_id in storage.get("item_stack_refs", []):
		var stack: Dictionary = runtime.get("item_stacks", {}).get(str(stack_id), {})
		lines.append("- %s x%s" % [str(stack.get("item_template_id", stack_id)), str(stack.get("amount", ""))])
	lines.append("")
	lines.append("唯一持续行动：%s status=%s progress=%.0f%% target=%s" % [
		str(active.get("visible_summary_key", active.get("action_id", "none"))),
		str(active.get("status", "none")),
		float(active.get("progress", 0.0)) * 100.0,
		_node_display_name(str(active.get("target_node_id", "")))
	])
	lines.append("")
	lines.append("宗门日志:")
	for entry in runtime.get("sect_logs", []):
		if typeof(entry) == TYPE_DICTIONARY:
			lines.append("[t%s h%s] %s" % [str(entry.get("turn_id", "")), str(entry.get("world_hour", "")), str(entry.get("message", ""))])
	if runtime.get("sect_logs", []).is_empty():
		lines.append("- 无")
	return "\n".join(lines)

func _format_logs(logs: Array) -> String:
	var lines := []
	for entry in logs:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		lines.append("[t%s h%s] %s: %s" % [
			str(entry.get("turn_id", "")),
			str(entry.get("world_hour", "")),
			str(entry.get("kind", "")),
			str(entry.get("message", ""))
		])
	return "\n".join(lines)

func _format_report(report: Dictionary) -> String:
	if report.is_empty():
		return "暂无回合报告。"
	var lines := [
		"turn_id: %s" % str(report.get("turn_id", "")),
		"总预算: %sh / 实耗: %sh" % [str(report.get("turn_total_hours", "")), str(report.get("consumed_hours", ""))],
		"",
		"原计划:"
	]
	for item in report.get("planned_actions", []):
		lines.append("- %s %sh" % [str(item.get("action_id", "")), str(item.get("planned_duration_hours", ""))])
	if report.get("planned_actions", []).is_empty():
		lines.append("- 空行动")
	lines.append("")
	lines.append("实际执行:")
	for item in report.get("actual_actions", []):
		var extra := ""
		if item.has("cultivation_progress_delta"):
			extra = " gain=%.1f stage=%s" % [float(item.get("cultivation_progress_delta", 0.0)), str(item.get("stage_after", ""))]
		if item.has("resource_bonus") and int(item.get("resource_bonus", {}).get("residual_effect_hours", 0)) > 0:
			extra += " residual=%sh" % str(item.get("resource_bonus", {}).get("residual_effect_hours", 0))
		if item.has("method_state_id"):
			extra += " method=%s" % str(item.get("method_state_id", ""))
		lines.append("- %s %sh status=%s reason=%s%s" % [
			str(item.get("action_id", "")),
			str(item.get("actual_consumed_hours", "")),
			str(item.get("status", "")),
			str(item.get("skip_or_interrupt_reason", "")),
			extra
		])
	if not report.get("interruptions", []).is_empty():
		lines.append("")
		lines.append("计划偏移:")
		for item in report.get("interruptions", []):
			lines.append("- %s 消耗 %sh effect=%s" % [
				str(item.get("event_id", "")),
				str(item.get("consumed_hours", "")),
				str(item.get("effect", ""))
			])
	lines.append("")
	lines.append("备注:")
	for note in report.get("notes", []):
		lines.append("- %s" % str(note))
	return "\n".join(lines)

func _format_action_line(action: Dictionary) -> String:
	var target = action.get("target", {})
	var target_id := ""
	if typeof(target) == TYPE_DICTIONARY:
		target_id = str(target.get("target_id", ""))
	if target_id != "" and content.get("tables", {}).get("nodes", {}).has(target_id):
		return "%s -> %s (%dh)" % [action.get("action_id", ""), _node_display_name(target_id), int(action.get("planned_duration_hours", 0))]
	return PersonalActionInstruction.display_name(action)

func _planned_location_after_queue(queue: Array) -> String:
	var location := _current_or_planned_location(false)
	for action in queue:
		if typeof(action) != TYPE_DICTIONARY:
			continue
		if str(action.get("action_id", "")) == "move_to_node":
			var target = action.get("target", {})
			if typeof(target) == TYPE_DICTIONARY:
				location = str(target.get("target_id", location))
	return location

func _current_or_planned_location(include_queue := true) -> String:
	var location := str(runtime.get("incarnations", {}).get(DemoConstants.LOCAL_CHARACTER_ID, {}).get("current_location", "node_qinghe_village"))
	if not include_queue:
		return location
	for action in _current_queue():
		if typeof(action) != TYPE_DICTIONARY:
			continue
		if str(action.get("action_id", "")) == "move_to_node":
			var target = action.get("target", {})
			if typeof(target) == TYPE_DICTIONARY:
				location = str(target.get("target_id", location))
	return location

func _node_state(node_id: String) -> Dictionary:
	if runtime.get("node_states", {}).has(node_id):
		return runtime["node_states"][node_id]
	return ContentLoader.node_template(content, node_id)

func _node_display_name(node_id: String) -> String:
	var state := _node_state(node_id)
	return str(state.get("display_name", state.get("display_name_key", node_id)))

func _character_rank() -> String:
	return str(runtime.get("incarnations", {}).get(DemoConstants.LOCAL_CHARACTER_ID, {}).get("sect_identity", {}).get("rank", "none"))

func _has_main_method() -> bool:
	var main_method_ref := str(runtime.get("incarnations", {}).get(DemoConstants.LOCAL_CHARACTER_ID, {}).get("cultivation", {}).get("main_dao_method_ref", ""))
	return main_method_ref != "" and runtime.get("method_states", {}).has(main_method_ref)

func _inventory_container() -> Dictionary:
	var container_id := str(runtime.get("incarnations", {}).get(DemoConstants.LOCAL_CHARACTER_ID, {}).get("inventory_container_ref", {}).get("container_id", ""))
	return runtime.get("asset_containers", {}).get(container_id, {})

func _has_item_stack(item_template_id: String) -> bool:
	var inventory := _inventory_container()
	for stack_id in inventory.get("item_stack_refs", []):
		var stack: Dictionary = runtime.get("item_stacks", {}).get(str(stack_id), {})
		if str(stack.get("item_template_id", "")) == item_template_id and int(stack.get("amount", 0)) > 0:
			return true
	return false

func _has_item_instance(item_template_id: String) -> bool:
	var inventory := _inventory_container()
	for item_id in inventory.get("item_instance_refs", []):
		var instance: Dictionary = runtime.get("item_instances", {}).get(str(item_id), {})
		if str(instance.get("item_template_id", "")) == item_template_id:
			return true
	return false

func _has_sect_permission(permission: String) -> bool:
	return runtime.get("incarnations", {}).get(DemoConstants.LOCAL_CHARACTER_ID, {}).get("sect_identity", {}).get("permissions", []).has(permission)

func _sect_storage_has_stack(sect_id: String, item_template_id: String) -> bool:
	var sect: Dictionary = runtime.get("sect_states", {}).get(sect_id, {})
	var storage_id := str(sect.get("storage_container_ref", {}).get("container_id", ""))
	var storage: Dictionary = runtime.get("asset_containers", {}).get(storage_id, {})
	for stack_id in storage.get("item_stack_refs", []):
		var stack: Dictionary = runtime.get("item_stacks", {}).get(str(stack_id), {})
		if str(stack.get("item_template_id", "")) == item_template_id and int(stack.get("amount", 0)) > 0:
			return true
	return false

func _planned_node_has_resource_slot(node_id: String) -> bool:
	for slot_state in runtime.get("resource_slot_states", {}).values():
		if str(slot_state.get("node_id", "")) == node_id and int(slot_state.get("abundance", 0)) > 0:
			return true
	return false

func _resource_slot_lines_for_node(node_id: String) -> Array:
	var lines := []
	for slot_state in runtime.get("resource_slot_states", {}).values():
		if str(slot_state.get("node_id", "")) != node_id:
			continue
		lines.append("- %s item=%s abundance=%s/%s state=%s" % [
			str(slot_state.get("slot_id", "")),
			str(slot_state.get("resource_item_template_id", "")),
			str(slot_state.get("abundance", 0)),
			str(slot_state.get("max_abundance", 0)),
			str(slot_state.get("state_tags", []))
		])
	return lines
