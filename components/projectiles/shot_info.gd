extends RefCounted
class_name ShotInfo

## Everything a projectile needs to know when it is fired.
## Built by GunComponent and passed to the projectile's setup(shot).

var direction: Vector2 = Vector2.RIGHT
var speed: float = 400.0
var damage: int = 1
var explode_chance: float = 0.0
var is_crit: bool = false
## Optional node with get_aim_direction() -> Vector2 (global aim point).
## Steering behaviours (e.g. rockets) follow it; null for turrets/enemies.
var aim_source: Node2D = null
