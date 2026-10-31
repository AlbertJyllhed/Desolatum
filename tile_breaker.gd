class_name TileBreaker

const AUTO_PICKUP := preload("res://components/pickups/auto_pickup.tscn")
const ENERGY := preload("res://resources/Items/energy.tres")
const ORE := preload("res://resources/Items/ore.tres")

## Breaks the wall or ceiling at coord. Returns true if something was broken.
static func break_tile(tilemap: TileMap, coord: Vector2i) -> bool:
	var id := tilemap.get_cell_source_id(Tiles.LAYER_BASE, coord)
	if id != Tiles.Id.WALL and id != Tiles.Id.CEILING:
		return false

	var tile_data := tilemap.get_cell_tile_data(Tiles.LAYER_BASE, coord)
	tilemap.set_cell(Tiles.LAYER_BASE, coord, Tiles.Id.GROUND, Vector2i(randi_range(0, 2), 0))
	tilemap.set_cell(Tiles.LAYER_OVERLAY, coord, Tiles.Id.NONE, Vector2i.ZERO)
	_update_neighbors(tilemap, coord)
	GameEvents.navigation_updated.emit(coord, false)
	_spawn_ore(tilemap, coord, tile_data)
	return true


static func _update_neighbors(tilemap: TileMap, coord: Vector2i) -> void:
	# Remove or restore the shadow below the broken tile.
	var bottom := tilemap.get_neighbor_cell(coord, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE)
	if tilemap.get_cell_source_id(Tiles.LAYER_BASE, bottom) == Tiles.Id.WALL:
		var atlas := tilemap.get_cell_atlas_coords(Tiles.LAYER_BASE, bottom)
		tilemap.set_cell(Tiles.LAYER_OVERLAY, bottom, Tiles.Id.CEILING, Vector2i(atlas.x, 1))
	else:
		tilemap.set_cell(Tiles.LAYER_OVERLAY, bottom, Tiles.Id.NONE, Vector2i.ZERO)

	# A ceiling above becomes a wall, and the broken tile gets a shadow.
	var top := tilemap.get_neighbor_cell(coord, TileSet.CELL_NEIGHBOR_TOP_SIDE)
	if tilemap.get_cell_source_id(Tiles.LAYER_BASE, top) == Tiles.Id.CEILING:
		var atlas := tilemap.get_cell_atlas_coords(Tiles.LAYER_BASE, top)
		tilemap.set_cell(Tiles.LAYER_BASE, top, Tiles.Id.WALL, atlas)
		tilemap.set_cell(Tiles.LAYER_OVERLAY, top, Tiles.Id.CEILING, Vector2i(atlas.x, 1))
		tilemap.set_cell(Tiles.LAYER_OVERLAY, coord, Tiles.Id.SHADOW, Vector2i.ZERO)


static func _spawn_ore(tilemap: TileMap, coord: Vector2i, tile_data: TileData) -> void:
	var ore_type: int = tile_data.get_custom_data("ore_type")
	if ore_type == 0:
		return

	var pickup := AUTO_PICKUP.instantiate() as AutoPickup
	pickup.set_item(ENERGY if ore_type == 1 else ORE)
	var base_layer := tilemap.get_tree().get_first_node_in_group("base_layer")
	base_layer.call_deferred("add_child", pickup)
	pickup.global_position = tilemap.to_global(tilemap.map_to_local(coord))
