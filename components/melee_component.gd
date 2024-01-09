extends WeaponComponent
class_name MeleeComponent

@onready var hitbox : Hitbox = $Pivot/Hitbox


func attack(attack_vector : Vector2):
	super.attack(attack_vector)
	
	var direction = (attack_vector - global_position).normalized()
	hitbox.knockback_vector = direction
