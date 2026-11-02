extends Timer

@export var projectile : Projectile


func _on_timeout():
	if not projectile:
		return
	
	projectile.explode()
