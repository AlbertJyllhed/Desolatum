extends Node2D
class_name LightMap

## Stepped, palette-exact lighting. Add one LightMap to a scene (next to the
## CanvasModulate) and it does the rest at runtime:
## - A SubViewport that shares this scene's world draws only a white
##   "receiver" rect over the view. Every light lights only that rect, so the
##   viewport ends up holding the combined light, shadows included.
## - A full-screen composite rect (above the world, below the UI) bands that
##   light and colours the scene with a palette that runs from the darkness
##   colour (the CanvasModulate's) to the light colour (light_color global).
## - The CanvasModulate is hidden, since the composite does the darkening.
## Sprites that should glow in the dark get a LightGlowComponent.
## - Ceiling tiles (and the ceiling lips on the overlay layer) ignore light:
##   a hidden copy of them is drawn into the light
##   map as a mask, and the composite keeps those pixels at the darkness
##   colour (overhang included). The copy is filled once when the level is
##   generated and then updated cell by cell when tiles break.
## - Overlay tiles with the "glows" custom data (ore on the ceiling) keep their
##   own colour in the dark: another hidden copy draws them into the light map
##   as glowing, on top of the ceiling's mask. Updated the same way.
## - Shadows (every Sprite2D named "Shadow" and the wall shadow tiles,
##   Tiles.Id.SHADOW) aren't drawn in the main view. Copies of their shapes
##   mark "in shadow" in the light map's alpha channel instead, and the
##   composite turns marked lit pixels into the dimmest light band. Overlaps
##   never stack, and in darkness shadows don't show at all.
##   Copies of what stands on top of shadows clear the mark again: the
##   sprites of anything that has a shadow (player, held weapons, enemies,
##   props) and the wall tiles, so the player isn't darkened by a wall shadow.

const RECEIVER_SHADER := preload("res://resources/shaders/light_map_receiver.gdshader")
const COMPOSITE_SHADER := preload("res://resources/shaders/light_composite.gdshader")
const UNLIT_MASK_SHADER := preload("res://resources/shaders/light_unlit_mask.gdshader")
const GLOW_TILES_SHADER := preload("res://resources/shaders/light_glow_tiles.gdshader")
const SHADOW_MASK_SHADER := preload("res://resources/shaders/light_shadow_mask.gdshader")
const SHADOW_CLEAR_SHADER := preload("res://resources/shaders/light_shadow_clear.gdshader")
## Sprites with this name are shadows (see the player, enemies and props).
const SHADOW_NODE_NAME := &"Shadow"
## Shadow copies are drawn after everything else in the light map (ceiling
## mask, glows), since they mark what is already there...
const SHADOW_Z := 1000
## ...and what stands on top of them is drawn after that, to clear the mark.
## Wall tiles add their own z index (10) to this.
const SHADOW_CLEAR_Z := 1100
## Tile custom data (bool) that makes an overlay tile glow.
const GLOWS_DATA := "glows"

## Visibility layer 20: things only the light map draws (the receiver).
const RECEIVER_LAYER := 1 << 19
## Visibility layer 19: glow shapes, also only drawn by the light map.
const GLOW_LAYER := 1 << 18
## Light mask the lights are switched to, so they only light the receiver.
const RECEIVER_LIGHT_MASK := 1 << 19
## Godot only draws a light's shadows on items whose light mask matches the
## light's shadow mask (layer 1 by default), so the receiver has that bit too.
## No light lights layer 1 any more, so it isn't lit twice.
const SHADOW_LIGHT_MASK := 1
## The composite is drawn above every world item.
const COMPOSITE_Z := RenderingServer.CANVAS_ITEM_Z_MAX

## The scene's darkness. Its colour becomes the palette's dark end, and it's
## hidden while the LightMap runs.
@export var canvas_modulate : CanvasModulate

