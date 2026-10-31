extends Upgrade


func apply_upgrade(_upgrade_node : Node2D) -> void:
	Run.state.add_modifiers({ "crit_chance" : 0.15 }, "+")


func remove_upgrade() -> void:
	Run.state.add_modifiers({ "crit_chance" : -0.15 }, "+")
	super.remove_upgrade()
