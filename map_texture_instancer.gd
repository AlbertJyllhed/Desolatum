extends Node2D
class_name MapTextureInstancer
## Stamps a pixel-art "prefab room" into the tilemap.
##
## Every opaque pixel of [member texture] is matched against
## [member color_instances] and becomes a tile (and optionally a scene).
## Transparent pixels are skipped, so whatever was already there stays.
##
## Usage (done by LevelGenerator):
##   var footprint := MapTextureInstancer.get_footprint(texture, center_cell)  # plan
##   instancer.stamp(tilemap, center_cell)    # writes tiles only
##   instancer.spawn_objects(base_layer)      # later, once the layout is accepted
##   instancer.queue_free()
##
## Splitting stamp() and spawn_objects() means a rejected layout can be thrown
## away without having instantiated (and having to clean up) any scenes.

const BASE_LAYER := 0
const OVERLAY_LAYER := 1

@export var texture: Texture2D
@export var color_instances: Array[ColorToInstance]

var _tilemap: TileMap
var _pending_objects: Array[Dictionary] = []  # each: {"scene": PackedScene, "cell": Vector2i}


## The rectangle of cells a prefab built from [param prefab_texture] covers when
## centered on [param center_cell]. Cheap: it never reads the image.
static func get_footprint(prefab_texture: Texture2D, center_cell: Vector2i) -> Rect2i:
	var size := Vector2i(prefab_texture.get_size())
	return Rect2i(center_cell - size / 2, size)


## Writes the prefab's tiles into [param tilemap]. Scenes are only remembered
## here; call spawn_objects() to actually create them.
func stamp(tilemap: TileMap, center_cell: Vector2i) -> void:
	_tilemap = tilemap
	_pending_objects.clear()

	if texture == null:
		push_warning("MapTextureInstancer has no texture assigned.")
		return

	var image := texture.get_image()
	if image == null:
		push_warning("Could not read an image from %s." % texture.resource_path)
		return
	if image.is_compressed():
		image.decompress()

	var lookup := _build_color_lookup()
	var origin := get_footprint(texture, center_cell).position
	var unmatched := {}  # "rrggbb" -> number of pixels

	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			if pixel.a == 0.0:
				continue

			var entry: ColorToInstance = lookup.get(pixel.to_rgba32(), null)
			if entry == null:
				var hex := pixel.to_html(false)
				unmatched[hex] = unmatched.get(hex, 0) + 1
				continue

			_place_tile(entry, origin + Vector2i(x, y))

	# One warning per unknown color instead of one per pixel. If you see these
	# for colors that *do* look right, check the texture's import settings
	# (use Lossless compression, not VRAM Compressed).
	for hex in unmatched:
		push_warning("%s: %d pixel(s) of color #%s match no ColorToInstance entry." % [
			texture.resource_path, unmatched[hex], hex
		])


## Instantiates the scenes collected by stamp() under [param parent].
func spawn_objects(parent: Node) -> void:
	for placement in _pending_objects:
		var scene: PackedScene = placement["scene"]
		var instance := scene.instantiate() as Node2D
		parent.add_child(instance)
		instance.global_position = _tilemap.to_global(_tilemap.map_to_local(placement["cell"]))
	_pending_objects.clear()


func _place_tile(entry: ColorToInstance, cell: Vector2i) -> void:
	var atlas_coords := Vector2i(
		randi_range(entry.min_x, entry.max_x),
		randi_range(entry.min_y, entry.max_y)
	)
	_tilemap.set_cell(BASE_LAYER, cell, entry.tile_id, atlas_coords)
	# A prefab replaces anything that was on the overlay layer (shadows, caps...).
	_tilemap.set_cell(OVERLAY_LAYER, cell, -1, Vector2i.ZERO)

	if entry.scene != null:
		_pending_objects.append({"scene": entry.scene, "cell": cell})


## color (as 32-bit int) -> ColorToInstance. If two entries share a color the
## first one wins, same as the old linear search.
func _build_color_lookup() -> Dictionary:
	var lookup := {}
	for entry in color_instances:
		if entry == null:
			continue
		var key := entry.color.to_rgba32()
		if not lookup.has(key):
			lookup[key] = entry
	return lookup
