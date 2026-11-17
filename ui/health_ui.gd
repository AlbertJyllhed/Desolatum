extends Control

## Health bar with a damage trail: on damage the bar drops at once, while a
## lighter TrailBar behind it waits a moment and then drains down to match,
## showing how much the hit cost. Healing moves both bars up at once.

## Seconds the trail waits before draining.
@export var trail_delay: float = 0.4
## Seconds the trail takes to drain down to the current health.
@export var trail_drain_time: float = 0.35

@onready var progress_bar: TextureProgressBar = $TextureProgressBar
@onready var label: Label = $TextureProgressBar/Label
## Optional: a second bar behind TextureProgressBar, same size, lighter colour.
@onready var trail_bar: TextureProgressBar = $TrailBar

var _trail_tween : Tween
var _has_value : bool = false


func _ready():
	GameEvents.health_updated.connect(on_health_updated)


func on_health_updated(amount: int, max_amount: int) -> void:
	var old_value: float = progress_bar.value
	progress_bar.max_value = max_amount
	progress_bar.value = amount
	label.text = str(amount) + " / " + str(max_amount)
	_update_trail(old_value, amount, max_amount)
	_has_value = true


func _update_trail(old_value: float, amount: int, max_amount: int) -> void:
	if not trail_bar:
		return
	trail_bar.max_value = max_amount

	# First update or healing: the trail simply matches the bar.
	if not _has_value or amount >= old_value:
		if _trail_tween:
			_trail_tween.kill()
		trail_bar.value = amount
		return

	# Damage: keep the trail where it was (or higher, if it's still draining
	# from an earlier hit), then drain it after the delay.
	trail_bar.value = maxf(trail_bar.value, old_value)
	if _trail_tween:
		_trail_tween.kill()
	_trail_tween = create_tween()
	_trail_tween.tween_interval(trail_delay)
	_trail_tween.tween_property(trail_bar, "value", float(amount), trail_drain_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
