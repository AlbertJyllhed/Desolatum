extends Upgrade

var ammo_component : AmmoComponent


func apply_upgrade(upgrade_node : Node2D):
	var player = upgrade_node as Player
	player.inventory_instance.weapon_replaced.connect(on_weapon_replaced)
	var ammo_component = player.inventory_instance.items[0].ammo_component
	change_stats()


func on_weapon_replaced(weapon : PlayerWeaponBase):
	ammo_component = weapon.ammo_component
	change_stats()


func change_stats():
	ammo_component.add_to_multiplier(0.20)
	#ammo_component.max_ammo *= 1.20
	ammo_component.reload_time *= 0.9


func remove_upgrade():
	ammo_component.add_to_multiplier(-0.20)
	super.remove_upgrade()
