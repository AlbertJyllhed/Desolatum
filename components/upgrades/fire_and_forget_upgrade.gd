extends Upgrade

var player : Player


func apply_upgrade(upgrade_node):
	player = upgrade_node as Player
	player.stats.add_modifiers({ "damage" : -0.5, "firing_speed" : -0.2 }, "*")


func remove_upgrade():
	player.stats.add_modifiers({ "damage" : 0.5, "firing_speed" : 0.2 }, "*")
	super.remove_upgrade()
