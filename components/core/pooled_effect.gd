extends Node
class_name PooledEffect

## Add as a child of an effect scene that's spawned with Pool.spawn(). Point
## the effect's "remove me" call here: in its AnimationPlayer, the method key
## that used to call queue_free on the root should call release() on this
## node instead (RemoveTimer does this automatically).
## When the pool reuses the effect, reset() restarts its particles, autoplay
## animations, autoplay sounds and autostart timers. If the root has a
## _on_pool_reset() method, that's called too.


## Hands the effect back to the pool (or frees it if it wasn't pooled).
func release() -> void:
	Pool.release(owner)


func reset() -> void:
	_restart(owner)
	if owner.has_method("_on_pool_reset"):
		owner._on_pool_reset()


## The PooledEffect child of [param node], if it has one.
static func find_in(node : Node) -> PooledEffect:
	for child in node.get_children():
		if child is PooledEffect:
			return child
	return null


static func _restart(node : Node) -> void:
	if node is GPUParticles2D:
		node.restart()
	elif node is CPUParticles2D:
		node.restart()
	elif node is AnimationPlayer:
		if node.autoplay != "":
			node.stop()
			node.play(node.autoplay)
	elif node is AudioStreamPlayer2D or node is AudioStreamPlayer:
		if node.autoplay:
			node.play()
	elif node is Timer:
		if node.autostart:
			node.start()
	for child in node.get_children():
		_restart(child)
