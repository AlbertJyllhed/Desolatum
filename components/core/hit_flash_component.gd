extends Node

@export var health_component : Node
@export var sprite : Sprite2D
@export var hit_flash_material : ShaderMaterial

@onready var timer : Timer = $Timer


func _ready():
	if not sprite:
		return
	
	health_component.damaged.connect(on_damaged)
	sprite.material = hit_flash_material


func on_damaged(_amount : float) -> void:
	(sprite.material as ShaderMaterial).set_shader_parameter("lerp_percent", 1.0)
	timer.start()


func _on_timer_timeout():
	(sprite.material as ShaderMaterial).set_shader_parameter("lerp_percent", 0.0)
