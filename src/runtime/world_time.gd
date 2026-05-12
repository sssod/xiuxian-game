extends RefCounted
class_name WorldTime

const HOURS_PER_DAY = 24

var world_day: int = 1
var world_hour: int = 0


func advance_hours(hours: int) -> void:
	var safe_hours = hours
	if safe_hours < 0:
		safe_hours = 0

	for _i in range(safe_hours):
		world_hour += 1
		if world_hour >= HOURS_PER_DAY:
			world_day += 1
			world_hour = 0


func to_dict() -> Dictionary:
	return {
		"world_day": world_day,
		"world_hour": world_hour,
	}


static func from_dict(data: Dictionary):
	var world_time = load("res://src/runtime/world_time.gd").new()
	world_time.world_day = int(data.get("world_day", 1))
	world_time.world_hour = int(data.get("world_hour", 0))
	return world_time


func label() -> String:
	return "Day %d Hour %02d" % [world_day, world_hour]
