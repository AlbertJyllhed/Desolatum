extends EnemyState

@export_group("Pathing")
@export var min_update_time : float = 0.3
@export var max_update_time : float = 0.6
@export var waypoint_reach_distance : float = 4.0
## If the enemy ends up this far from the next waypoint, force a repath
@export var max_waypoint_distance : float = 40.0

@export_group("Chase")
@export var run_chance : float = 0.5
## Within this distance and with line of sight, ignore the path and run straight at the player
@export var direct_chase_distance : float = 64.0

@export_group("Separation")
@export var separation_radius : float = 16.0
@export var separation_weight : float = 0.8

var pathfinding_grid : PathfindingGrid
var astar_grid : AStarGrid2D
var tilemap : TileMap

var path : Array[Vector2i] = []
var last_goal_tile : Vector2i = Vector2i(-9999, -9999)
var has_line_of_sight : bool = false


func _ready():
	super._ready()
	pathfinding_grid = get_tree().get_first_node_in_group("pathfinding")
	astar_grid = pathfinding_grid.astar_grid
	tilemap = pathfinding_grid.tilemap


func enter(message = {}):
	state_machine.animation_player.play("walk_right")
	path.clear()
	last_goal_tile = Vector2i(-9999, -9999)
	has_line_of_sight = false
	
	# Short random delay so a wave of enemies doesn't all repath on the same frame
	state_machine.timer.start(randf_range(0.05, 0.3))
	
	if randf() <= run_chance:
		enemy_entity.max_speed = enemy_entity.base_speed + 10


func exit():
	state_machine.timer.stop()
	enemy_entity.max_speed = enemy_entity.base_speed
	path.clear()


# Runs on the timer: the expensive desicions (LOS check, A*)
func timeout():
	var player = state_machine.player
	if not is_instance_valid(player):
		state_machine.transition_to("Wander")
		return
	
	var ray = state_machine.target_locator_ray
	has_line_of_sight = ray != null and ray.has_target()
	
	var dist = enemy_entity.global_position.distance_to(player.global_position)
	var chasing_directly = has_line_of_sight and dist < direct_chase_distance
	
	if not chasing_directly:
		if not update_path(player.global_position):
			state_machine.transition_to("Wander")
			return
	
	state_machine.timer.start(randf_range(min_update_time, max_update_time))


# Runs every physics frame: cheap steering only
func physics_update(delta):
	var player = state_machine.player
	if not is_instance_valid(player):
		return
	
	var target_pos = get_steer_target(player)
	var dir = (target_pos - enemy_entity.global_position).normalized()
	dir += get_separation() * separation_weight
	enemy_entity.direction = dir.normalized()


func get_steer_target(player: Node2D) -> Vector2:
	var enemy_pos = enemy_entity.global_position
	var dist_to_player = enemy_pos.distance_to(player.global_position)
	
	if has_line_of_sight and dist_to_player < direct_chase_distance:
		return player.global_position
	
	# Drop waypoints we've already reached
	while not path.is_empty() and enemy_pos.distance_to(tile_to_global(path[0])) < waypoint_reach_distance:
		path.pop_front()
	
	# Path is finished: we're in the player's tile, so just close the gap
	if path.is_empty():
		return player.global_position
	
	return tile_to_global(path[0])


# Returns false if the player can't be reached at all
func update_path(player_pos: Vector2) -> bool:
	var start_tile = global_to_tile(enemy_entity.global_position)
	var goal_tile = global_to_tile(player_pos)
	
	if not astar_grid.is_in_boundsv(start_tile) or not astar_grid.is_in_boundsv(goal_tile):
		return false
	
	# Player is standing against/inside a solid tile: keep the current path
	if astar_grid.is_point_solid(goal_tile):
		return true
	
	# Knocked off course?
	var off_path = not path.is_empty() \
		and enemy_entity.global_position.distance_to(tile_to_global(path[0])) > max_waypoint_distance
	
	# Nothing changed, keep walking the existing path
	if goal_tile == last_goal_tile and not path.is_empty() and not off_path:
		return true
	
	last_goal_tile = goal_tile
	
	# Already in the same tile: no path needed, physics update closes in directly
	if start_tile == goal_tile:
		path.clear()
		return true
	
	path = astar_grid.get_id_path(start_tile, goal_tile)
	if path.is_empty():
		return false
	
	path.pop_front()
	return true


func get_separation() -> Vector2:
	var push := Vector2.ZERO
	var radius_sq = separation_radius * separation_radius
	for other in get_tree().get_nodes_in_group("enemies"):
		if other == enemy_entity:
			continue
		
		var offset : Vector2 = enemy_entity.global_position - other.global_position
		var dist_sq = offset.length_squared()
		if dist_sq > 0.0 and dist_sq < radius_sq:
			var dist = sqrt(dist_sq)
			push += (offset / dist) * (1.0 - dist / separation_radius)
	
	return push


func tile_to_global(tile: Vector2i) -> Vector2:
	return tilemap.to_global(tilemap.map_to_local(tile))


func global_to_tile(pos: Vector2) -> Vector2i:
	return tilemap.local_to_map(tilemap.to_local(pos))
