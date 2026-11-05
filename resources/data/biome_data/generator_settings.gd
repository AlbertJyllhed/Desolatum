extends Resource
class_name GeneratorSettings

## Level generation settings a biome can change. Every property here must have a
## property of the same name on LevelGenerator; apply_to() copies them across.
## The defaults are the cave's values (the ones set in level_generator.tscn).

@export_group("Walkers")
@export_range(0.0, 1.0, 0.01) var walker_spawn_chance: float = 0.05
@export_range(0.0, 1.0, 0.01) var walker_destroy_chance: float = 0.05
@export_range(0.0, 1.0, 0.01) var walker_turn_chance: float = 0.25
@export var max_steps_until_turn: int = 10
@export var max_walkers: int = 4
@export var walkers_can_u_turn: bool = true
@export_range(1, 3, 1, "or_greater") var path_width: int = 2
@export var scale_turns_with_path_width: bool = true

@export_group("Smoothing")
@export_range(0, 3) var smoothing_passes: int = 1

@export_group("Rooms")
@export_range(0.0, 1.0, 0.01) var room_chance: float = 0.6
@export var min_room_size_x: int = 2
@export var min_room_size_y: int = 2
@export var max_room_size_x: int = 3
@export var max_room_size_y: int = 3
@export var min_room_spacing: int = 4


func apply_to(generator: LevelGenerator) -> void:
	for property in get_property_list():
		if not property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			continue
		if not property.name in generator:
			push_error("GeneratorSettings: LevelGenerator has no property '%s'" % property.name)
			continue
		generator.set(property.name, get(property.name))
