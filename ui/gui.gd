extends Control
class_name GUI

## The game's whole UI. Put one gui.tscn instance in every scene (levels and
## the ship). It's in the "ui_layer" group, so other code finds it with
## get_tree().get_first_node_in_group("ui_layer") and uses the functions below.
##
## Two layers: MainUI holds the HUD, OverlayUI (drawn above it) holds the
## pause menu, FPS counter, transition screen, cursor and the game over screen.

const GAME_OVER_SCREEN_SCENE : PackedScene = preload("uid://by6qfdacpxedr")

## HUD parts that only make sense in a level (health, ammo, weapons...).
## Created in this order into MainUI when the scene is a Level.
@export var level_hud_scenes : Array[PackedScene] = []

@onready var main_ui : CanvasLayer = $MainUI
@onready var overlay_ui : CanvasLayer = $OverlayUI


func _ready() -> void:
	add_to_group("ui_layer")
	if is_in_level():
		for scene : PackedScene in level_hud_scenes:
			if scene:
				main_ui.add_child(scene.instantiate())

	# Hide the HUD whenever a menu (pause, game over...) is open in OverlayUI.
	for child : Node in overlay_ui.get_children():
		_watch_menu(child)
	overlay_ui.child_entered_tree.connect(_watch_menu)
	overlay_ui.child_exiting_tree.connect(func(_node : Node) -> void: _update_hud_visibility.call_deferred())
	_update_hud_visibility()


func _watch_menu(node : Node) -> void:
	if node is Menu and not node.visibility_changed.is_connected(_update_hud_visibility):
		node.visibility_changed.connect(_update_hud_visibility)
		_update_hud_visibility()


## The HUD shows only while no menu in OverlayUI is visible.
func _update_hud_visibility() -> void:
	var menu_open : bool = false
	for child : Node in overlay_ui.get_children():
		if child is Menu and child.visible and not child.is_queued_for_deletion():
			menu_open = true
			break
	main_ui.visible = not menu_open


## The Level this GUI is in, or null on the ship (or any non-level scene).
func get_level() -> Level:
	return owner as Level


func is_in_level() -> bool:
	return get_level() != null


func is_on_ship() -> bool:
	return owner != null and owner.scene_file_path == SceneManager.ship_scene.resource_path


## Adds something to the HUD layer, e.g. a mission timer.
func add_to_hud(node : Node) -> void:
	main_ui.add_child(node)


## Shows the game over screen above the HUD. It goes first in OverlayUI, so
## the pause menu, FPS counter, transition and cursor still draw over it.
func show_game_over() -> void:
	var game_over_screen : Node = GAME_OVER_SCREEN_SCENE.instantiate()
	overlay_ui.add_child(game_over_screen)
	overlay_ui.move_child(game_over_screen, 0)


## The GUI a node belongs to, found by walking up its parents.
static func find_for(node : Node) -> GUI:
	var current : Node = node
	while current:
		if current is GUI:
			return current
		current = current.get_parent()
	return null
