extends RefCounted
class_name MapGenerator

const LAYERS := 8
const MIN_NODES := 2
const MAX_NODES := 4


static func generate(config : PlayerConfig) -> Array:
	var layers : Array = []
	
	for l in LAYERS:
		var layer : Array[MapNode] = []
		# One node at the top (the run starts there automatically) and one boss at the bottom.
		var count := 1 if l == 0 or l == LAYERS - 1 else randi_range(MIN_NODES, MAX_NODES)
		for i in count:
			var node := MapNode.new()
			node.layer = l
			node.index = i
			node.type = _pick_type(l)
			if node.type == MapNode.Type.BOSS:
				node.option = _make_boss_option(config)
			elif node.type != MapNode.Type.REST and node.type != MapNode.Type.SHOP:
				node.option = _make_option(config, l)
			layer.append(node)
		layers.append(layer)
	
	_link_layers(layers)
	return layers


static func _pick_type(layer : int) -> MapNode.Type:
	if layer == LAYERS - 1:
		return MapNode.Type.BOSS
	if layer == 0:
		return MapNode.Type.MISSION       # always start with a plain mission
	if layer == LAYERS - 2:
		return MapNode.Type.REST          # rest stop before the boss
	
	var roll := randf()
	if roll < 0.12:
		return MapNode.Type.REST
	if roll < 0.22:
		return MapNode.Type.SHOP
	if roll < 0.38 and layer >= 3:
		return MapNode.Type.ELITE
	return MapNode.Type.MISSION


static func _make_option(config : PlayerConfig, layer : int) -> LevelOption:
	var pool := config.missions.filter(func(m): return m.min_depth <= layer)
	var option := LevelOption.new()
	option.mission = pool.pick_random()
	option.biome = config.biomes.pick_random()
	return option


static func _make_boss_option(config : PlayerConfig) -> LevelOption:
	var option := LevelOption.new()
	option.mission = config.boss_mission
	option.biome = config.biomes.back()
	return option


static func _link_layers(layers : Array) -> void:
	for l in layers.size() - 1:
		var here : Array = layers[l]
		var there : Array = layers[l + 1]
		
		# 1. Every node links to the closest-by-position node(s) in the next layer.
		for node : MapNode in here:
			var target := _scaled_index(node.index, here.size(), there.size())
			node.next.append(target)
			
			# Maybe a second link to a neighbour.
			if randf() < 0.45:
				var other := clampi(target + (1 if randf() < 0.5 else -1), 0, there.size() - 1)
				if not node.next.has(other):
					node.next.append(other)
		
		# 2. Anything in the next layer nobody links to gets adopted.
		for t in there.size():
			var has_parent := false
			for node : MapNode in here:
				if node.next.has(t):
					has_parent = true
					break
			if has_parent:
				continue
			
			var closest : MapNode = here[_scaled_index(t, there.size(), here.size())]
			closest.next.append(t)
		
		for node : MapNode in here:
			node.next.sort()


## Maps position i of a layer with `from_size` nodes onto a layer with `to_size` nodes.
static func _scaled_index(i : int, from_size : int, to_size : int) -> int:
	if from_size <= 1:
		return to_size / 2
	return roundi(float(i) / float(from_size - 1) * float(to_size - 1))
