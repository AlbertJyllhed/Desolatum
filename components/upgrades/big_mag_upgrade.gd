extends Upgrade

var player : Player


func apply_upgrade(upgrade_node : Node2D):
	player = upgrade_node as Player
	player.stats.add_modifiers({ "ammo" : 0.2, "reload_speed" : 0.1 }, "*")


func remove_upgrade():
	player.stats.add_modifiers({ "ammo" : -0.2, "reload_speed" : -0.1 }, "*")
	super.remove_upgrade()
