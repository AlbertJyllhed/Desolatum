extends State
class_name EnemyState

var enemy_entity : EnemyEntity


func _ready():
	if not owner is EnemyEntity:
		return
	
	enemy_entity = owner as EnemyEntity
