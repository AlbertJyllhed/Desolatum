extends Node2D

var hurtbox : Hurtbox


func apply_effect(new_hurtbox : Hurtbox):
	hurtbox = new_hurtbox
	hurtbox.hit.connect(on_hurtbox_hit)


func on_hurtbox_hit():
	hurtbox.damage_multiplier = 6.0
