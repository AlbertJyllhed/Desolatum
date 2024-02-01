extends Upgrade

var player : Player


func apply_upgrade(upgrade_node):
	player = upgrade_node as Player
	player.stats.add_modifiers({ "damage" : 2, "health" : -2 }, "+")


func remove_upgrade():
	player.stats.add_modifiers({ "damage" : -2, "health" : 2 }, "+")
	super.remove_upgrade()
