extends Node

## Object pool for frequently spawned scenes (effects, later projectiles).
## Pool.spawn(scene, parent, position, rotation) reuses an unused instance of
## the scene if there is one, otherwise instantiates it. Pooled scenes hand
## themselves back with PooledEffect.release() instead of queue_free().
## Unused instances are kept out of the scene tree, so they don't draw or
## process, and they survive scene changes.

## Most unused instances kept per scene; extras are freed.
@export var max_free_per_scene : int = 64

const SCENE_META := &"pool_scene"

## PackedScene -> Array of unused instances (outside the tree).
var _free : Dictionary = {}


## Adds an instance of [param scene] to [param parent] at the given global
## position and rotation (for 2D nodes) and starts it from the beginning.
func spawn(scene : PackedScene, parent : Node, global_pos : Vector2 = Vector2.ZERO, rot : float = 0.0) -> Node:
	var node : Node = _take_free(scene)
	var reused : bool = node != null
	if not reused:
		node = scene.instantiate()
		node.set_meta(SCENE_META, scene)

	parent.add_child(node)
	if node is Node2D:
		node.global_position = global_pos
		node.rotation = rot
	if reused:
		var effect := PooledEffect.find_in(node)
		if effect:
			effect.reset()
	return node


## Takes a node out of the scene and keeps it for reuse. Nodes that didn't
## come from the pool are simply freed.
func release(node : Node) -> void:
	if not is_instance_valid(node):
		return
	if not node.has_meta(SCENE_META):
		node.queue_free()
		return
	# Deferred: release is usually called from the node's own animation or timer.
	_park.call_deferred(node)


func _park(node : Node) -> void:
	if not is_instance_valid(node) or node.is_queued_for_deletion():
		return
	var scene : PackedScene = node.get_meta(SCENE_META)
	var list : Array = _free.get_or_add(scene, [])
	if list.has(node):
		return
	var parent := node.get_parent()
	if parent:
		parent.remove_child(node)
	if list.size() >= max_free_per_scene:
		node.free()
		return
	list.append(node)


func _take_free(scene : PackedScene) -> Node:
	var list : Array = _free.get(scene, [])
	while not list.is_empty():
		var node = list.pop_back()
		if is_instance_valid(node):
			return node
	return null


## Number of unused instances waiting for reuse (for debugging/measuring).
func free_count(scene : PackedScene) -> int:
	return _free.get(scene, []).size()


func _exit_tree() -> void:
	# Unused instances are outside the tree, so free them ourselves.
	for list : Array in _free.values():
		for node in list:
			if is_instance_valid(node):
				node.free()
	_free.clear()