@export_group("Unlit Tiles")
## Tile layer holding the ceilings. Uses the "tilemap_layer" group if empty.
@export var tile_layer : TileMapLayer
## Overlay tile layer holding the ceiling lips drawn over the walls. Uses the
## "tile_overlay" group if empty.
@export var overlay_layer : TileMapLayer
## Tile sources that are never lit (see Tiles.Id): ceiling, bedrock, ship ceiling.
@export var unlit_sources : Array[int] = [1, 3, 7]
## Tile sources drawn on top of shadows, which clear them (see Tiles.Id):
## wall, ship wall.
@export var shadow_clear_sources : Array[int] = [2, 6]

@export_group("Glowing Tiles")
## How bright glowing tiles (ore on the ceiling) are in the dark, snapped to
## the nearest light band. 1 = their full colour, like glowing sprites.
@export_range(0.0, 1.0, 0.01) var tile_glow_strength : float = 0.67:
	set(value):
		tile_glow_strength = value
		if is_instance_valid(_glow_copy):
			(_glow_copy.material as ShaderMaterial).set_shader_parameter(&"glow_strength", value)

var _viewport : SubViewport
## Source tile layer -> its copy of the unlit tiles, which only the light map
## draws. One copy per layer, since both layers can have a tile in one cell.
var _unlit_copies : Dictionary[TileMapLayer, TileMapLayer] = {}
## Copy of the overlay layer's glowing tiles, which only the light map draws.
var _glow_copy : TileMapLayer
var _receiver : ColorRect
var _composite : ColorRect
## Parent for the glow shapes made by LightGlowComponents.
var glow_root : Node2D
var _main_cull_mask : int
## Parent of the shadow sprites' copies, which mark "in shadow".
var _shadow_root : Node2D
## Parent of the copies of sprites standing on top of shadows, which clear it.
var _shadow_clear_root : Node2D
var _shadow_mask_material : ShaderMaterial
var _shadow_clear_material : ShaderMaterial
## Sprite (Sprite2D or AnimatedSprite2D) -> its copy in the light map. Shadow
## sprites' copies mark, everything else's clear.
var _sprite_copies : Dictionary[Node2D, Node2D] = {}
## Shadow sprite -> its visibility layer before it was hidden from the main view.
var _shadow_old_layers : Dictionary[Node2D, int] = {}
## Nodes that own a shadow (its scene's root). Their sprites clear shadows.
var _shadow_owners : Dictionary[Node, bool] = {}
## Tile layer with wall shadow tiles -> its copy of them in the light map.
var _shadow_tile_copies : Dictionary[TileMapLayer, TileMapLayer] = {}
## The copies' own tile set per source tile set (holding just the shadow
## tiles), so hiding the real shadow tiles doesn't hide the copies.
var _shadow_tile_sets : Dictionary[TileSet, TileSet] = {}
## Wall shadow tiles hidden from the main view -> their modulate before.
var _shadow_tiles_old_modulate : Dictionary[TileData, Color] = {}
## Copy of the wall tiles, which clear shadows under them.
var _wall_clear_copy : TileMapLayer


