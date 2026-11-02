extends EnemyState

@export var next_state : String = "Wander"
@export var min_update_time : float = 0.5
@export var max_update_time : float = 1.0

var pathfinding_grid : PathfindingGrid
var astar_grid : AStarGrid2D
var tilemap : TileMapLayer
var target_tile : Vector2i
var used_tiles : Array[Vector2i]


func _ready():
	super._ready()
	pathfinding_grid = get_tree().get_first_node_in_group("pathfinding")
	astar_grid = pathfinding_grid.astar_grid
	tilemap = pathfinding_grid.tilemap
	used_tiles = tilemap.get_used_cells_by_id(Tiles.Id.GROUND)


func timeout():
	var path = astar_grid.get_id_path(
		tilemap.local_to_map(enemy_entity.global_position),
		target_tile
	)
	
	path.pop_front()
	
	if path.is_empty():
		state_machine.transition_to(next_state)
		return
	
	enemy_entity.direction = (tilemap.map_to_local(path[0]) - enemy_entity.global_position).normalized()
	state_machine.timer.start(randf_range(min_update_time, max_update_time))


func enter(_message = {}):
	target_tile = used_tiles.pick_random()
	state_machine.animation_player.play("walk_right")
	state_machine.timer.start(randf_range(0.2, 0.5))


func exit():
	state_machine.timer.stop()
