extends Upgrade

var player : Player


func apply_upgrade(upgrade_node):
	player = upgrade_node as Player
	player.stats.add_modifiers({ "explode_chance" : 0.05 }, "+")


func remove_upgrade():
	player.stats.add_modifiers({ "explode_chance" : -0.05 }, "+")
	super.remove_upgrade()
