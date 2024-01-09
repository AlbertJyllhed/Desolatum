extends Line2D

@onready var ray : RayCast2D = $RayCast2D
@onready var hitbox : Hitbox = $Hitbox
@onready var collision_shape : CollisionShape2D = $Hitbox/CollisionShape2D
@onready var light : Node2D = $PointLight2D

var bounces : int = 3
var tween : Tween


func setup(new_direction, new_length = 1000, new_damage = 1):
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
	collision_shape.shape.extents = Vector2(hitbox_size, 6)
	
	light.position = cast_point / 2
	light.rotation = cast_point.angle()
	light.scale = Vector2(hitbox_size / 16, 1)


func grow():
	tween = get_tree().create_tween().bind_node(self)
	tween.tween_property(self, "width", 10.0, 0.1)


func shrink():
	collision_shape.disabled = true
	tween = get_tree().create_tween().bind_node(self)
	tween.tween_property(self, "width", 0, 0.2)
	tween.tween_callback(queue_free)
