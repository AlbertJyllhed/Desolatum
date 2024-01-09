extends Node2D

@onready var attract_area : Area2D = $AttractArea

var focused_interactables : Array[Interactable]


func _physics_process(_delta):
	if Input.is_action_just_pressed("pick_up"):
		if focused_interactables.size() > 0:
			var closest_interactable = focused_interactables[0]
			for pickup in focused_interactables:
				if global_position.distance_to(pickup.global_position) < global_position.distance_to(closest_interactable.global_position):
					closest_interactable = pickup
			
			closest_interactable.interact()
	
	if not attract_area.has_overlapping_bodies():
		return
	
	var bodies = attract_area.get_overlapping_bodies()
	for body in bodies:
		if body is AutoPickup:
			var direction = (global_position - body.global_position).normalized()
			body.accelerate_in_direction(direction, 120)


func _on_pickup_area_body_entered(body):
	if body is AutoPickup:
		var pickup = body as AutoPickup
		pickup.pick_up()
	
	if body is Interactable:
		focused_interactables.append(body)
		body.show_details()


func _on_pickup_area_body_exited(body):
	if body is Interactable:
		body.hide_details()
		focused_interactables.erase(body)
