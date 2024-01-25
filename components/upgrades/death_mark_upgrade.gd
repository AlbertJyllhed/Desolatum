extends Upgrade

@export var status_effect_scene : PackedScene


func apply_upgrade(upgrade_node : Node2D):
	var player = upgrade_node as Player
	var melee_weapon = player.inventory_instance.items[1].weapon_component as MeleeComponent
	melee_weapon.hitbox.area_entered.connect(on_hitbox_area_entered)


func on_hitbox_area_entered(area):
	if not area.owner is EnemyEntity:
		return
	
	var enemy = area.owner as EnemyEntity
	var status_effect_instance = status_effect_scene.instantiate() as Node2D
	enemy.add_child(status_effect_instance)
	status_effect_instance.global_position = enemy.global_position
	status_effect_instance.apply_effect(area)
