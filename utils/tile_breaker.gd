class_name TileBreaker

static var ground: TileMapLayer
static var overlay: TileMapLayer

const ENERGY := preload("uid://othtdwxul6oi")
const ORE := preload("uid://bayy7fbn27s3h")


static func register(new_ground: TileMapLayer, new_overlay: TileMapLayer) -> void:
	ground = new_ground
	overlay = new_overlay


## Breaks the wall or ceiling at coord. Returns true if something was broken.
static func break_tile(coord: Vector2i) -> bool:
	var id := ground.get_cell_source_id(coord)
	if id != Tiles.Id.WALL and id != Tiles.Id.CEILING:
		return false

	var tile_data := ground.get_cell_tile_data(coord)
	ground.set_cell(coord, Tiles.Id.GROUND, Vector2i(randi_range(0, 2), 0))
	overlay.set_cell(coord, Tiles.Id.NONE, Vector2i.ZERO)
	_update_neighbors(coord)
	GameEvents.navigation_updated.emit(coord, false)
	_spawn_ore(coord, tile_data)
	return true


static func _update_neighbors(coord: Vector2i) -> void:
	# Remove or restore the shadow below the broken tile.
	var bottom := ground.get_neighbor_cell(coord, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE)
	if ground.get_cell_source_id(bottom) == Tiles.Id.WALL:
		var atlas := ground.get_cell_atlas_coords(bottom)
		overlay.set_cell(bottom, Tiles.Id.CEILING, Vector2i(atlas.x, 1))
	else:
		overlay.set_cell(bottom, Tiles.Id.NONE, Vector2i.ZERO)

	# A ceiling above becomes a wall, and the broken tile gets a shadow.
	var top := ground.get_neighbor_cell(coord, TileSet.CELL_NEIGHBOR_TOP_SIDE)
	if ground.get_cell_source_id(top) == Tiles.Id.CEILING:
		var atlas := ground.get_cell_atlas_coords(top)
		ground.set_cell(top, Tiles.Id.WALL, atlas)
		overlay.set_cell(top, Tiles.Id.CEILING, Vector2i(atlas.x, 1))
		overlay.set_cell(coord, Tiles.Id.SHADOW, Vector2i.ZERO)


static func _spawn_ore(coord: Vector2i, tile_data: TileData) -> void:
	var ore_type: int = tile_data.get_custom_data("ore_type")
	if ore_type == 0:
		return

	var pickup := Scenes.AUTO_PICKUP.instantiate() as AutoPickup
	pickup.set_item(ENERGY if ore_type == 1 else ORE)
	var base_layer := ground.get_tree().get_first_node_in_group("base_layer")
	base_layer.call_deferred("add_child", pickup)
	pickup.global_position = ground.to_global(ground.map_to_local(coord))
