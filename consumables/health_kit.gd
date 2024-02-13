extends Consumable

@export var heal_amount : float = 4.0


func use_consumable():
	player.health_component.heal(heal_amount)
	super.use_consumable()
