extends Control

## Vertical run map: the top row is the first level and every row below is one
## step deeper underground. Nodes are small icons; hovering or focusing one shows
## its details in the info panel.

signal node_chosen(node : MapNode)

@export_group("Layout")
@export var icon_size : Vector2 = Vector2(16, 16)
@export var node_spacing : float = 36.0   ## horizontal distance between nodes in a row (leaves room for the "here" arrow)
@export var map_margin : float = 10.0     ## space above the first and below the last row

@export_group("Icons")
## Used when a mission has no icon of its own.
@export var mission_icon : Texture2D = preload("res://assets/textures/turret_icon.png")
@export var elite_icon : Texture2D = preload("res://assets/textures/warning_sign.png")
@export var boss_icon : Texture2D = preload("res://assets/textures/danger_sign.png")
@export var rest_icon : Texture2D = preload("res://assets/textures/health_kit.png")
@export var shop_icon : Texture2D
@export var focus_frame : Texture2D = preload("res://assets/textures/icon_border.png")
@export var here_marker : Texture2D = preload("res://assets/textures/selection_arrow.png")

const COLOR_AVAILABLE := Color.WHITE
const COLOR_LOCKED := Color(1, 1, 1, 0.35)
const COLOR_VISITED := Color(0.054902, 1, 0.4)
const COLOR_LINE := Color(1, 1, 1, 0.2)
const COLOR_LINE_OPEN := Color(0.054902, 1, 0.4)

@onready var map_area : Control = $MapArea
@onready var line_container : Control = $MapArea/LineContainer
@onready var node_container : Control = $MapArea/NodeContainer
@onready var type_label : Label = %TypeLabel
@onready var title_label : Label = %TitleLabel
@onready var details_label : Label = %DetailsLabel
@onready var status_label : Label = %StatusLabel

var buttons : Dictionary = {}   # MapNode -> TextureButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameEvents.show_path_select.connect(open)
	if shop_icon == null:
		shop_icon = _shop_frame()
	hide()


func open() -> void:
	_clear()
	_build()
	show()
	get_tree().paused = true


func _build() -> void:
	var layers : Array = Run.state.map_layers
	var available := Run.state.get_available_nodes()
	var current := Run.state.get_current_node()

	var row_spacing := (map_area.size.y - map_margin * 2.0 - icon_size.y) / maxf(layers.size() - 1, 1)
	var center_x := map_area.size.x / 2.0

	for l in layers.size():
		var layer : Array = layers[l]
		var row_width := (layer.size() - 1) * node_spacing
		for i in layer.size():
			var node : MapNode = layer[i]
			var top_left := Vector2(
				center_x - row_width / 2.0 + i * node_spacing,
				map_margin + l * row_spacing
			) - Vector2(icon_size.x / 2.0, 0)
			buttons[node] = _make_button(node, top_left, available, current)

	for l in layers.size() - 1:
		for node : MapNode in layers[l]:
			for next_index in node.next:
				var target : MapNode = layers[l + 1][next_index]
				_draw_link(buttons[node], buttons[target], node == current and available.has(target))

	if current:
		_add_here_marker(buttons[current])
	_focus_first_available(available)


func _make_button(node : MapNode, top_left : Vector2, available : Array[MapNode], current : MapNode) -> TextureButton:
	var button := TextureButton.new()
	button.texture_normal = _icon_for(node)
	button.texture_focused = focus_frame
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.custom_minimum_size = icon_size
	button.size = icon_size
	button.position = top_left
	button.focus_mode = Control.FOCUS_ALL   # locked nodes can still be inspected

	# Nodes with no scene yet (e.g. Rest/Shop before those exist) can't be picked.
	var can_pick := available.has(node) and SceneManager.has_scene_for(node)
	if node.visited:
		button.modulate = COLOR_VISITED
	elif can_pick:
		button.modulate = COLOR_AVAILABLE
	else:
		button.modulate = COLOR_LOCKED

	button.mouse_entered.connect(button.grab_focus)
	button.focus_entered.connect(func(): _show_info(node, available, current))
	if can_pick:
		button.pressed.connect(func(): choose(node))

	node_container.add_child(button)
	return button


func _icon_for(node : MapNode) -> Texture2D:
	match node.type:
		MapNode.Type.REST: return rest_icon
		MapNode.Type.SHOP: return shop_icon
		MapNode.Type.BOSS: return boss_icon
		MapNode.Type.ELITE: return elite_icon
	if node.option and node.option.mission and node.option.mission.icon:
		return node.option.mission.icon
	return mission_icon


func _draw_link(from : Control, to : Control, open_path : bool) -> void:
	var line := Line2D.new()
	line.width = 1.0
	line.default_color = COLOR_LINE_OPEN if open_path else COLOR_LINE
	line.add_point(from.position + Vector2(from.size.x / 2.0, from.size.y + 1))
	line.add_point(to.position + Vector2(to.size.x / 2.0, -1))
	line_container.add_child(line)


func _add_here_marker(button : Control) -> void:
	var marker := TextureRect.new()
	marker.texture = here_marker
	marker.modulate = COLOR_VISITED
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.position = button.position + Vector2(button.size.x + 2, (button.size.y - here_marker.get_height()) / 2.0)
	node_container.add_child(marker)


# --- Info panel ------------------------------------------------------------

func _show_info(node : MapNode, available : Array[MapNode], current : MapNode) -> void:
	type_label.text = _type_name(node)

	var mission := node.option.mission if node.option else null
	title_label.text = mission.title if mission else ""
	title_label.visible = title_label.text != ""

	var details : PackedStringArray = ["Depth %d" % (node.layer + 1)]
	if node.option and node.option.biome:
		details.append("Biome: %s" % node.option.biome.name)
	if mission and mission.reward:
		details.append("Reward: %s" % mission.reward.name)
	details_label.text = "\n".join(details)

	status_label.text = _status_text(node, available, current)


func _type_name(node : MapNode) -> String:
	match node.type:
		MapNode.Type.REST: return "Rest stop"
		MapNode.Type.SHOP: return "Shop"
		MapNode.Type.BOSS: return "Boss"
		MapNode.Type.ELITE: return "Elite mission"
	return "Mission"


func _status_text(node : MapNode, available : Array[MapNode], current : MapNode) -> String:
	if node == current:
		return "You are here"
	if node.visited:
		return "Cleared"
	if available.has(node):
		return "Select to descend" if SceneManager.has_scene_for(node) else "Not built yet"
	return "Out of reach"


func _clear_info() -> void:
	type_label.text = ""
	title_label.text = ""
	details_label.text = ""
	status_label.text = ""


# --- Helpers ---------------------------------------------------------------

## First frame of the shop sprite sheet, as a fallback shop icon.
func _shop_frame() -> Texture2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = preload("res://assets/textures/shop.png")
	atlas.region = Rect2(0, 0, 16, 32)
	return atlas


func _focus_first_available(available : Array[MapNode]) -> void:
	for node in available:
		if buttons.has(node):
			buttons[node].grab_focus() # gamepad support, also fills the info panel
			return


func choose(node : MapNode) -> void:
	hide()
	get_tree().paused = false
	node_chosen.emit(node)
	SceneManager.travel_to_node(node)


func _clear() -> void:
	for child in node_container.get_children():
		child.queue_free()
	for child in line_container.get_children():
		child.queue_free()
	buttons.clear()
	_clear_info()
