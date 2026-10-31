@icon("res://addons/at-icons/node/star.svg")
extends Node
class_name Upgrade

var id : String


func _ready():
	SceneManager.changing_level.connect(remove_upgrade)


func apply_upgrade(_upgrade_node : Node2D):
	pass


func remove_upgrade():
	queue_free()
