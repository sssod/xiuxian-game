extends RefCounted
class_name CharacterState

var character_id = ""
var true_spirit_id = ""
var initialized = false


func to_dict() -> Dictionary:
	return {
		"character_id": character_id,
		"true_spirit_id": true_spirit_id,
		"initialized": initialized,
	}


static func from_dict(data: Dictionary):
	var state = load("res://src/runtime/character_state.gd").new()
	state.character_id = str(data.get("character_id", ""))
	state.true_spirit_id = str(data.get("true_spirit_id", ""))
	state.initialized = bool(data.get("initialized", false))
	return state
