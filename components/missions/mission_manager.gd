extends Node
class_name MissionManager

var mission : Mission


func _ready():
	GameEvents.level_generated.connect(start_mission, CONNECT_ONE_SHOT)


func start_mission():
	var data : MissionData = Run.state.current_mission
	if data == null:
		# No mission picked (e.g. the level was run straight from the editor):
		# finishing any objective opens the exit, so the level stays playable.
		GameEvents.objective_done.connect(func(_objective): GameEvents.unlock_exit.emit(), CONNECT_ONE_SHOT)
		return

	mission = data.mission_scene.instantiate() as Mission
	add_child(mission)
	mission.start(get_tree().get_first_node_in_group("level_generator"))
