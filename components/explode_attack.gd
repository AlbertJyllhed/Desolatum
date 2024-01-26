extends EnemyWeaponBase

@export var health_component : HealthComponent


func attack():
	health_component.damage(100)


func _on_attack_area_body_entered(_body):
	has_target.emit()
