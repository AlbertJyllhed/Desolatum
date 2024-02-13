extends TriggerEvent

@export var dialogue : Dialogue


func setup(handler : EventHandlerComponent, new_target_node : Node2D):
	super.setup(handler, new_target_node)
	DialogueManager.dialogue_finished.connect(handler.reset)


func trigger(new_player : Player):
	super.trigger(new_player)
	if not dialogue:
		print("error: no dialogue assigned!")
		return
	
	DialogueManager.start_dialogue(target_node.global_position, dialogue.text)
