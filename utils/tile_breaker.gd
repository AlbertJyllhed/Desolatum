class_name TileBreaker

## Breaks and damages wall/ceiling tiles. Tiles have health (see TILE_HEALTH):
## damage_tile() chips at it and shows cracks, break_tile() removes the tile
## at once (explosions). Damage is remembered per cell until the level ends.

static var ground: TileMapLayer
static var overlay: TileMapLayer

const ENERGY := preload("uid://othtdwxul6oi")
const ORE := preload("uid://bayy7fbn27s3h")
const DEBRIS := preload("res://particles/debris.tscn")
const CRACK_TEXTURE := preload("res://assets/textures/crack.png")

## Hits needed to break a tile, by the tile's ore_type (0 rock, 1 energy, 2 ore).
const TILE_HEALTH := {0: 2, 1: 3, 2: 3}
## Pickups dropped when a tile breaks, by ore_type: a random count from x to y.
const ORE_DROPS := {0: Vector2i(0, 0), 1: Vector2i(1, 3), 2: Vector2i(1, 3)}
## Frames in crack.png, shown in order as the tile takes damage.
const CRACK_STAGES := 3
## Camera shake when a tile breaks (fades with distance).
const BREAK_SHAKE := 0.15

## Damage taken so far, per cell.
static var _damage: Dictionary = {}
## Crack sprite shown on each damaged cell.
static var _cracks: Dictionary = {}
## Average colour per tile (source id + atlas coords), for the debris.
static var _tile_colors: Dictionary = {}


static func register(new_ground: TileMapLayer, new_overlay: TileMapLayer) -> void:
	ground = new_ground
	overlay = new_overlay
	_damage.clear()
	_cracks.clear()
	_tile_colors.clear()


static func is_breakable(coord: Vector2i) -> bool:
	var id := ground.get_cell_source_id(coord)
	return id == Tiles.Id.WALL or id == Tiles.Id.CEILING


## What the wall or ceiling at coord holds (Tiles.OreType). Walls keep it on the
## wall tile itself, ceilings on their overlay tile.
static func get_ore_type(coord: Vector2i) -> int:
	var tile_data: TileData = null
	match ground.get_cell_source_id(coord):
		Tiles.Id.WALL:
			tile_data = ground.get_cell_tile_data(coord)
		Tiles.Id.CEILING:
			if overlay.get_cell_source_id(coord) == Tiles.Id.CEILING_OVERLAY:
				tile_data = overlay.get_cell_tile_data(coord)
	return tile_data.get_custom_data("ore_type") if tile_data else Tiles.OreType.NONE


## Hits needed to break the tile at coord.
static func get_tile_health(coord: Vector2i) -> int:
	return TILE_HEALTH.get(get_ore_type(coord), TILE_HEALTH[0])


## Deals [param amount] damage to the wall or ceiling at coord and breaks it
## when its health runs out. [param hit_normal] points back toward whatever
## hit it, for the debris direction. Returns true if a tile was hit.
static func damage_tile(coord: Vector2i, amount: int = 1, hit_normal: Vector2 = Vector2.ZERO) -> bool:
	if not is_breakable(coord):
		return false

	var health := get_tile_health(coord)
	var dealt: int = _damage.get(coord, 0) + amount
	if dealt >= health:
		return break_tile(coord)

	_damage[coord] = dealt
	_show_crack(coord, float(dealt) / health)
	var direction := hit_normal if hit_normal != Vector2.ZERO else Vector2.UP
	_spawn_debris(coord, [direction.angle()])
	return true


## Breaks the wall or ceiling at coord right away. Returns true if something was broken.
static func break_tile(coord: Vector2i) -> bool:
	if not is_breakable(coord):
		return false

	_remove_tile(coord)
	# One small shake, even when a neighbour broke along with it.
	var camera := ground.get_viewport().get_camera_2d() as PlayerCamera
	if camera:
		camera.add_shake_at(BREAK_SHAKE, _cell_to_global(coord))
	return true


## Turns the tile into floor, drops its ore and spawns debris, then fixes up the
## tiles above and below (which can break along with it).
static func _remove_tile(coord: Vector2i) -> void:
	var ore_type := get_ore_type(coord)
	var color := _get_tile_color(coord)
	ground.set_cell(coord, Tiles.Id.GROUND, Vector2i(randi_range(0, 2), 0))
	overlay.set_cell(coord, Tiles.Id.NONE, Vector2i.ZERO)
	_clear_damage(coord)
	_update_neighbors(coord)
	GameEvents.navigation_updated.emit(coord, false)
	GameEvents.tile_broken.emit(coord)
	_spawn_ore(coord, ore_type)

	# Debris in three directions.
	var start := randf() * TAU
	_spawn_debris(coord, [start, start + TAU / 3.0, start + TAU * 2.0 / 3.0], color)