func _ready() -> void:
	add_to_group(&"light_map")

	# The receiver and glow shapes are children of the SubViewport. It shares
	# this scene's world, so they're drawn in the same canvas as everything
	# else, but they have no CanvasItem parents. That matters because a canvas
	# item is only drawn if it and all its parents share a layer with the
	# viewport: only the light map should see them.
	_viewport = SubViewport.new()
	_viewport.name = "LightViewport"
	_viewport.world_2d = get_viewport().world_2d
	_viewport.canvas_cull_mask = RECEIVER_LAYER | GLOW_LAYER
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.disable_3d = true
	# Keeps the alpha channel, which holds the "in shadow" mark.
	_viewport.transparent_bg = true
	add_child(_viewport)

	_receiver = _make_rect("Receiver", RECEIVER_SHADER)
	_receiver.visibility_layer = RECEIVER_LAYER
	_receiver.light_mask = RECEIVER_LIGHT_MASK | SHADOW_LIGHT_MASK
	_viewport.add_child(_receiver)

	glow_root = Node2D.new()
	glow_root.name = "Glow"
	glow_root.visibility_layer = GLOW_LAYER
	glow_root.light_mask = 0
	_viewport.add_child(glow_root)

	_shadow_mask_material = ShaderMaterial.new()
	_shadow_mask_material.shader = SHADOW_MASK_SHADER
	_shadow_clear_material = ShaderMaterial.new()
	_shadow_clear_material.shader = SHADOW_CLEAR_SHADER
	_shadow_root = _make_copy_root("Shadows", SHADOW_Z)
	_shadow_clear_root = _make_copy_root("ShadowClearers", SHADOW_CLEAR_Z)

	_setup_unlit_tiles()

	_composite = _make_rect("Composite", COMPOSITE_SHADER)
	_composite.visibility_layer = 1
	_composite.light_mask = 0
	_composite.z_index = COMPOSITE_Z
	_composite.z_as_relative = false
	add_child(_composite)

	# Keep the main view from drawing the receiver and glow shapes.
	_main_cull_mask = get_viewport().canvas_cull_mask
	get_viewport().canvas_cull_mask = _main_cull_mask & ~(RECEIVER_LAYER | GLOW_LAYER)

	if canvas_modulate:
		canvas_modulate.visible = false

	for light in get_tree().root.find_children("*", "Light2D", true, false):
		_retarget_light(light)
	for shadow in get_tree().root.find_children(SHADOW_NODE_NAME, "Sprite2D", true, false):
		_add_shadow_sprite(shadow as Sprite2D)
	get_tree().node_added.connect(_on_node_added)
	RenderingServer.global_shader_parameter_set(&"light_map", _viewport.get_texture())
	RenderingServer.frame_pre_draw.connect(_sync)
	_sync()


func _exit_tree() -> void:
	if RenderingServer.frame_pre_draw.is_connected(_sync):
		RenderingServer.frame_pre_draw.disconnect(_sync)
	if get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.disconnect(_on_node_added)
	if GameEvents.level_generated.is_connected(_refresh_all_unlit_tiles):
		GameEvents.level_generated.disconnect(_refresh_all_unlit_tiles)
	if GameEvents.navigation_updated.is_connected(_on_navigation_updated):
		GameEvents.navigation_updated.disconnect(_on_navigation_updated)
	get_viewport().canvas_cull_mask = _main_cull_mask
	if is_instance_valid(canvas_modulate):
		canvas_modulate.visible = true
	_restore_shadows()


## The LightMap in the scene, or null if there is none.
static func find(tree : SceneTree) -> LightMap:
	return tree.get_first_node_in_group(&"light_map") as LightMap


func _make_copy_root(root_name : String, z : int) -> Node2D:
	var root := Node2D.new()
	root.name = root_name
	root.visibility_layer = GLOW_LAYER
	root.light_mask = 0
	root.z_index = z
	root.z_as_relative = false
	_viewport.add_child(root)
	return root


func _make_rect(rect_name : String, shader : Shader) -> ColorRect:
	var rect := ColorRect.new()
	rect.name = rect_name
	rect.color = Color.WHITE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material_instance := ShaderMaterial.new()
	material_instance.shader = shader
	rect.material = material_instance
	return rect


