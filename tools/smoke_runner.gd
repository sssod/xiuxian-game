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
	var empty_room_output = runtime.run_empty_room_smoke()
	var save_load_output = runtime.run_save_load_recovery_smoke()
	var active_breathing_output = runtime.run_active_breathing_smoke()
	var command_template_output = runtime.run_command_template_smoke()
	var ok = (
		bool(empty_room_output.get("ok", false))
		and bool(save_load_output.get("ok", false))
		and bool(active_breathing_output.get("ok", false))
		and bool(command_template_output.get("ok", false))
	)
	var output = {
		"ok": ok,
		"empty_room": empty_room_output,
		"save_load_recovery": save_load_output,
		"active_breathing": active_breathing_output,
		"command_templates": command_template_output,
	}

	if ok:
		logger.info("smoke.pass", output)
		print(JSON.stringify(output))
		quit(0)
	else:
		logger.error("smoke.fail", output)
		quit(1)
