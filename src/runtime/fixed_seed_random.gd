extends RefCounted
class_name FixedSeedRandom

const RuntimeConstantsScript = preload("res://src/runtime/runtime_constants.gd")

var _rng = RandomNumberGenerator.new()


func _init(seed_value: int = RuntimeConstantsScript.DEFAULT_WORLD_SEED) -> void:
	_rng.seed = seed_value


func next_debug_marker() -> int:
	return int(_rng.randi() % 1000000)
