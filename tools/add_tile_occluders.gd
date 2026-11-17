@tool
extends EditorScript

## One-off tool: sets up light occluders on the tilesets so the rock casts
## shadows into the light map. Open this file in the script editor and run it
## with File > Run (Ctrl+Shift+X). Safe to run again.
##
## Only the rock tops (ceilings, bedrock, ship ceilings) block light. Wall
## tiles are the rock's front faces: they get no occluder, so light in front
## of them lights them fully, and the ceiling right behind stops the light
## from passing through the rock. (Occluders on the wall tiles themselves
## make neighbouring wall tiles cast little shadow wedges onto each other.)

const TILESETS : Array[String] = [
	"res://resources/tilesets/tileset.tres",
	"res://resources/tilesets/ice_tileset.tres",
	"res://resources/tilesets/nest_tileset.tres",
]
## Tile sources that block light (see Tiles.Id): ceiling, bedrock, ship ceiling.
const BLOCKING_SOURCES : Array[int] = [1, 3, 7]
## Tile sources that must not block light: wall, ship wall.
const OPEN_SOURCES : Array[int] = [2, 6]
const OCCLUSION_LAYER := 0


func _run() -> void:
	for path in TILESETS:
		var tile_set := load(path) as TileSet
		if not tile_set:
			push_error("add_tile_occluders: can't load %s" % path)
			continue
		var count := setup_occluders(tile_set)
		var error := ResourceSaver.save(tile_set, path)
		print("add_tile_occluders: %s - %d blocking tiles, save %s" % [path, count, error_string(error)])


## Gives every solid tile in BLOCKING_SOURCES a full-tile occluder and clears
## all other occluders in BLOCKING_SOURCES and OPEN_SOURCES. A tile counts as
## solid when it has a collision polygon: the ceiling sources also hold
## non-solid pieces (row 1) that are drawn on the overlay layer on top of
## wall cells, and those must not block light. Returns how many tiles block.
static func setup_occluders(tile_set : TileSet) -> int:
	if tile_set.get_occlusion_layers_count() <= OCCLUSION_LAYER:
		tile_set.add_occlusion_layer()
	var half := Vector2(tile_set.tile_size) / 2.0
	var count := 0
	for source_id in BLOCKING_SOURCES + OPEN_SOURCES:
		if not tile_set.has_source(source_id):
			continue
		var source := tile_set.get_source(source_id) as TileSetAtlasSource
		if not source:
			continue
		var blocks := source_id in BLOCKING_SOURCES
		for i in source.get_tiles_count():
			var coords := source.get_tile_id(i)
			for a in source.get_alternative_tiles_count(coords):
				var data := source.get_tile_data(coords, source.get_alternative_tile_id(coords, a))
				var solid := tile_set.get_physics_layers_count() > 0 and data.get_collision_polygons_count(0) > 0
				if not (blocks and solid):
					data.set_occluder_polygons_count(OCCLUSION_LAYER, 0)
					continue
				var polygon := OccluderPolygon2D.new()
				polygon.polygon = PackedVector2Array([
					Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
					Vector2(half.x, half.y), Vector2(-half.x, half.y),
				])
				data.set_occluder_polygons_count(OCCLUSION_LAYER, 1)
				data.set_occluder_polygon(OCCLUSION_LAYER, 0, polygon)
				count += 1
	return count
