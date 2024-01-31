extends Upgrade

var player : Player


func apply_upgrade(upgrade_node : Node2D):
	player = upgrade_node as Player
	player.stats.add_modifiers({ "ammo" : 0.5, "reload_speed" : 0.4 }, "*")


func remove_upgrade():
	player.stats.add_modifiers({ "ammo" : -0.5, "reload_speed" : -0.4 }, "*")
	super.remove_upgrade()
