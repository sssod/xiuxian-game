extends RefCounted

const SCHEMA_VERSION := "demo.phase_c.v0.1"
const CONTENT_VERSION := "demo.content.v0.2"
const DEFAULT_WORLD_SEED := 20260506
const DEFAULT_TURN_DURATION_DAYS := 5
const DEFAULT_DECISION_COUNTDOWN_SECONDS := 120
const HOURS_PER_DAY := 24
const DEBUG_LOG_LIMIT := 20

const LOCAL_PLAYER_ID := "player_local"
const LOCAL_SPIRIT_ID := "spirit_local"
const LOCAL_CHARACTER_ID := "character_local"

const PHASES := [
	"room_loading",
	"turn_start",
	"report_review",
	"instant_personal",
	"personal_action_planning",
	"waiting_lock",
	"settlement",
	"inserted_event",
	"writeback",
	"turn_end"
]

static func default_turn_config() -> Dictionary:
	return {
		"turn_duration_days": DEFAULT_TURN_DURATION_DAYS,
		"decision_countdown_seconds": DEFAULT_DECISION_COUNTDOWN_SECONDS,
		"decision_countdown_enabled": false,
		"internal_tick_unit": "hour",
		"visible_time_unit": "day"
	}

static func turn_total_hours(turn_config: Dictionary) -> int:
	return int(turn_config.get("turn_duration_days", DEFAULT_TURN_DURATION_DAYS)) * HOURS_PER_DAY

static func macro_period_for_world_day(world_day: int) -> String:
	var period_index := int(floor(float(max(world_day, 1) - 1) / 30.0)) + 1
	return "macro_period_%03d" % period_index

static func make_time_state(turn_id: int, world_day: int, world_hour: int) -> Dictionary:
	return {
		"turn_id": turn_id,
		"world_day": world_day,
		"world_hour": world_hour,
		"hour_tick": world_hour,
		"macro_period_id": macro_period_for_world_day(world_day)
	}
