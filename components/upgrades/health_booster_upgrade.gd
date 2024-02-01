extends Upgrade

var player : Player


func apply_upgrade(upgrade_node):
	player = upgrade_node as Player
	player.stats.add_modifiers({ "health" : 1 }, "+")


func remove_upgrade():
	player.stats.add_modifiers({ "health" : -1 }, "+")
	super.remove_upgrade()
