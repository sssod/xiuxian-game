extends RefCounted
class_name RoomState

const RuntimeConstantsScript = preload("res://src/runtime/runtime_constants.gd")
const WorldTimeScript = preload("res://src/runtime/world_time.gd")
const CommandQueueScript = preload("res://src/runtime/command_queue.gd")
const CharacterStateScript = preload("res://src/runtime/character_state.gd")
const ReplayLogScript = preload("res://src/runtime/replay_log.gd")

var room_id = ""
var room_name = ""
var mode = RuntimeConstantsScript.ROOM_MODE_SINGLE_LOCAL
var world_seed = RuntimeConstantsScript.DEFAULT_WORLD_SEED
var save_lineage = RuntimeConstantsScript.SAVE_LINEAGE_SINGLE
var save_version = RuntimeConstantsScript.SAVE_SCHEMA_VERSION
var active_state = RuntimeConstantsScript.ROOM_ACTIVE_STATE
var speed_state = RuntimeConstantsScript.SPEED_N1
var world_time = WorldTimeScript.new()
var command_queue = CommandQueueScript.new()
var character_state = CharacterStateScript.new()
var replay_log = ReplayLogScript.new()
var result_history: Array[Dictionary] = []
var rng_cursor = 0
var next_result_sequence = 1
var last_recovery_status: Dictionary = {}


static func create_single_local(room_name_value: String, seed_value: int):
	var room = load("res://src/runtime/room_state.gd").new()
	room.room_id = "single_local_%s" % str(seed_value)
	room.room_name = room_name_value
	room.world_seed = seed_value
	room.save_lineage = RuntimeConstantsScript.SAVE_LINEAGE_SINGLE
	room.mode = RuntimeConstantsScript.ROOM_MODE_SINGLE_LOCAL
	room.active_state = RuntimeConstantsScript.ROOM_ACTIVE_STATE
	room.speed_state = RuntimeConstantsScript.SPEED_N1
	room.replay_log.append_event(
		"room_created",
		room.world_time.to_dict(),
		{
			"mode": room.mode,
			"save_lineage": room.save_lineage,
			"world_seed": room.world_seed,
		}
	)
	return room


func next_result_id() -> String:
	var result_id = "rp_%04d" % next_result_sequence
	next_result_sequence += 1
	return result_id


func to_dict() -> Dictionary:
	return {
		"room_id": room_id,
		"room_name": room_name,
		"mode": mode,
		"world_seed": world_seed,
		"save_lineage": save_lineage,
		"save_version": save_version,
		"active_state": active_state,
		"speed_state": speed_state,
		"world_time": world_time.to_dict(),
		"command_queue": command_queue.to_dict(),
		"character_state": character_state.to_dict(),
		"replay_log": replay_log.to_array(),
		"result_history": result_history.duplicate(true),
		"rng_cursor": rng_cursor,
		"next_result_sequence": next_result_sequence,
		"last_recovery_status": last_recovery_status.duplicate(true),
	}


static func from_dict(data: Dictionary):
	var room = load("res://src/runtime/room_state.gd").new()
	room.room_id = str(data.get("room_id", ""))
	room.room_name = str(data.get("room_name", ""))
	room.mode = str(data.get("mode", RuntimeConstantsScript.ROOM_MODE_SINGLE_LOCAL))
	room.world_seed = int(data.get("world_seed", RuntimeConstantsScript.DEFAULT_WORLD_SEED))
	room.save_lineage = str(data.get("save_lineage", RuntimeConstantsScript.SAVE_LINEAGE_SINGLE))
	room.save_version = int(data.get("save_version", RuntimeConstantsScript.SAVE_SCHEMA_VERSION))
	room.active_state = str(data.get("active_state", RuntimeConstantsScript.ROOM_ACTIVE_STATE))
	room.speed_state = str(data.get("speed_state", RuntimeConstantsScript.SPEED_N1))
	room.rng_cursor = int(data.get("rng_cursor", 0))
	room.next_result_sequence = int(data.get("next_result_sequence", 1))

	var time_data = data.get("world_time", {})
	if typeof(time_data) == TYPE_DICTIONARY:
		room.world_time = WorldTimeScript.from_dict(time_data)

	var queue_data = data.get("command_queue", {})
	if typeof(queue_data) == TYPE_DICTIONARY:
		room.command_queue = CommandQueueScript.from_dict(queue_data)

	var character_data = data.get("character_state", {})
	if typeof(character_data) == TYPE_DICTIONARY:
		room.character_state = CharacterStateScript.from_dict(character_data)

	var replay_data = data.get("replay_log", [])
	if typeof(replay_data) == TYPE_ARRAY:
		room.replay_log = ReplayLogScript.from_array(replay_data)

	var history = data.get("result_history", [])
	if typeof(history) == TYPE_ARRAY:
		for item in history:
			if typeof(item) == TYPE_DICTIONARY:
				room.result_history.append(item.duplicate(true))

	var recovery = data.get("last_recovery_status", {})
	if typeof(recovery) == TYPE_DICTIONARY:
		room.last_recovery_status = recovery.duplicate(true)

	return room
