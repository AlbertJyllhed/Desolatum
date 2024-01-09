extends CharacterBody2D
class_name Projectile

@export var impact_scene : PackedScene
@export var explosion_scene : PackedScene
@export var speed : float = 400
@export var bounces : int = 0
@export var piercing : bool = false

@onready var sprite : Sprite2D = $Sprite2D
@onready var hitbox : Hitbox = $Hitbox

var base_layer : Node2D
var direction = Vector2.ZERO


func setup(new_direction, new_speed = 400, new_damage = 1):
	speed = new_speed
	hitbox.damage = new_damage
	hitbox.knockback_vector = new_direction
	direction = new_direction
	sprite.rotation = direction.angle()
	base_layer = get_tree().get_first_node_in_group("base_layer")


func explode():
	if explosion_scene:
		var explosion_instance = explosion_scene.instantiate() as Node2D
		base_layer.call_deferred("add_child", explosion_instance)
		explosion_instance.global_position = global_position
	
	queue_free()


func _physics_process(delta):
	var collision_result = move_and_collide(direction * speed * delta)
	if collision_result != null:
		if bounces > 0:
			direction = direction.bounce(collision_result.get_normal())
			sprite.rotation = direction.angle()
			bounces -= 1
			return
		
		var impact_instance = impact_scene.instantiate() as Node2D
		base_layer.add_child(impact_instance)
		impact_instance.global_position = collision_result.get_position()
		impact_instance.rotation = collision_result.get_normal().angle()
		explode()


func _on_hitbox_area_entered(_area):
	if piercing:
		return
	
	explode()
