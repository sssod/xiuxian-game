extends RefCounted

const DemoConstants = preload("res://scripts/core/demo_constants.gd")
const LogUtils = preload("res://scripts/core/log_utils.gd")

const TRANSITIONS := {
	"room_loading": ["turn_start"],
	"turn_start": ["report_review", "instant_personal", "personal_action_planning"],
	"report_review": ["instant_personal", "personal_action_planning"],
	"instant_personal": ["personal_action_planning"],
	"personal_action_planning": ["waiting_lock"],
	"waiting_lock": ["personal_action_planning", "settlement"],
	"settlement": ["inserted_event", "writeback", "turn_end"],
	"inserted_event": ["settlement", "writeback"],
	"writeback": ["turn_end"],
	"turn_end": ["turn_start", "report_review", "personal_action_planning"]
}

static func can_transition(runtime: Dictionary, target_phase: String) -> bool:
	if not DemoConstants.PHASES.has(target_phase):
		return false
	var current_phase := str(runtime.get("room_state", {}).get("current_phase", "room_loading"))
	return TRANSITIONS.get(current_phase, []).has(target_phase)

static func transition_to(runtime: Dictionary, target_phase: String) -> Dictionary:
	var room_state: Dictionary = runtime.get("room_state", {})
	var current_phase := str(room_state.get("current_phase", "room_loading"))
	if not can_transition(runtime, target_phase):
		return {
			"ok": false,
			"from": current_phase,
			"to": target_phase,
			"error": "Invalid phase transition."
		}

	room_state["current_phase"] = target_phase
	runtime["room_state"] = room_state
	_append_debug(runtime, current_phase, target_phase)
	return {
		"ok": true,
		"from": current_phase,
		"to": target_phase,
		"error": ""
	}

static func force_phase(runtime: Dictionary, target_phase: String) -> void:
	if not DemoConstants.PHASES.has(target_phase):
		return
	runtime["room_state"]["current_phase"] = target_phase

static func _append_debug(runtime: Dictionary, from_phase: String, to_phase: String) -> void:
	var room_state: Dictionary = runtime.get("room_state", {})
	if not runtime.has("debug_logs"):
		runtime["debug_logs"] = []
	runtime["debug_logs"].append(LogUtils.debug(
		"phase_transition",
		"%s -> %s" % [from_phase, to_phase],
		int(room_state.get("current_turn_id", 0)),
		int(room_state.get("current_world_hour", 0)),
		{}
	))
