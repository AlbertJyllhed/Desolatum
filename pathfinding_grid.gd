extends Node
class_name PathfindingGrid

@export var tilemap : TileMap
@export var debug_mode : bool

var astar_grid : AStarGrid2D
var debug_positions : Dictionary

var base_layer : Node2D
var path_debug_scene = preload("res://debug/path.tscn")

var _pending: Dictionary = {} # Vector2i -> bool, updates that arrived before the grid existed

const OBSTACLE_IDS: Array[int] = [
	Tiles.Id.BEDROCK, Tiles.Id.WALL, Tiles.Id.CEILING,
	Tiles.Id.SHIP_WALL, Tiles.Id.SHIP_CEILING
]

enum {
	GROUND = 0,
	CEILING = 1,
	WALL = 2,
	BEDROCK = 3,
	SHIP_WALL = 6,
	SHIP_CEILING = 7,
}


func _ready():
	add_to_group("pathfinding")
	GameEvents.navigation_updated.connect(update_point)
	GameEvents.level_generated.connect(setup_navigation, CONNECT_ONE_SHOT)


func setup_navigation():
	astar_grid = AStarGrid2D.new()
	astar_grid.region = tilemap.get_used_rect()
	astar_grid.cell_size = Vector2i(16, 16)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_AT_LEAST_ONE_WALKABLE
	astar_grid.jumping_enabled = true
	astar_grid.update()
	
	var obstacles: Array[Vector2i] = []
	for id in OBSTACLE_IDS:
		obstacles.append_array(tilemap.get_used_cells_by_id(Tiles.LAYER_BASE, id))
	
	base_layer = get_tree().get_first_node_in_group("base_layer")
	for tile in obstacles:
		update_point(tile, true)
	
	for tile in _pending:
		update_point(tile, _pending[tile])
	_pending.clear()


func create_debug_node(pos : Vector2):
	var path_debug_instance = path_debug_scene.instantiate()
	base_layer.call_deferred("add_child", path_debug_instance)
	path_debug_instance.global_position = pos * 16 + Vector2(8, 8)
	return path_debug_instance


func update_point(tile : Vector2i, value : bool):
	if astar_grid == null:
		_pending[tile] = value
		return
	
	if not astar_grid.is_in_boundsv(tile):
		return
	
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
