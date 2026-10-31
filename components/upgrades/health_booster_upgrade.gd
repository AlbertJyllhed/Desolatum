extends Upgrade


func apply_upgrade(_upgrade_node: Node2D) -> void:
	Run.state.add_modifiers({ "health" : 1 }, "+")


func remove_upgrade() -> void:
	Run.state.add_modifiers({ "health" : -1 }, "+")
	super.remove_upgrade()
