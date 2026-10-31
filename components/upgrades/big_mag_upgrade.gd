extends Upgrade


func apply_upgrade(_upgrade_node : Node2D) -> void:
	Run.state.add_modifiers({ "ammo" : 0.5, "reload_speed" : 0.4 }, "*")


func remove_upgrade() -> void:
	Run.state.add_modifiers({ "ammo" : -0.5, "reload_speed" : -0.4 }, "*")
	super.remove_upgrade()