func _setup_unlit_tiles() -> void:
	if not tile_layer:
		tile_layer = get_tree().get_first_node_in_group(&"tilemap_layer") as TileMapLayer
	if not overlay_layer:
		overlay_layer = get_tree().get_first_node_in_group(&"tile_overlay") as TileMapLayer
	if tile_layer:
		_unlit_copies[tile_layer] = _make_tile_copy("UnlitTiles", UNLIT_MASK_SHADER)
	if overlay_layer and overlay_layer != tile_layer:
		_unlit_copies[overlay_layer] = _make_tile_copy("UnlitOverlay", UNLIT_MASK_SHADER)
		_glow_copy = _make_tile_copy("GlowOverlay", GLOW_TILES_SHADER)
		tile_glow_strength = tile_glow_strength  # pass it to the shader
	if tile_layer:
		_wall_clear_copy = _make_tile_copy("ShadowClearWalls", SHADOW_CLEAR_SHADER)
		_wall_clear_copy.material = _shadow_clear_material
		_wall_clear_copy.z_index = SHADOW_CLEAR_Z
		_wall_clear_copy.z_as_relative = false
	# Wall shadow tiles can be on any layer (the ship has its own ShadowLayer).
	for layer in get_tree().root.find_children("*", "TileMapLayer", true, false):
		var source_layer := layer as TileMapLayer
		if _viewport.is_ancestor_of(source_layer) or not source_layer.tile_set \
				or not source_layer.tile_set.has_source(Tiles.Id.SHADOW):
			continue
		var copy := _make_tile_copy("ShadowTiles", SHADOW_MASK_SHADER)
		copy.material = _shadow_mask_material
		copy.z_index = SHADOW_Z
		copy.z_as_relative = false
		_shadow_tile_copies[source_layer] = copy
	if _unlit_copies.is_empty() and _shadow_tile_copies.is_empty():
		return

	# A full copy costs a few ms, so it only happens when the whole map is
	# new (level generated, or right away for fixed maps like the ship).
	# Broken tiles only update their own cells.
	GameEvents.level_generated.connect(_refresh_all_unlit_tiles)
	GameEvents.navigation_updated.connect(_on_navigation_updated)
	_refresh_all_unlit_tiles.call_deferred()


func _make_tile_copy(copy_name : String, shader : Shader) -> TileMapLayer:
	var copy := TileMapLayer.new()
	copy.name = copy_name
	copy.visibility_layer = GLOW_LAYER
	copy.light_mask = 0
	# Only a picture: no second set of collisions, occluders or navigation.
	copy.collision_enabled = false
	copy.occlusion_enabled = false
	copy.navigation_enabled = false
	var material_instance := ShaderMaterial.new()
	material_instance.shader = shader
	copy.material = material_instance
	_viewport.add_child(copy)
	return copy


## Copies every unlit tile from each source layer.
func _refresh_all_unlit_tiles() -> void:
	_refresh_all_shadow_tiles()
	for layer : TileMapLayer in _unlit_copies:
		if not is_instance_valid(layer):
			continue
		var copy : TileMapLayer = _unlit_copies[layer]
		copy.tile_set = layer.tile_set
		copy.clear()
		for source_id in unlit_sources:
			for cell in layer.get_used_cells_by_id(source_id):
				copy.set_cell(cell, source_id, layer.get_cell_atlas_coords(cell), layer.get_cell_alternative_tile(cell))

	if is_instance_valid(_glow_copy) and is_instance_valid(overlay_layer):
		_glow_copy.tile_set = overlay_layer.tile_set
		_glow_copy.clear()
		for cell in overlay_layer.get_used_cells():
			_refresh_glow_cell(cell)


## A tile broke (or a prop moved): refresh that cell and its neighbours, since
## breaking a tile also changes the ceiling above it and the lip below it.
func _on_navigation_updated(cell : Vector2i, _value : bool) -> void:
	for y in range(-1, 2):
		for x in range(-1, 2):
			var neighbor := cell + Vector2i(x, y)
			for layer : TileMapLayer in _unlit_copies:
				if is_instance_valid(layer):
					_refresh_unlit_cell(layer, _unlit_copies[layer], neighbor)
			if is_instance_valid(_glow_copy) and is_instance_valid(overlay_layer):
				_refresh_glow_cell(neighbor)
			for layer : TileMapLayer in _shadow_tile_copies:
				if is_instance_valid(layer):
					_refresh_shadow_cell(layer, _shadow_tile_copies[layer], neighbor)
			if is_instance_valid(_wall_clear_copy) and is_instance_valid(tile_layer):
				_refresh_wall_clear_cell(neighbor)


