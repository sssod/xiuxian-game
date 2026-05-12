extends SceneTree

const RuntimeConstantsScript = preload("res://src/runtime/runtime_constants.gd")
const StructuredLoggerScript = preload("res://src/runtime/structured_logger.gd")
const XiuxianRuntimeScript = preload("res://src/runtime/xiuxian_runtime.gd")


func _init() -> void:
	var logger = StructuredLoggerScript.new()
	logger.info("smoke.start", {
		"app_version": RuntimeConstantsScript.APP_VERSION,
		"godot_version_target": RuntimeConstantsScript.GODOT_VERSION_TARGET,
	})

	var runtime = XiuxianRuntimeScript.new()
	var output = runtime.run_empty_room_smoke()
	var ok = bool(output.get("ok", false))

	if ok:
		logger.info("smoke.pass", output)
		print(JSON.stringify(output))
		quit(0)
	else:
		logger.error("smoke.fail", output)
		quit(1)
