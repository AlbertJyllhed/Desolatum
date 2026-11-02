extends RayCast2D
class_name TileRemoverRay

@onready var audio_player_component : AudioPlayerComponent = $AudioPlayerComponent


func _physics_process(_delta):
	if not is_colliding():
		return
	
	var tilemap := get_collider() as TileMapLayer
	if not tilemap:
		return
	
	var hit_position := get_collision_point() - get_collision_normal()
	var coord := tilemap.local_to_map(tilemap.to_local(hit_position))
	audio_player_component.play_random_sound()
	TileBreaker.break_tile(coord)
	enabled = false