## Copies the overlay tile at [param cell] into the glow copy if it glows,
## otherwise clears that cell of the copy.
func _refresh_glow_cell(cell : Vector2i) -> void:
	var tile_set := overlay_layer.tile_set
	var tile_data := overlay_layer.get_cell_tile_data(cell)
	var glows := tile_data != null and tile_set.get_custom_data_layer_by_name(GLOWS_DATA) >= 0 \
		and bool(tile_data.get_custom_data(GLOWS_DATA))
	if glows:
		_glow_copy.set_cell(cell, overlay_layer.get_cell_source_id(cell), overlay_layer.get_cell_atlas_coords(cell), overlay_layer.get_cell_alternative_tile(cell))
	elif _glow_copy.get_cell_source_id(cell) != -1:
		_glow_copy.erase_cell(cell)


func _refresh_unlit_cell(layer : TileMapLayer, copy : TileMapLayer, cell : Vector2i) -> void:
	var source_id := layer.get_cell_source_id(cell)
	if source_id in unlit_sources:
		copy.set_cell(cell, source_id, layer.get_cell_atlas_coords(cell), layer.get_cell_alternative_tile(cell))
	elif copy.get_cell_source_id(cell) != -1:
		copy.erase_cell(cell)


func _on_node_added(node : Node) -> void:
	if node is Light2D:
		_retarget_light(node)
	elif node is Sprite2D and node.name == SHADOW_NODE_NAME:
		_add_shadow_sprite(node as Sprite2D)
	elif (node is Sprite2D or node is AnimatedSprite2D) and _has_shadow_owner(node):
		# e.g. a weapon picked up after the player's shadow was found.
		_add_sprite_copy(node as Node2D, _shadow_clear_root, _shadow_clear_material)


func _retarget_light(light : Light2D) -> void:
	light.range_item_cull_mask = RECEIVER_LIGHT_MASK


## Hides a shadow sprite from the main view and draws a copy of its shape
## into the light map instead. The sprites of whatever owns the shadow get
## copies that clear it.
func _add_shadow_sprite(shadow : Sprite2D) -> void:
	if _sprite_copies.has(shadow):
		return
	_add_sprite_copy(shadow, _shadow_root, _shadow_mask_material)
	_shadow_old_layers[shadow] = shadow.visibility_layer
	shadow.visibility_layer = 0

	# The shadow's scene root (the player, an enemy, a prop). Not the level
	# itself, in case a shadow sits directly in it.
	var shadow_owner : Node = shadow.owner
	if not shadow_owner or shadow_owner == get_tree().current_scene:
		shadow_owner = shadow.get_parent()
	if not shadow_owner or _shadow_owners.has(shadow_owner):
		return
	_shadow_owners[shadow_owner] = true
	shadow_owner.tree_exiting.connect(_on_shadow_owner_exiting.bind(shadow_owner), CONNECT_ONE_SHOT)
	var sprites : Array[Node] = [shadow_owner]
	sprites.append_array(shadow_owner.find_children("*", "Node2D", true, false))
	for node in sprites:
		if (node is Sprite2D or node is AnimatedSprite2D) and node.name != SHADOW_NODE_NAME:
			_add_sprite_copy(node as Node2D, _shadow_clear_root, _shadow_clear_material)


func _on_shadow_owner_exiting(shadow_owner : Node) -> void:
	_shadow_owners.erase(shadow_owner)


## True if [param node] is inside something that owns a shadow.
func _has_shadow_owner(node : Node) -> bool:
	if node.name == SHADOW_NODE_NAME:
		return false
	var ancestor := node
	while ancestor:
		if _shadow_owners.has(ancestor):
			return true
		ancestor = ancestor.get_parent()
	return false


func _add_sprite_copy(sprite : Node2D, parent : Node2D, copy_material : ShaderMaterial) -> void:
	if _sprite_copies.has(sprite):
		return
	var copy : Node2D = AnimatedSprite2D.new() if sprite is AnimatedSprite2D else Sprite2D.new()
	copy.name = "%s_copy" % sprite.name
	copy.visibility_layer = GLOW_LAYER
	copy.light_mask = 0
	copy.material = copy_material
	parent.add_child(copy)
	_sprite_copies[sprite] = copy
	# Pooled or moved nodes come back through node_added.
	sprite.tree_exiting.connect(_remove_sprite_copy.bind(sprite), CONNECT_ONE_SHOT)
	_sync_sprite_copy(sprite, copy)


