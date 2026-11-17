extends Node2D
class_name GasPuffs

## Script-driven gas puffs for the GasVent. Each puff is drawn as a soft white
## blob (alpha = how much gas) into GasViewport, and the GasCloud shader turns
## that into the pixel cloud. Because the script knows where every puff is,
## GasVent can put one hitbox shape on each puff, so damage only happens where
## gas is drawn. Positions are relative to this node, which sits at the centre
## of the viewport (the vent's centre).

class Puff:
	var position: Vector2
	var velocity: Vector2
	var age: float = 0.0
	var lifetime: float = 1.0
	var max_radius: float = 24.0

## Soft round blob; alpha must fall off linearly from the centre to the edge.
@export var texture: Texture2D
@export var max_puffs: int = 40
@export var puffs_per_second: float = 25.0
@export var lifetime: float = 1.6
@export_range(0.0, 1.0, 0.05) var lifetime_randomness: float = 0.3
## New puffs appear within this many pixels of the centre.
@export var spawn_radius: float = 28.0
## Seconds for the spawn area to grow from the centre to spawn_radius,
## so the cloud spreads outward when the vent starts.
@export var spread_time: float = 0.75
@export var min_speed: float = 5.0
@export var max_speed: float = 15.0
## How fast puffs slow down, in pixels per second per second.
@export var damping: float = 10.0
## Puff radius in pixels at full size.
@export var min_size: float = 19.0
@export var max_size: float = 32.0
## Gas amount at the centre of a puff at its thickest.
@export_range(0.0, 1.0, 0.05) var peak_density: float = 0.85
## Share of a puff's life spent fading in; the rest is spent fading out.
@export_range(0.01, 0.99, 0.01) var fade_in: float = 0.2

## A new puff starts at this share of its full size and grows to full size.
const START_SCALE: float = 0.6

var emitting: bool = false: set = set_emitting
var puffs: Array[Puff] = []

var _spawn_budget: float = 0.0
var _emit_time: float = 0.0


func set_emitting(value: bool) -> void:
	if value and not emitting:
		_emit_time = 0.0
		_spawn_budget = 0.0
	emitting = value


func _physics_process(delta: float) -> void:
	if emitting:
		_emit_time += delta
		_spawn_budget += puffs_per_second * delta
		while _spawn_budget >= 1.0:
			_spawn_budget -= 1.0
			if puffs.size() < max_puffs:
				_spawn_puff()

	for i in range(puffs.size() - 1, -1, -1):
		var puff: Puff = puffs[i]
		puff.age += delta
		if puff.age >= puff.lifetime:
			puffs.remove_at(i)
			continue
		puff.position += puff.velocity * delta
		puff.velocity = puff.velocity.move_toward(Vector2.ZERO, damping * delta)

	queue_redraw()


func _spawn_puff() -> void:
	var spread: float = spawn_radius
	if spread_time > 0.0:
		spread *= clampf(_emit_time / spread_time, 0.15, 1.0)
	var puff := Puff.new()
	# sqrt keeps the spawn points even across the circle instead of bunched in the middle
	puff.position = Vector2.from_angle(randf() * TAU) * sqrt(randf()) * spread
	puff.velocity = Vector2.from_angle(randf() * TAU) * randf_range(min_speed, max_speed)
	puff.lifetime = lifetime * (1.0 - randf() * lifetime_randomness)
	puff.max_radius = randf_range(min_size, max_size)
	puffs.append(puff)


## Gas amount at the puff's centre right now.
func get_density(puff: Puff) -> float:
	var t: float = puff.age / puff.lifetime
	if t < fade_in:
		return peak_density * t / fade_in
	return peak_density * (1.0 - (t - fade_in) / (1.0 - fade_in))


## Drawn radius of the puff right now.
func get_radius(puff: Puff) -> float:
	return puff.max_radius * lerpf(START_SCALE, 1.0, puff.age / puff.lifetime)


## Radius of the part of this puff that is thick enough to show as cloud
## (gas amount at or above threshold). 0 when the whole puff is too thin.
func get_visible_radius(puff: Puff, threshold: float) -> float:
	var density: float = get_density(puff)
	if density <= threshold:
		return 0.0
	return get_radius(puff) * (1.0 - threshold / density)


func _draw() -> void:
	if texture == null:
		return
	for puff: Puff in puffs:
		var radius: float = get_radius(puff)
		var rect := Rect2(puff.position - Vector2(radius, radius), Vector2(radius, radius) * 2.0)
		draw_texture_rect(texture, rect, false, Color(1.0, 1.0, 1.0, get_density(puff)))
