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
var content_label: Label

func _ready() -> void:
	content = ContentLoader.load_content()
	runtime = RoomFactory.create_local_room(content.get("summary", {}))
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

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 8)
	root.add_child(columns)

	visible_log_text = _make_panel(columns, "玩家可见日志")
	queue_text = _make_panel(columns, "当前行动预案")
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
	runtime = RoomFactory.create_local_room(content.get("summary", {}))
	_refresh()

func _on_add_rest_pressed() -> void:
	var queue := _current_queue()
	queue.append(PersonalActionInstruction.make_rest(DemoConstants.LOCAL_CHARACTER_ID, queue.size() + 1, 24))
	runtime["pending_player_decisions"][DemoConstants.LOCAL_PLAYER_ID] = queue
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
		validation_label.text = "读取：%s" % result["path"]
	else:
		validation_label.text = "读取失败：%s" % result["error"]
	_refresh()

func _refresh() -> void:
	if runtime.is_empty():
		return
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
	queue_text.text = _format_queue()
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
		lines.append("%d. %s" % [index + 1, PersonalActionInstruction.display_name(action)])
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
		lines.append("- %s %sh status=%s reason=%s" % [
			str(item.get("action_id", "")),
			str(item.get("actual_consumed_hours", "")),
			str(item.get("status", "")),
			str(item.get("skip_or_interrupt_reason", ""))
		])
	lines.append("")
	lines.append("备注:")
	for note in report.get("notes", []):
		lines.append("- %s" % str(note))
	return "\n".join(lines)
