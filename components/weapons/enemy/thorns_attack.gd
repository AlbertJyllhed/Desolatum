extends EnemyWeaponBase

@export var thorn_scene : PackedScene
@export var thorn_amount : int = 3

var tilemap : TileMapLayer
var base_layer : Node2D
var pathfinding_grid : PathfindingGrid
var astar_grid : AStarGrid2D


func setup_weapon(player: Player, target_locator_ray: TargetLocatorRay) -> void:
	super.setup_weapon(player, target_locator_ray)
	tilemap = get_tree().get_first_node_in_group("tilemap_layer")
	base_layer = get_tree().get_first_node_in_group("base_layer")
	pathfinding_grid = get_tree().get_first_node_in_group("pathfinding")
	astar_grid = pathfinding_grid.astar_grid


func attack(_attack_vector: Vector2):
	if not is_instance_valid(_player):
		return
	
	var used_tiles: Array[Vector2i] = []
	for i in thorn_amount:
		var tile_pos = find_free_tile(used_tiles)
		if tile_pos == null:
			continue
		
		used_tiles.append(tile_pos)
		var local_pos = tilemap.map_to_local(tile_pos)
		var global_pos = tilemap.to_global(local_pos)
		
		var thorn_instance = thorn_scene.instantiate() as Node2D
		base_layer.add_child(thorn_instance)
		thorn_instance.global_position = global_pos


func find_free_tile(used_tiles: Array[Vector2i], max_attempts: int = 8) -> Variant:
	for attempt in max_attempts:
		var offset = Vector2(randi_range(-32, 32), randi_range(-32, 32))
		var tile_pos = tilemap.local_to_map(tilemap.to_local(_player.global_position + offset))
		if used_tiles.has(tile_pos):
			continue
		
		if is_tile_free(tile_pos):
			return tile_pos
	
	return null


func is_tile_free(tile: Vector2i) -> bool:
	if not astar_grid.is_in_boundsv(tile):
		return false
	
	return not astar_grid.is_point_solid(tile)