## Frees a sprite's copy, and lets the main view draw a shadow again.
func _remove_sprite_copy(sprite : Node2D) -> void:
	if not _sprite_copies.has(sprite):
		return
	var copy : Node2D = _sprite_copies[sprite]
	if is_instance_valid(copy):
		copy.queue_free()
	_sprite_copies.erase(sprite)
	if _shadow_old_layers.has(sprite):
		(sprite as Sprite2D).visibility_layer = _shadow_old_layers[sprite]
		_shadow_old_layers.erase(sprite)


## Copies a sprite's look and place. A sprite faded out by its own modulate
## (e.g. a burrowed enemy's shadow) counts as hidden.
func _sync_sprite_copy(sprite : Node2D, copy : Node2D) -> void:
	copy.visible = sprite.is_visible_in_tree() and sprite.modulate.a * sprite.self_modulate.a > 0.01
	copy.global_transform = sprite.global_transform
	if sprite is Sprite2D:
		var source := sprite as Sprite2D
		var target := copy as Sprite2D
		target.texture = source.texture
		target.hframes = source.hframes
		target.vframes = source.vframes
		target.frame = source.frame
		target.region_enabled = source.region_enabled
		target.region_rect = source.region_rect
		target.centered = source.centered
		target.offset = source.offset
		target.flip_h = source.flip_h
		target.flip_v = source.flip_v
	elif sprite is AnimatedSprite2D:
		var source := sprite as AnimatedSprite2D
		var target := copy as AnimatedSprite2D
		target.sprite_frames = source.sprite_frames
		target.animation = source.animation
		target.frame = source.frame
		target.centered = source.centered
		target.offset = source.offset
		target.flip_h = source.flip_h
		target.flip_v = source.flip_v


## Copies every wall shadow tile and every wall tile (which clears shadows),
## and hides the real shadow tiles from the main view (the tile set can
## change when a level is generated).
func _refresh_all_shadow_tiles() -> void:
	for layer : TileMapLayer in _shadow_tile_copies:
		if not is_instance_valid(layer) or not layer.tile_set:
			continue
		var copy : TileMapLayer = _shadow_tile_copies[layer]
		copy.tile_set = _get_shadow_tile_set(layer.tile_set)
		copy.clear()
		_hide_shadow_tiles(layer.tile_set)
		for cell in layer.get_used_cells_by_id(Tiles.Id.SHADOW):
			copy.set_cell(cell, Tiles.Id.SHADOW, layer.get_cell_atlas_coords(cell))

	if is_instance_valid(_wall_clear_copy) and is_instance_valid(tile_layer):
		_wall_clear_copy.tile_set = tile_layer.tile_set
		_wall_clear_copy.clear()
		for source_id in shadow_clear_sources:
			for cell in tile_layer.get_used_cells_by_id(source_id):
				_wall_clear_copy.set_cell(cell, source_id, tile_layer.get_cell_atlas_coords(cell), tile_layer.get_cell_alternative_tile(cell))


func _refresh_shadow_cell(layer : TileMapLayer, copy : TileMapLayer, cell : Vector2i) -> void:
	if layer.get_cell_source_id(cell) == Tiles.Id.SHADOW:
		copy.set_cell(cell, Tiles.Id.SHADOW, layer.get_cell_atlas_coords(cell))
	elif copy.get_cell_source_id(cell) != -1:
		copy.erase_cell(cell)


func _refresh_wall_clear_cell(cell : Vector2i) -> void:
	var source_id := tile_layer.get_cell_source_id(cell)
	if source_id in shadow_clear_sources:
		_wall_clear_copy.set_cell(cell, source_id, tile_layer.get_cell_atlas_coords(cell), tile_layer.get_cell_alternative_tile(cell))
	elif _wall_clear_copy.get_cell_source_id(cell) != -1:
		_wall_clear_copy.erase_cell(cell)


