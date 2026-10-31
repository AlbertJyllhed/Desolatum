extends Resource
class_name Item

@export var id : String
@export var name : String
@export_multiline var description : String
@export var icon : Texture2D

@export var amount : int = 1

enum PickupType { manual, auto }
@export var pickup_type = PickupType.manual
@export var drop_weight : int = 1
@export var drop_limit : int = -1
