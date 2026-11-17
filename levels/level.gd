extends Node
class_name Level

## Root of the shared level scene. Dresses the level up as the current biome
## (tiles, tint, particles, generator settings) before anything is generated.

## Used when the level wasn't entered from the map, e.g. when you run this
## scene straight from the editor. Swap it to test another biome.
@export var preview_biome : BiomeData
## Use preview_biome even inside a run. Together with a fixed seed on the
## LevelGenerator (Randomize Seed off) this reproduces a level exactly.
@export var force_preview_biome : bool = false

@export var level_generator : LevelGenerator
@export var ground_layer : TileMapLayer
@export var overlay_layer : TileMapLayer
@export var canvas_modulate : CanvasModulate

var biome : BiomeData


## _enter_tree runs before any child's _ready, so the LevelGenerator already
## sees the biome's settings when it generates in its own _ready.
func _enter_tree() -> void:
	if biome != null:
		return # already applied (the node re-entered the tree)

	if force_preview_biome and preview_biome:
		biome = preview_biome
	elif Run.state and Run.state.current_biome:
		biome = Run.state.current_biome
	else:
		biome = preview_biome
	if biome == null:
		push_warning("Level: no biome to apply, using the scene as it is")
		return
	_apply(biome)


## Runs after every child is ready, so all level_generated listeners are connected.
func _ready() -> void:
	var level_seed : int = Run.state.get_level_seed() if Run.state else -1
	level_generator.start(level_seed)


func _apply(data : BiomeData) -> void:
	if data.tile_set:
		ground_layer.tile_set = data.tile_set
		overlay_layer.tile_set = data.tile_set
	canvas_modulate.color = data.ambient_color
	if data.ambient_particles:
		level_generator.dust_scene = data.ambient_particles
	if data.generator_settings:
		data.generator_settings.apply_to(level_generator)
	if data.calm_music:
		MusicPlayer.play(data.calm_music, data.combat_music)
