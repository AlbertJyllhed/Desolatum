extends Node2D
class_name MeleeSlash

## Zero-speed "projectile" for melee weapons, fired through GunComponent.
## A short-lived hitbox and swing effect that keeps the direction it was
## swung in, even if the weapon turns. It follows its shooter's position
## (when fired with an aim source) so it doesn't trail behind a moving player.

## How long the hitbox can damage after the swing starts
@export var active_time: float = 0.1
## How long the swing effect stays before the slash is removed
@export var lifetime: float = 0.3

@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox: Hitbox = $Hitbox
@onready var tile_remover_ray: TileRemoverRay = get_node_or_null("TileRemoverRay") as TileRemoverRay

var follow_target: Node2D
var follow_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	# update after the player has moved this frame, so the slash doesn't lag behind
	process_physics_priority = 100


func setup(shot: ShotInfo) -> void:
	rotation = shot.direction.angle()
	# mirror when swinging left, like the weapon pivot does
	scale.y = -1.0 if shot.direction.x < 0.0 else 1.0

	hitbox.damage = shot.damage
	hitbox.knockback_vector = shot.direction
	hitbox.collision_shape.set_deferred("disabled", false)

	if is_instance_valid(shot.aim_source):
		follow_target = shot.aim_source
		follow_offset = global_position - follow_target.global_position

	if tile_remover_ray:
		tile_remover_ray.force_raycast_update()

	sprite.frame = 0
	var last_frame: int = sprite.hframes * sprite.vframes - 1
	var tween: Tween = create_tween()
	tween.tween_property(sprite, "frame", last_frame, lifetime * 2.0 / 3.0)

	var timer_tween: Tween = create_tween()
	timer_tween.tween_interval(active_time)
	timer_tween.tween_callback(hitbox.collision_shape.set_deferred.bind("disabled", true))
	timer_tween.tween_interval(maxf(lifetime - active_time, 0.0))
	timer_tween.tween_callback(queue_free)


func _physics_process(_delta: float) -> void:
	if is_instance_valid(follow_target):
		global_position = follow_target.global_position + follow_offset
