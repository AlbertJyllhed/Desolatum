extends Node
class_name MusicCue

## Drop this into a scene to tell the MusicPlayer what to play there, for scenes
## that aren't biome levels (biome levels take their music from BiomeData).
## If the same song is already playing, it just carries on.

@export var calm_music: AudioStream
## Optional. Played in sync with calm_music; enemy waves crossfade to it.
## Must be the same length as calm_music.
@export var combat_music: AudioStream


func _ready() -> void:
	MusicPlayer.play(calm_music, combat_music)
