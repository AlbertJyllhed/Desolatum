extends Upgrade

var player : Player


func apply_upgrade(upgrade_node : Node2D):
	player = upgrade_node as Player
	player.stats.add_modifiers({ "crit_chance" : 0.15 }, "+")


func remove_upgrade():
	player.stats.add_modifiers({ "crit_chance" : -0.15 }, "+")
	super.remove_upgrade()
