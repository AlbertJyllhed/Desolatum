extends Node

var config: PlayerConfig = preload("uid://ffwhqkje216k")
var state: RunState


func _ready() -> void:
	if not SaveManager.load_game():
		new_run()


func new_run() -> void:
	_set_state(RunState.new(config))
	GameEvents.reset_stats.emit() # DropList/EnemyList still rebuild on this


func load_run(data: Dictionary) -> void:
	_set_state(RunState.from_dict(config, data))
	GameEvents.reset_stats.emit()


func _set_state(new_state: RunState) -> void:
	if state:
		GameEvents.item_picked_up.disconnect(state.on_item_picked_up)
	state = new_state
	GameEvents.item_picked_up.connect(state.on_item_picked_up)