## A tile set holding only [param source_tile_set]'s wall shadow tiles, with
## their own tile data, for the shadow copies.
func _get_shadow_tile_set(source_tile_set : TileSet) -> TileSet:
	if _shadow_tile_sets.has(source_tile_set):
		return _shadow_tile_sets[source_tile_set]
	var tile_set := TileSet.new()
	tile_set.tile_size = source_tile_set.tile_size
	var source := source_tile_set.get_source(Tiles.Id.SHADOW) as TileSetAtlasSource
	if source:
		var copy_source := TileSetAtlasSource.new()
		copy_source.texture = source.texture
		copy_source.texture_region_size = source.texture_region_size
		copy_source.margins = source.margins
		copy_source.separation = source.separation
		tile_set.add_source(copy_source, Tiles.Id.SHADOW)
		for i in source.get_tiles_count():
			var coords := source.get_tile_id(i)
			copy_source.create_tile(coords, source.get_tile_size_in_atlas(coords))
	_shadow_tile_sets[source_tile_set] = tile_set
	return tile_set


## Makes the wall shadow tiles in [param tile_set] invisible in the main view.
func _hide_shadow_tiles(tile_set : TileSet) -> void:
	var source := tile_set.get_source(Tiles.Id.SHADOW) as TileSetAtlasSource
	if not source:
		return
	for i in source.get_tiles_count():
		var coords := source.get_tile_id(i)
		for j in source.get_alternative_tiles_count(coords):
			var tile_data := source.get_tile_data(coords, source.get_alternative_tile_id(coords, j))
			if tile_data and not _shadow_tiles_old_modulate.has(tile_data):
				_shadow_tiles_old_modulate[tile_data] = tile_data.modulate
				tile_data.modulate = Color(1.0, 1.0, 1.0, 0.0)


## Shows the shadows normally again, since the tile sets (and any sprite that
## outlives this scene) are used where there may be no LightMap.
func _restore_shadows() -> void:
	# Untyped keys: a freed sprite can't be put in a typed variable.
	for key in _sprite_copies.keys():
		if is_instance_valid(key):
			_remove_sprite_copy(key as Node2D)
		elif is_instance_valid(_sprite_copies[key]):
			_sprite_copies[key].queue_free()
	_sprite_copies.clear()
	_shadow_old_layers.clear()
	_shadow_owners.clear()
	for tile_data : TileData in _shadow_tiles_old_modulate:
		if is_instance_valid(tile_data):
			tile_data.modulate = _shadow_tiles_old_modulate[tile_data]
	_shadow_tiles_old_modulate.clear()


## Runs right before each frame is drawn, after the camera (and its shake)
## has moved: lines the light map and both rects up with the view.
func _sync() -> void:
	var main := get_viewport()
	var view_size : Vector2 = main.get_visible_rect().size
	var canvas_transform : Transform2D = main.canvas_transform
	var origin : Vector2 = canvas_transform.affine_inverse() * Vector2.ZERO

	_viewport.size = Vector2i(view_size)
	_viewport.canvas_transform = canvas_transform
	for rect : ColorRect in [_receiver, _composite]:
		rect.global_position = origin
		rect.size = view_size
	for layer : TileMapLayer in _unlit_copies:
		if is_instance_valid(layer):
			_unlit_copies[layer].global_transform = layer.global_transform
	if is_instance_valid(_glow_copy) and is_instance_valid(overlay_layer):
		_glow_copy.global_transform = overlay_layer.global_transform
	for layer : TileMapLayer in _shadow_tile_copies:
		if is_instance_valid(layer):
			_shadow_tile_copies[layer].global_transform = layer.global_transform
	if is_instance_valid(_wall_clear_copy) and is_instance_valid(tile_layer):
		_wall_clear_copy.global_transform = tile_layer.global_transform
	for key in _sprite_copies:
		if is_instance_valid(key):
			_sync_sprite_copy(key as Node2D, _sprite_copies[key])

	if canvas_modulate:
		RenderingServer.global_shader_parameter_set(&"light_ambient_color", canvas_modulate.color)
