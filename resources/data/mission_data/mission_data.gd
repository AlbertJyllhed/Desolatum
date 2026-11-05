extends Resource
class_name MissionData

@export var title : String
@export var mission_scene : PackedScene
@export var icon : Texture2D
@export var reward : Item               # shown on the button, granted on completion
@export var min_depth : int = 0         # so hard missions appear later
