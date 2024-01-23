extends Upgrade

var gun : GunComponent


func apply_upgrade(upgrade_node : Node2D):
	var player = upgrade_node as Player
	player.inventory_instance.weapon_replaced.connect(on_weapon_replaced)
	gun = player.inventory_instance.items[0].weapon_component
	gun.shot_projectile.connect(on_shot_projectile)


func on_weapon_replaced(weapon : PlayerWeaponBase):
	gun = weapon.weapon_component
	gun.shot_projectile.connect(on_shot_projectile)


func on_shot_projectile(new_projectile : Projectile):
	if randf() > 0.15:
		return
	
	var damage = new_projectile.hitbox.damage * 3
	new_projectile.hitbox.set_damage(damage)
