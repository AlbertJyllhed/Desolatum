extends StaticBody2D

@onready var sprite : Sprite2D = $Sprite2D
@onready var shadow : Sprite2D = $Shadow

var pos : Vector2


func _ready():
	pos = global_position / 16 - Vector2(0.5, 0.5)
	GameEvents.navigation_updated.emit(pos, true)
	
	if randf() < 0.5:
		return
	
	sprite.flip_h = true
	shadow.flip_h = true


func _on_health_component_died():
	GameEvents.navigation_updated.emit(pos, false)
