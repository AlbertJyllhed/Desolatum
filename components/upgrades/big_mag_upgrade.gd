extends Upgrade

var player : Player


func apply_upgrade(upgrade_node : Node2D):
	player = upgrade_node as Player
	player.stats.add_to_multiplier("ammo_mod", 0.2)
	player.stats.add_to_multiplier("reload_time", 0.1)


func remove_upgrade():
	player.stats.add_to_multiplier("ammo_mod", -0.2)
	player.stats.add_to_multiplier("reload_time", -0.1)
	super.remove_upgrade()
