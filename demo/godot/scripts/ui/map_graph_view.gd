extends Control

signal node_selected(node_id: String)

const ContentLoader = preload("res://scripts/core/content_loader.gd")

const NODE_POSITIONS := {
	"node_qinghe_village": Vector2(0.10, 0.56),
	"node_outer_mountain_road": Vector2(0.30, 0.48),
	"node_market_town": Vector2(0.18, 0.78),
	"node_training_hall": Vector2(0.36, 0.84),
	"node_yunlu_mountain_road": Vector2(0.50, 0.40),
	"node_yunlu_gate": Vector2(0.66, 0.34),
	"node_outer_sect_room": Vector2(0.80, 0.46),
	"node_spirit_grass_slope": Vector2(0.88, 0.66),
	"node_blackstone_ridge": Vector2(0.62, 0.74),
	"node_abandoned_cave": Vector2(0.84, 0.18)
}

var content := {}
var runtime := {}
var selected_node_id := ""
var current_node_id := ""
var planned_node_id := ""
var _node_buttons := {}

func _ready() -> void:
	clip_contents = true
	custom_minimum_size = Vector2(680, 280)

func configure(next_content: Dictionary, next_runtime: Dictionary, next_selected_node_id: String, next_current_node_id: String, next_planned_node_id: String) -> void:
	content = next_content
	runtime = next_runtime
	selected_node_id = next_selected_node_id
	current_node_id = next_current_node_id
	planned_node_id = next_planned_node_id
	_refresh_node_buttons()
	_layout_node_buttons()
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_node_buttons()
		queue_redraw()

func _draw() -> void:
	_draw_routes()
	_draw_selected_path()

func _refresh_node_buttons() -> void:
	for child in get_children():
		child.queue_free()
	_node_buttons.clear()

	var node_ids: Array = content.get("tables", {}).get("nodes", {}).keys()
	node_ids.sort()
	for node_id in node_ids:
		var stable_node_id := str(node_id)
		var state := _node_state(stable_node_id)
		var visibility := str(state.get("visibility_state", "hidden"))
		var button := Button.new()
		button.toggle_mode = true
		button.button_pressed = stable_node_id == selected_node_id
		button.disabled = visibility == "hidden"
		button.focus_mode = Control.FOCUS_NONE
		button.clip_contents = true
		button.custom_minimum_size = Vector2(118, 48)
		button.text = _node_button_text(stable_node_id, state, visibility)
		button.pressed.connect(_on_node_button_pressed.bind(stable_node_id))
		add_child(button)
		_node_buttons[stable_node_id] = button

func _layout_node_buttons() -> void:
	var button_size := Vector2(118, 48)
	for node_id in _node_buttons.keys():
		var button: Button = _node_buttons[node_id]
		if not is_instance_valid(button):
			continue
		var point := _point_for_node(str(node_id))
		button.position = point - button_size * 0.5
		button.size = button_size

func _draw_routes() -> void:
	var drawn_pairs := {}
	for route in content.get("tables", {}).get("routes", {}).values():
		if typeof(route) != TYPE_DICTIONARY:
			continue
		var from_node := str(route.get("from_node", ""))
		var to_node := str(route.get("to_node", ""))
		if from_node == "" or to_node == "":
			continue
		var pair_key := _route_pair_key(from_node, to_node)
		if drawn_pairs.has(pair_key):
			continue
		drawn_pairs[pair_key] = true

		var route_visible := _node_visibility(from_node) != "hidden" and _node_visibility(to_node) != "hidden"
		var color := Color(0.48, 0.57, 0.65, 0.72)
		var width := 3.0
		if not route_visible:
			color = Color(0.35, 0.39, 0.44, 0.28)
			width = 2.0
		if route.get("risk_tags", []).has("minor_delay") or route.get("risk_tags", []).has("wild_pressure"):
			color = Color(0.86, 0.52, 0.22, color.a)

		var from_point := _point_for_node(from_node)
		var to_point := _point_for_node(to_node)
		if route_visible:
			draw_line(from_point, to_point, color, width, true)
		else:
			_draw_dashed_line(from_point, to_point, color, width)

func _draw_selected_path() -> void:
	var route := ContentLoader.route_path_between(content, planned_node_id, selected_node_id, _visible_node_ids())
	if route.is_empty():
		return
	var route_path: Array = route.get("route_path", [])
	if route_path.is_empty():
		route_path = [route]
	for step in route_path:
		if typeof(step) != TYPE_DICTIONARY:
			continue
		draw_line(
			_point_for_node(str(step.get("from_node", ""))),
			_point_for_node(str(step.get("to_node", ""))),
			Color(0.95, 0.78, 0.30, 0.95),
			6.0,
			true
		)

func _draw_dashed_line(from_point: Vector2, to_point: Vector2, color: Color, width: float) -> void:
	var delta := to_point - from_point
	var length := delta.length()
	if length <= 0.0:
		return
	var direction := delta / length
	var cursor := 0.0
	while cursor < length:
		var segment_end = min(cursor + 12.0, length)
		draw_line(from_point + direction * cursor, from_point + direction * segment_end, color, width, true)
		cursor += 20.0

func _on_node_button_pressed(node_id: String) -> void:
	node_selected.emit(node_id)

func _node_button_text(node_id: String, state: Dictionary, visibility: String) -> String:
	var title := str(state.get("display_name", node_id))
	if visibility == "hidden":
		title = "未发现节点"
	var markers := []
	if node_id == current_node_id:
		markers.append("当前")
	if node_id == planned_node_id and planned_node_id != current_node_id:
		markers.append("计划")
	if not markers.is_empty():
		return "%s\n%s · %s" % [title, visibility, "/".join(markers)]
	return "%s\n%s" % [title, visibility]

func _point_for_node(node_id: String) -> Vector2:
	var normalized: Vector2 = NODE_POSITIONS.get(node_id, Vector2(0.5, 0.5))
	var padding := Vector2(72, 40)
	var drawable_size := Vector2(max(size.x - padding.x * 2.0, 1.0), max(size.y - padding.y * 2.0, 1.0))
	return padding + Vector2(normalized.x * drawable_size.x, normalized.y * drawable_size.y)

func _node_state(node_id: String) -> Dictionary:
	if runtime.get("node_states", {}).has(node_id):
		return runtime["node_states"][node_id]
	return ContentLoader.node_template(content, node_id)

func _node_visibility(node_id: String) -> String:
	return str(_node_state(node_id).get("visibility_state", "hidden"))

func _visible_node_ids() -> Array:
	var node_ids := []
	for node_id in content.get("tables", {}).get("nodes", {}).keys():
		if _node_visibility(str(node_id)) != "hidden":
			node_ids.append(str(node_id))
	return node_ids

func _route_pair_key(from_node: String, to_node: String) -> String:
	var nodes := [from_node, to_node]
	nodes.sort()
	return "%s|%s" % [nodes[0], nodes[1]]
