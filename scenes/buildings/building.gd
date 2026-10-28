@icon("res://addons/at-icons/node2d/building.svg")
extends StaticBody2D
class_name Building

static var occupied : Dictionary = {} # Vector2i -> Building

@export var blocks_navigation : bool = true

var tile : Vector2i


func _ready() -> void:
	var tilemap = get_tree().get_first_node_in_group("tilemap_layer") as TileMap
	tile = tilemap.local_to_map(tilemap.to_local(global_position))
	occupied[tile] = self
	if blocks_navigation:
		GameEvents.navigation_updated.emit(tile, true)


func _exit_tree():
	occupied.erase(tile)
	if blocks_navigation:
		GameEvents.navigation_updated.emit(tile, false)
