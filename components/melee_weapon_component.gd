extends WeaponComponent
class_name MeleeWeaponComponent

@onready var hitbox : Hitbox = $Pivot/Hitbox


func attack(attack_vector : Vector2):
	var direction = (attack_vector - global_position).normalized()
	hitbox.knockback_vector = direction
