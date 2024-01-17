extends Pickup
class_name TetherNode

@export var electric_arc_scene : PackedScene

var electric_arcs : Array[ElectricArc]
var max_target_amount : int = 6


func _ready():
	for i in max_target_amount:
		spawn_electric_arc()


func spawn_electric_arc():
	var electric_arc_instance = electric_arc_scene.instantiate() as ElectricArc
	add_child(electric_arc_instance)
	electric_arc_instance.global_position = global_position
	electric_arc_instance.set_enabled(false)
	electric_arcs.append(electric_arc_instance)


func _on_area_2d_body_entered(body):
	for electric_arc in electric_arcs:
		if electric_arc.target:
			continue
		
		electric_arc.set_target(body)
		electric_arc.set_enabled(true)
		return


func _on_area_2d_body_exited(body):
	for electric_arc in electric_arcs:
		if electric_arc.target == body:
			electric_arc.set_target(null)
			electric_arc.set_enabled(false)
			return
