extends RefCounted
class_name MapNode

enum Type { MISSION, ELITE, REST, SHOP, BOSS }

var layer : int
var index : int                 # position within its layer
var type : Type = Type.MISSION
var option : LevelOption        # null for REST / SHOP
var next : Array[int] = []      # indices into the next layer
var visited : bool = false
