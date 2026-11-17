extends Node2D
class_name ScreenShakeComponent

## Shakes the camera from where this node is. Drop it into scenes that have no
## script of their own, like the explosion: with shake_on_ready it shakes as
## soon as the scene appears. Others can call shake() themselves.

## Shake amount, 0 to 1 (e.g. 0.3 small, 0.7 big explosion).
@export var amount : float = 0.6
## Shake as soon as this node enters the scene.
@export var shake_on_ready : bool = true
## Weaker the further from the camera (see PlayerCamera.shake_falloff_distance).
@export var fade_with_distance : bool = true


func _ready() -> void:
	if shake_on_ready:
		shake()


func shake() -> void:
	var camera := get_viewport().get_camera_2d() as PlayerCamera
	if not camera:
		return
	if fade_with_distance:
		camera.add_shake_at(amount, global_position)
	else:
		camera.add_shake(amount)
