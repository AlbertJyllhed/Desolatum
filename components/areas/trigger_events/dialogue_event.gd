extends TriggerEvent

@export var dialogue : Dialogue


func setup(new_trigger_area : TriggerArea, new_target_node : Node2D):
	super.setup(new_trigger_area, new_target_node)
	DialogueManager.dialogue_finished.connect(trigger_area.reset)


func trigger(new_player : Player):
	super.trigger(new_player)
	if not dialogue:
		print("error: no dialogue assigned!")
		return
	
	DialogueManager.start_dialogue(target_node.global_position, dialogue.text)
