extends EnemyState

@export var min_update_time : float = 0.5
@export var max_update_time : float = 1.0
@export var run_chance : float = 0.5

var pathfinding_grid : PathfindingGrid
var astar_grid : AStarGrid2D
var tilemap : TileMap


func _ready():
	super._ready()
	pathfinding_grid = get_tree().get_first_node_in_group("pathfinding")
	astar_grid = pathfinding_grid.astar_grid
	tilemap = pathfinding_grid.tilemap


func timeout():
	var player = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		state_machine.transition_to("Wander")
		return
	
	var path = astar_grid.get_id_path(
		tilemap.local_to_map(enemy_entity.global_position),
		tilemap.local_to_map(player.global_position)
	)
	
	path.pop_front()
	
	if path.is_empty():
		state_machine.transition_to("Wander")
		return
	
	enemy_entity.direction = (tilemap.map_to_local(path[0]) - enemy_entity.global_position).normalized()
	state_machine.timer.start(randf_range(min_update_time, max_update_time))


func enter(message = {}):
	state_machine.animation_player.play("walk_right")
	state_machine.timer.start(randf_range(0.2, 0.5))
	if randf() > run_chance:
		return
	
	enemy_entity.max_speed = enemy_entity.base_speed + 10


func exit():
	state_machine.timer.stop()
	enemy_entity.max_speed = enemy_entity.base_speed
