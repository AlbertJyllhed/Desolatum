extends Upgrade

@export var time_to_reset : float = 2.0

@onready var timer : Timer = $Timer

var gun : GunComponent


func apply_upgrade(upgrade_node : Node2D):
	var player = upgrade_node as Player
	player.health_component.health_changed.connect(on_health_changed)
	player.inventory_instance.weapon_replaced.connect(on_weapon_replaced)
	gun = player.inventory_instance.items[0].weapon_component


func on_weapon_replaced(weapon : PlayerWeaponBase):
	gun = weapon.weapon_component


func on_health_changed(_current_health : int):
	if not timer.is_stopped():
		timer.stop()
	
	gun.projectile_damage = min(gun.base_projectile_damage * 2, 4)
	gun.projectile_deviation = min(gun.base_projectile_deviation + 0.4, 0.6)
	timer.start(time_to_reset)


func _on_timer_timeout():
	gun.projectile_damage = gun.base_projectile_damage
	gun.projectile_deviation = gun.base_projectile_deviation
