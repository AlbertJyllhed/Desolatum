extends Node2D

@onready var grab_area : Area2D = $GrabArea
@onready var sprite : Sprite2D = $GrabArea/Sprite2D

var throw_direction : Vector2
var grab_target : GrabTargetArea
var projectile_scene : PackedScene


func _physics_process(delta):
	throw_direction = get_global_mouse_position()
	look_at(throw_direction)
	
	#grab the target if we don't already have one
	if Input.is_action_just_pressed("alt_attack"):
		if not grab_target or projectile_scene:
			return
		
		projectile_scene = grab_target.projectile
		setup_sprite()
		grab_target.owner.queue_free()
		grab_target = null


func setup_sprite():
	var target_sprite = grab_target.sprite
	sprite.texture = target_sprite.texture
	sprite.hframes = target_sprite.hframes
	sprite.vframes = target_sprite.vframes
	sprite.frame = target_sprite.frame


func is_active() -> bool:
	if projectile_scene:
		return true
	
	return false


func activate():
	#throw the grabbed object
	if not projectile_scene:
		return
	
	var foreground_layer = get_tree().get_first_node_in_group("foreground_layer")
	var direction = (throw_direction - global_position).normalized()
	var new_projectile = projectile_scene.instantiate()
	foreground_layer.add_child(new_projectile)
	new_projectile.global_position = grab_area.global_position
	new_projectile.setup(direction, 300, 1)
	projectile_scene = null
	sprite.texture = null


func _on_vacuum_area_area_entered(area):
	if not area is GrabTargetArea:
		return
	
	grab_target = area as GrabTargetArea


func _on_vacuum_area_area_exited(area):
	grab_target = null
