extends Resource
class_name BiomeData

## Everything that makes one biome's levels different. All biomes share the
## level scene (levels/main.tscn); Level applies this to it on load.

@export var name : String
@export var icon : Texture2D

@export_group("Look")
@export var tile_set : TileSet
## Colour of the level's CanvasModulate (the darkness tint).
@export var ambient_color : Color = Color.WHITE
## Spawned around the level for atmosphere (dust, fireflies...). Leave empty to
## keep the LevelGenerator's default.
@export var ambient_particles : PackedScene

@export_group("Music")
## Played on loop in this biome's levels. Leave empty to keep whatever is playing.
@export var calm_music : AudioStream
## Optional. Plays in sync with calm_music; enemy waves crossfade to it.
## Must be the same length as calm_music.
@export var combat_music : AudioStream

@export_group("Generation")
## Leave empty to use the LevelGenerator's own values.
@export var generator_settings : GeneratorSettings

@export_group("Scene")
## Only for biomes that need a hand-built scene of their own (a boss arena, say).
## Leave empty to use the shared level scene.
@export_file("*.tscn") var scene_override : String
