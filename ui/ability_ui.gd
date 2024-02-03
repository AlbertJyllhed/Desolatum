extends Control

@onready var texture_progress_bar : TextureProgressBar = $TextureProgressBar
@onready var label : Label = $Label

var tween : Tween


func _ready():
	GameEvents.ability_updated.connect(on_ability_updated)


func on_ability_updated(recharge_time, uses):
	if tween:
		tween.kill()
	
	if recharge_time == 0:
		label.text = str(uses)
		texture_progress_bar.value = 0
		return
	
	label.text = str(uses)
	texture_progress_bar.max_value = recharge_time
	texture_progress_bar.value = 0
	tween = create_tween()
	tween.tween_property(texture_progress_bar, "value", texture_progress_bar.max_value, recharge_time)
