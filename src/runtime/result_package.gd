extends RefCounted
class_name ResultPackage

var result_id = ""
var source_system = ""
var room_id = ""
var world_time: Dictionary = {}
var visible_logs: Array[String] = []
var debug_trace: Array[Dictionary] = []
var replay_entries: Array[Dictionary] = []
var deltas: Dictionary = {}


static func create(
		result_id_value: String,
		source_system_value: String,
		room_id_value: String,
		world_time_value: Dictionary,
		visible_logs_value: Array[String],
		debug_trace_value: Array[Dictionary],
		replay_entries_value: Array[Dictionary],
		deltas_value: Dictionary = {}
):
	var package = load("res://src/runtime/result_package.gd").new()
	package.result_id = result_id_value
	package.source_system = source_system_value
	package.room_id = room_id_value
	package.world_time = world_time_value.duplicate(true)
	package.visible_logs = visible_logs_value.duplicate()
	package.debug_trace = debug_trace_value.duplicate(true)
	package.replay_entries = replay_entries_value.duplicate(true)
	package.deltas = deltas_value.duplicate(true)
	return package


func to_dict() -> Dictionary:
	return {
		"result_id": result_id,
		"source_system": source_system,
		"room_id": room_id,
		"world_time": world_time.duplicate(true),
		"visible_logs": visible_logs.duplicate(),
		"debug_trace": debug_trace.duplicate(true),
		"replay_entries": replay_entries.duplicate(true),
		"deltas": deltas.duplicate(true),
	}
