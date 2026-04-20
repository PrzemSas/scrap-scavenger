extends Node3D

const SCRAP_SCENE = preload("res://scenes/objects/ScrapItem.tscn")
const WORLD_HALF := 55.0
const MAX_ITEMS := 50

var scrap_types: Array = [
	{"id":"alloy_frame","name":"Alloy Frame","value":45,"rarity":1,"weight":20},
	{"id":"titanium_plate","name":"Titanium Plate","value":80,"rarity":2,"weight":12},
	{"id":"nano_chip","name":"Nano Chip","value":60,"rarity":2,"weight":10},
	{"id":"reactor_core","name":"Reactor Core","value":150,"rarity":3,"weight":4},
	{"id":"scrap_drone","name":"Scrap Drone","value":200,"rarity":3,"weight":2},
	{"id":"cable","name":"Copper Cable","value":6,"rarity":1,"weight":18},
	{"id":"motor","name":"Motor","value":20,"rarity":2,"weight":8},
	{"id":"gear","name":"Titanium Gear","value":35,"rarity":2,"weight":8},
	{"id":"gold","name":"Gold Part","value":60,"rarity":3,"weight":3},
	{"id":"crystal","name":"Forge Crystal","value":120,"rarity":3,"weight":1},
]

var _rt: float = 0.0

func _ready() -> void:
	for i in MAX_ITEMS:
		spawn_random()

func _process(delta: float) -> void:
	if get_child_count() < MAX_ITEMS:
		_rt += delta
		if _rt >= 0.6:
			_rt = 0.0
			spawn_random()

func spawn_random() -> void:
	var item = SCRAP_SCENE.instantiate()
	var x := randf_range(-WORLD_HALF, WORLD_HALF)
	var z := randf_range(-WORLD_HALF, WORLD_HALF)
	item.position = Vector3(x, 0.4, z)
	item.scrap_data = _pick_type()
	add_child(item)

func _pick_type() -> Dictionary:
	var total_w: float = 0.0
	for t in scrap_types: total_w += t.weight
	var r := randf() * total_w
	for t in scrap_types:
		r -= t.weight
		if r <= 0.0: return t
	return scrap_types[0]
