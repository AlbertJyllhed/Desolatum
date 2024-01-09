extends Node

@export var projectile : Projectile
@export var slowdown_start_time : float = 0.25
@export var target_speed : float


func _ready():
	target_speed = projectile.speed
	$Timer.start(slowdown_start_time)


func _physics_process(_delta):
	projectile.speed = lerp(projectile.speed, target_speed, 0.2)


func _on_timer_timeout():
	target_speed = 0
