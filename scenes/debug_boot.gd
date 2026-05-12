extends Control

const RuntimeConstantsScript = preload("res://src/runtime/runtime_constants.gd")
const XiuxianRuntimeScript = preload("res://src/runtime/xiuxian_runtime.gd")
const UiStateAdapterScript = preload("res://src/runtime/ui_state_adapter.gd")
const CommandQueueScript = preload("res://src/runtime/command_queue.gd")

var runtime = XiuxianRuntimeScript.new()
var ui_adapter = UiStateAdapterScript.new()
var room = null
var last_result = null
var config_status: Dictionary = {}
var save_status: Dictionary = {}
var load_status: Dictionary = {}
var save_slot_status: Dictionary = {}
var labels: Dictionary = {}
var buttons: Dictionary = {}


func _ready() -> void:
	_build_ui()
	config_status = runtime.load_config()
	room = runtime.create_single_player_room()
	_refresh()


func _build_ui() -> void:
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var layout = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)

	var title = Label.new()
	title.text = "Xiuxian Game Debug Boot"
	title.add_theme_font_size_override("font_size", 28)
	layout.add_child(title)

	for key in ["build", "config", "seed", "room", "character", "time", "queue", "slot", "save", "result", "replay"]:
		var label = Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		labels[key] = label
		layout.add_child(label)

	var button_row = HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 8)
	layout.add_child(button_row)

	var create_button = Button.new()
	create_button.text = "New Local Room"
	create_button.pressed.connect(_on_create_room_pressed)
	buttons["create"] = create_button
	button_row.add_child(create_button)

	var load_button = Button.new()
	load_button.text = "Continue Save"
	load_button.pressed.connect(_on_load_pressed)
	buttons["load"] = load_button
	button_row.add_child(load_button)

	var save_button = Button.new()
	save_button.text = "Save Room"
	save_button.pressed.connect(_on_save_pressed)
	buttons["save"] = save_button
	button_row.add_child(save_button)

	var advance_button = Button.new()
	advance_button.text = "Advance One Hour"
	advance_button.pressed.connect(_on_advance_pressed)
	buttons["advance"] = advance_button
	button_row.add_child(advance_button)

	var active_breathing_button = Button.new()
	active_breathing_button.text = "Queue Active Breathing"
	active_breathing_button.pressed.connect(_on_active_breathing_pressed)
	buttons["active_breathing"] = active_breathing_button
	button_row.add_child(active_breathing_button)

	var f1_button = Button.new()
	f1_button.text = "Advance F1 Smoke"
	f1_button.pressed.connect(_on_advance_f1_pressed)
	buttons["f1"] = f1_button
	button_row.add_child(f1_button)


func _on_create_room_pressed() -> void:
	room = runtime.create_single_player_room()
	last_result = null
	load_status = {}
	save_status = {}
	_refresh()


func _on_load_pressed() -> void:
	load_status = runtime.load_room()
	if bool(load_status.get("ok", false)):
		room = load_status.get("room")
		last_result = null
		save_status = {}
	_refresh()


func _on_save_pressed() -> void:
	if room == null:
		room = runtime.create_single_player_room()
	save_status = runtime.save_room(room)
	_refresh()


func _on_advance_pressed() -> void:
	if room == null:
		room = runtime.create_single_player_room()
	last_result = runtime.advance_one_hour(room)
	_refresh()


func _on_active_breathing_pressed() -> void:
	if room == null:
		room = runtime.create_single_player_room()
	save_status = runtime.enqueue_active_breathing(room, runtime.data_registry.get_smoke_post_load_f1_hours())
	_refresh()


func _on_advance_f1_pressed() -> void:
	if room == null:
		room = runtime.create_single_player_room()
	if room.command_queue.is_empty() or room.command_queue.is_current_fallback():
		save_status = runtime.enqueue_active_breathing(room, runtime.data_registry.get_smoke_post_load_f1_hours())
	var results = runtime.advance_hours(
		room,
		runtime.data_registry.get_smoke_post_load_f1_hours(),
		RuntimeConstantsScript.SPEED_F1
	)
	if not results.is_empty():
		last_result = results.back()
	_refresh()


