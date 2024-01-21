extends Control

@onready var progress_bar : TextureProgressBar = $TextureProgressBar
@onready var label : Label = $TextureProgressBar/Label


func _ready():
	GameEvents.health_updated.connect(on_health_updated)


func on_health_updated(amount : int, max_amount : int):
	progress_bar.max_value = max_amount
	progress_bar.value = amount
	label.text = str(amount) + " / " + str(max_amount)
