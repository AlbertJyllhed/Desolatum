extends Mission

@export var objective_scene : PackedScene
@export var objective_amount : int = 3

var done : int = 0


func start(level_generator : LevelGenerator):
	level_generator.place_objectives(objective_scene, objective_amount)
	GameEvents.objective_done.connect(on_objective_done)


func on_objective_done(_objective):
	done += 1
	GameEvents.mission_progress.emit(self)
	if done >= objective_amount:
		complete()
