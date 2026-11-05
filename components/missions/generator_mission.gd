extends Mission
class_name GeneratorMission

## Uses the generator the LevelGenerator already placed in the room farthest
## from the start, instead of spawning a new one at a random spot.

var generator : Generator


func start(level_generator : LevelGenerator) -> void:
	generator = level_generator.generator
	if generator == null:
		push_error("GeneratorMission: the level has no generator. Is 'mission_uses_generator' off on the LevelGenerator?")
		return
	GameEvents.objective_done.connect(on_objective_done)


func on_objective_done(objective) -> void:
	if objective != generator:
		return
	GameEvents.mission_progress.emit(self)
	complete()