func _refresh() -> void:
	save_slot_status = runtime.diagnose_save_slot()
	_refresh_button_state()

	labels["build"].text = "Build: %s | Target Godot: %s | Save schema: %d" % [
		RuntimeConstantsScript.APP_VERSION,
		RuntimeConstantsScript.GODOT_VERSION_TARGET,
		RuntimeConstantsScript.SAVE_SCHEMA_VERSION,
	]

	var config_text = "Config: not loaded"
	if bool(config_status.get("ok", false)):
		config_text = "Config: loaded %s (%s)" % [
			config_status.get("path", ""),
			config_status.get("build_label", ""),
		]
	elif config_status.has("error"):
		config_text = "Config: failed - %s" % config_status.get("error", "")
	labels["config"].text = config_text

	if room == null:
		labels["seed"].text = "Seed: unavailable"
		labels["room"].text = "Room: no active room"
		labels["character"].text = "Character: unavailable"
		labels["time"].text = "Time: unavailable"
		labels["queue"].text = "Queue: unavailable"
		labels["slot"].text = _format_save_slot_status()
		labels["save"].text = "Save/load: unavailable"
		labels["result"].text = "Result: unavailable"
		labels["replay"].text = "Replay: unavailable"
		return

	var ui_state = ui_adapter.from_room(room, last_result)
	labels["seed"].text = "Seed: %d" % ui_state.get("world_seed", 0)
	labels["room"].text = "Room: %s | %s | %s | State: %s" % [
		ui_state.get("room_name", ""),
		ui_state.get("mode", ""),
		ui_state.get("save_lineage", ""),
		ui_state.get("active_state", ""),
	]
	labels["character"].text = "Character: %s" % ui_state.get("character_summary", "")
	labels["time"].text = "World time: %s | Speed: %s" % [
		ui_state.get("world_time_label", ""),
		ui_state.get("speed_state", ""),
	]
	labels["queue"].text = "Command: %s | queued future: %d/%d | fallback=%s | empty=%s" % [
		ui_state.get("current_command_summary", "none"),
		ui_state.get("future_command_count", 0),
		CommandQueueScript.MAX_FUTURE_COMMANDS,
		str(ui_state.get("current_command_is_fallback", false)),
		str(ui_state.get("queue_empty", true)),
	]
	labels["slot"].text = _format_save_slot_status()

	var save_text = "Save/load: no action yet"
	if bool(save_status.get("ok", false)):
		if save_status.has("command"):
			save_text = "Command enqueue: ok %s (%s)" % [
				save_status.get("command", {}).get("command_id", ""),
				save_status.get("code", ""),
			]
		else:
			save_text = "Save: ok %s at Day %d Hour %02d | saved_at_unix=%d" % [
				save_status.get("path", ""),
				save_status.get("world_time", {}).get("world_day", 1),
				save_status.get("world_time", {}).get("world_hour", 0),
				save_status.get("saved_at_unix", 0),
			]
	elif save_status.has("error"):
		save_text = "Action failed (%s) - %s" % [
			save_status.get("code", "unknown"),
			save_status.get("error", ""),
		]

	if bool(load_status.get("ok", false)):
		var recovery = load_status.get("recovery", {})
		save_text += " | Load: ok code=%s recovery=%s strategy=%s" % [
			load_status.get("code", "loaded"),
			str(recovery.get("recovered", false)),
			recovery.get("strategy", "none"),
		]
	elif load_status.has("error"):
		save_text += " | Load: failed (%s) - %s" % [
			load_status.get("code", "unknown"),
			load_status.get("error", ""),
		]
	labels["save"].text = save_text

	labels["result"].text = "Last result: %s" % ui_state.get("result_summary", "")
	labels["replay"].text = "Replay entries: %d | Result packages: %d" % [
		ui_state.get("replay_entries", 0),
		ui_state.get("result_packages", 0),
	]


func _refresh_button_state() -> void:
	if buttons.has("load"):
		var load_button = buttons["load"]
		load_button.disabled = not bool(save_slot_status.get("can_continue", false))
		if load_button.disabled:
			load_button.tooltip_text = "No continueable save: %s" % save_slot_status.get("code", "unknown")
		else:
			load_button.tooltip_text = "Continue %s at Day %d Hour %02d" % [
				save_slot_status.get("room_name", ""),
				save_slot_status.get("world_time", {}).get("world_day", 1),
				save_slot_status.get("world_time", {}).get("world_hour", 0),
			]


func _format_save_slot_status() -> String:
	if bool(save_slot_status.get("can_continue", false)):
		return "Save slot: can continue %s | %s/%s | Day %d Hour %02d | recovery=%s strategy=%s | saved_at_unix=%d" % [
			save_slot_status.get("room_name", ""),
			save_slot_status.get("mode", ""),
			save_slot_status.get("save_lineage", ""),
			save_slot_status.get("world_time", {}).get("world_day", 1),
			save_slot_status.get("world_time", {}).get("world_hour", 0),
			str(save_slot_status.get("recovery_needed", false)),
			save_slot_status.get("recovery_strategy", "none"),
			save_slot_status.get("saved_at_unix", 0),
		]

	return "Save slot: cannot continue (%s) %s" % [
		save_slot_status.get("code", "unknown"),
		save_slot_status.get("error", ""),
	]
