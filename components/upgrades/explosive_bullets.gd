extends Upgrade


func apply_upgrade(upgrade_node):
	Run.state.add_modifiers({ "explode_chance" : 0.05 }, "+")


func remove_upgrade():
	Run.state.add_modifiers({ "explode_chance" : -0.05 }, "+")
	super.remove_upgrade()