## Every wall needs a ceiling (or bedrock) above it. A wall that would be left
## with floor above breaks too, so this never goes further than one tile.
static func _update_neighbors(coord: Vector2i) -> void:
	# A wall below just lost its ceiling, so it breaks too. Otherwise remove the
	# shadow the broken wall cast on the floor below.
	var bottom := ground.get_neighbor_cell(coord, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE)
	if ground.get_cell_source_id(bottom) == Tiles.Id.WALL:
		_remove_tile(bottom)
	elif overlay.get_cell_source_id(bottom) == Tiles.Id.SHADOW:
		overlay.set_cell(bottom, Tiles.Id.NONE, Vector2i.ZERO)

	# A ceiling above becomes a wall: its overlay ore moves into the wall's atlas
	# column (the column is the ore_type) and the broken tile gets a shadow. If
	# there is floor above that new wall, it breaks too.
	var top := ground.get_neighbor_cell(coord, TileSet.CELL_NEIGHBOR_TOP_SIDE)
	if ground.get_cell_source_id(top) == Tiles.Id.CEILING:
		var ore_type := get_ore_type(top)
		ground.set_cell(top, Tiles.Id.WALL, Vector2i(ore_type, 0))
		overlay.set_cell(top, Tiles.Id.NONE, Vector2i.ZERO)
		overlay.set_cell(coord, Tiles.Id.SHADOW, Vector2i.ZERO)
		var above := ground.get_neighbor_cell(top, TileSet.CELL_NEIGHBOR_TOP_SIDE)
		if ground.get_cell_source_id(above) == Tiles.Id.GROUND:
			_remove_tile(top)


static func _spawn_ore(coord: Vector2i, ore_type: int) -> void:
	var drop_range: Vector2i = ORE_DROPS.get(ore_type, Vector2i.ZERO)
	var count: int = randi_range(drop_range.x, drop_range.y)
	if count <= 0:
		return

	var base_layer := ground.get_tree().get_first_node_in_group("base_layer")
	for i in count:
		var pickup := Scenes.AUTO_PICKUP.instantiate() as AutoPickup
		pickup.set_item(ENERGY if ore_type == Tiles.OreType.ENERGY else ORE)
		base_layer.call_deferred("add_child", pickup)
		pickup.global_position = _cell_to_global(coord)


## Shows (or advances) the crack on a damaged tile. [param damage_ratio] is 0..1.
static func _show_crack(coord: Vector2i, damage_ratio: float) -> void:
	var crack: Sprite2D = _cracks.get(coord)
	if not is_instance_valid(crack):
		crack = Sprite2D.new()
		crack.texture = CRACK_TEXTURE
		crack.hframes = CRACK_STAGES
		# A child of the overlay layer draws above the tiles.
		overlay.add_child(crack)
		crack.position = overlay.map_to_local(coord)
		_cracks[coord] = crack
	crack.frame = clampi(ceili(damage_ratio * CRACK_STAGES) - 1, 0, CRACK_STAGES - 1)


static func _clear_damage(coord: Vector2i) -> void:
	_damage.erase(coord)
	var crack: Sprite2D = _cracks.get(coord)
	if is_instance_valid(crack):
		crack.queue_free()
	_cracks.erase(coord)


## Spawns one debris burst per angle (radians) at the tile.
static func _spawn_debris(coord: Vector2i, angles: Array, color: Color = Color(-1, -1, -1)) -> void:
	if color.r < 0.0:
		color = _get_tile_color(coord)
	var base_layer := ground.get_tree().get_first_node_in_group("base_layer")
	if not base_layer:
		return
	for angle: float in angles:
		var debris := Pool.spawn(DEBRIS, base_layer, _cell_to_global(coord), angle) as Node2D
		debris.modulate = color


## Average colour of the tile's texture, so debris matches the rock. Cached.
static func _get_tile_color(coord: Vector2i) -> Color:
	var source_id := ground.get_cell_source_id(coord)
	var atlas_coords := ground.get_cell_atlas_coords(coord)
	var key := Vector3i(source_id, atlas_coords.x, atlas_coords.y)
	if _tile_colors.has(key):
		return _tile_colors[key]

	var color := Color.WHITE
	var source := ground.tile_set.get_source(source_id) as TileSetAtlasSource if source_id >= 0 else null
	if source and source.texture:
		var image := source.texture.get_image()
		if image:
			if image.is_compressed():
				image.decompress()
			var region := source.get_tile_texture_region(atlas_coords)
			var sum := Color(0, 0, 0, 0)
			var count := 0
			for y in range(region.position.y, region.end.y):
				for x in range(region.position.x, region.end.x):
					var pixel := image.get_pixel(x, y)
					if pixel.a > 0.5:
						sum += pixel
						count += 1
			if count > 0:
				color = Color(sum.r / count, sum.g / count, sum.b / count, 1.0)
	_tile_colors[key] = color
	return color


static func _cell_to_global(coord: Vector2i) -> Vector2:
	return ground.to_global(ground.map_to_local(coord))
