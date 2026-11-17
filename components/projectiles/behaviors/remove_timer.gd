extends Timer

## Removes its owner when the time runs out: back to the pool if the owner has
## a PooledEffect child, otherwise freed.
func _on_timeout():
	var effect := PooledEffect.find_in(owner)
	if effect:
		effect.release()
	else:
		owner.queue_free()
