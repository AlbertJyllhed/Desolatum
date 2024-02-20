extends Node
class_name PathfindingGrid

@export var tilemap : TileMap
@export var debug_mode : bool

var astar_grid : AStarGrid2D
var debug_positions : Dictionary

var base_layer : Node2D
var path_debug_scene = preload("res://debug/path.tscn")

enum {
	ground = 0,
	ceiling = 1,
	wall = 2,
	bedrock = 3
}


func _ready():
	add_to_group("pathfinding")
	GameEvents.navigation_updated.connect(update_point)
	setup_navigation()


func setup_navigation():
	astar_grid = AStarGrid2D.new()
	astar_grid.region = tilemap.get_used_rect()
	astar_grid.cell_size = Vector2i(16, 16)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_AT_LEAST_ONE_WALKABLE
	astar_grid.jumping_enabled = true
	astar_grid.update()
	
	var bedrock_tiles = tilemap.get_used_cells_by_id(0, bedrock)
	var wall_tiles = tilemap.get_used_cells_by_id(0, wall)
	var ceiling_tiles = tilemap.get_used_cells_by_id(0, ceiling)
	var obstacles = bedrock_tiles + wall_tiles + ceiling_tiles
	
	base_layer = get_tree().get_first_node_in_group("base_layer")
	for tile in obstacles:
		update_point(tile, true)


func create_debug_node(pos : Vector2):
	var path_debug_instance = path_debug_scene.instantiate()
	base_layer.call_deferred("add_child", path_debug_instance)
	path_debug_instance.global_position = pos * 16 + Vector2(8, 8)
	return path_debug_instance


func update_point(tile : Vector2i, value : bool):
	astar_grid.set_point_solid(tile, value)
	if not debug_mode:
		return
	
	if value:
		var debug_node = create_debug_node(tile)
		debug_positions[tile] = debug_node
		return
	
	if debug_positions.has(tile):
		debug_positions[tile].queue_free()
		debug_positions.erase(tile)
