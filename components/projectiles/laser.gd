extends Line2D

@onready var ray : RayCast2D = $RayCast2D
@onready var hitbox : Hitbox = $Hitbox
@onready var light : Node2D = $PointLight2D

var explosion_scene : PackedScene = preload("res://particles/explosion.tscn")
var base_layer : Node2D
var explode_chance : float = 0.0
var tween : Tween


func setup(new_direction, new_length = 1000, new_damage = 1):
	base_layer = get_tree().get_first_node_in_group("base_layer")
	hitbox.area_entered.connect(on_hit)
	ray.target_position = new_direction * new_length
	hitbox.damage = new_damage
	hitbox.knockback_vector = new_direction
	cast()
	grow()
	$Timer.timeout.connect(shrink)


func cast():
	var cast_point = ray.target_position
	ray.force_raycast_update()
	
	if ray.is_colliding():
		cast_point = to_local(ray.get_collision_point())
	
	add_point(cast_point)
	hitbox.position = cast_point / 2
	hitbox.rotation = cast_point.angle()
	var hitbox_size = (get_point_position(0) + cast_point).length() / 2
	hitbox.collision_shape.shape.extents = Vector2(hitbox_size, 6)
	
	light.position = cast_point / 2
	light.rotation = cast_point.angle()
	light.scale = Vector2(hitbox_size, 1)


func grow():
	tween = get_tree().create_tween().bind_node(self)
	tween.tween_property(self, "width", 10.0, 0.1)


func shrink():
	hitbox.collision_shape.disabled = true
	tween = get_tree().create_tween().bind_node(self)
	tween.tween_property(self, "width", 0, 0.2)
	tween.tween_callback(queue_free)


func on_hit(area):
	if explode_chance < randf():
		return
	
	var explosion_instance = explosion_scene.instantiate() as Node2D
	base_layer.call_deferred("add_child", explosion_instance)
	explosion_instance.global_position = area.global_position
