extends RefCounted
class_name StructuredLogger


func info(event_name: String, data: Dictionary = {}) -> void:
	_emit("info", event_name, data)


func error(event_name: String, data: Dictionary = {}) -> void:
	_emit("error", event_name, data)


func _emit(level: String, event_name: String, data: Dictionary) -> void:
	print(JSON.stringify({
		"level": level,
		"event": event_name,
		"data": data,
	}))
