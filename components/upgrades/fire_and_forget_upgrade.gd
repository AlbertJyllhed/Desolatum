extends Upgrade


func apply_upgrade(_upgrade_node: Node2D) -> void:
	Run.state.add_modifiers({ "damage" : -0.5, "firing_speed" : -0.2 }, "*")


func remove_upgrade() -> void:
	Run.state.add_modifiers({ "damage" : 0.5, "firing_speed" : 0.2 }, "*")
	super.remove_upgrade()
