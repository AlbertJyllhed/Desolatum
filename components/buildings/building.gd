@icon("res://addons/at-icons/node2d/building.svg")
extends StaticBody2D
class_name Building

static var occupied : Dictionary = {} # Vector2i -> Building

@export var blocks_navigation : bool = true

var tile : Vector2i

const ENEMY_PATH_COST := 8.0


func _ready() -> void:
	var tilemap = get_tree().get_first_node_in_group("tilemap_layer") as TileMapLayer
	tile = tilemap.local_to_map(tilemap.to_local(global_position))
	occupied[tile] = self
	if blocks_navigation:
		_set_path_weight(ENEMY_PATH_COST)


func _exit_tree():
	occupied.erase(tile)
	if blocks_navigation:
		_set_path_weight(1.0)


func _set_path_weight(weight: float) -> void:
	var grid := get_tree().get_first_node_in_group("pathfinding") as PathfindingGrid
	if grid == null or grid.astar_grid == null:
		return
	if grid.astar_grid.is_in_boundsv(tile):
		grid.astar_grid.set_point_weight_scale(tile, weight)
