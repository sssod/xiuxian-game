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
var labels: Dictionary = {}


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

	for key in ["build", "config", "seed", "room", "time", "queue", "result", "replay"]:
		var label = Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		labels[key] = label
		layout.add_child(label)

	var button_row = HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 8)
	layout.add_child(button_row)

	var create_button = Button.new()
	create_button.text = "Create Local Smoke Room"
	create_button.pressed.connect(_on_create_room_pressed)
	button_row.add_child(create_button)

	var advance_button = Button.new()
	advance_button.text = "Advance One Hour"
	advance_button.pressed.connect(_on_advance_pressed)
	button_row.add_child(advance_button)


func _on_create_room_pressed() -> void:
	room = runtime.create_single_player_room()
	last_result = null
	_refresh()


func _on_advance_pressed() -> void:
	if room == null:
		room = runtime.create_single_player_room()
	last_result = runtime.advance_one_hour(room)
	_refresh()


func _refresh() -> void:
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
		labels["time"].text = "Time: unavailable"
		labels["queue"].text = "Queue: unavailable"
		labels["result"].text = "Result: unavailable"
		labels["replay"].text = "Replay: unavailable"
		return

	var ui_state = ui_adapter.from_room(room, last_result)
	labels["seed"].text = "Seed: %d" % ui_state.get("world_seed", 0)
	labels["room"].text = "Room: %s | %s | %s" % [
		ui_state.get("room_name", ""),
		ui_state.get("mode", ""),
		ui_state.get("save_lineage", ""),
	]
	labels["time"].text = "World time: %s | Speed: %s" % [
		ui_state.get("world_time_label", ""),
		ui_state.get("speed_state", ""),
	]
	labels["queue"].text = "Command queue empty: %s | Max queued future commands: %d" % [
		str(ui_state.get("queue_empty", true)),
		CommandQueueScript.MAX_FUTURE_COMMANDS,
	]
	labels["result"].text = "Last result: %s" % ui_state.get("result_summary", "")
	labels["replay"].text = "Replay entries: %d | Result packages: %d" % [
		ui_state.get("replay_entries", 0),
		ui_state.get("result_packages", 0),
	]
