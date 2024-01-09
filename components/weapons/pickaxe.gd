extends Node2D

@onready var audio_player_component : AudioPlayerComponent = $AudioPlayerComponent
@onready var melee_weapon_component = $MeleeWeaponComponent
@onready var sprite : Sprite2D = $WeaponSprite
@onready var animation_player : AnimationPlayer = $AnimationPlayer

var ability : Node2D
var attack_vector
var disabled : bool = false


func _physics_process(delta):
	if not melee_weapon_component:
		return
	
	attack_vector = get_global_mouse_position()
	look_at(attack_vector)
	if attack_vector.x > global_position.x:
		scale.y = 1.0
	else:
		scale.y = -1.0
	
	if attack_vector.y > global_position.y:
		sprite.z_index = 0
	else:
		sprite.z_index = -1
	
	if disabled:
		return
	
	if Input.is_action_pressed("attack"):
		if ability and ability.is_active():
			ability.activate()
			melee_weapon_component.start_cooldown()
			return
		
		if melee_weapon_component.attack(attack_vector):
			if animation_player.is_playing():
				animation_player.stop()
			
			animation_player.play("attack")
			audio_player_component.play_random_sound()


func disable(value : bool):
	disabled = value
