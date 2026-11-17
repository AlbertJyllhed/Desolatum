extends Resource
class_name DirectorPhase

@export var max_enemies: int = 8
@export var spawn_time: float = 10.0
## Chance (0 to 1) that each dark spawner spawns an enemy on a spawn check.
@export_range(0.0, 1.0) var spawn_chance: float = 0.3
@export var min_duration: float = 30.0
@export var max_duration: float = 60.0
@export var aggressive: bool = false

@export_group("Burst")
## Enemies that pour out of the dark when this phase starts, on the first level.
## Still limited by max_enemies. 0 = no burst.
@export var burst_size: int = 0
## Extra burst enemies for each level deeper into the run.
@export var burst_per_depth: int = 0
## Seconds the burst takes to pour out.
@export var burst_duration: float = 2.0


## Burst size at [param depth] (1 = first level).
func get_burst_size(depth: int) -> int:
	return burst_size + burst_per_depth * maxi(depth - 1, 0)
