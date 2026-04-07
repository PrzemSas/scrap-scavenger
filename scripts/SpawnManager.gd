extends Node3D

const SCRAP_SCENE = preload("res://scenes/objects/ScrapItem.tscn")
const MAX_ITEMS: int = 6
const RESPAWN_DELAY: float = 1.5

var scrap_types: Array = [
	{"id": "can", "name": "Aluminum Can", "value": 1, "rarity": 0, "weight": 35},
	{"id": "bolt", "name": "Bolt", "value": 1, "rarity": 0, "weight": 25},
	{"id": "pipe", "name": "Steel Pipe", "value": 3, "rarity": 0, "weight": 15},
	{"id": "cable", "name": "Copper Cable", "value": 5, "rarity": 1, "weight": 12},
	{"id": "battery", "name": "Battery", "value": 8, "rarity": 1, "weight": 8},
	{"id": "motor", "name": "Motor", "value": 15, "rarity": 2, "weight": 4},
	{"id": "gold", "name": "Gold Part", "value": 50, "rarity": 3, "weight": 1},
]

var _respawn_timer: float = 0.0

func _ready() -> void:
	for i in MAX_ITEMS:
		spawn_random()

func _process(delta: float) -> void:
	if get_child_count() < MAX_ITEMS:
		_respawn_timer += delta
		if _respawn_timer >= RESPAWN_DELAY:
			_respawn_timer = 0.0
			spawn_random()

func spawn_random() -> void:
	var data = _roll_scrap()
	var item = SCRAP_SCENE.instantiate()
	item.position = Vector3(randf_range(-8.0, 8.0), 0.0, randf_range(-8.0, 8.0))
	add_child(item)
	item.setup(data)

func _roll_scrap() -> Dictionary:
	var total = 0.0
	for s in scrap_types:
		total += s.weight
	var roll = randf() * total
	var cum = 0.0
	for s in scrap_types:
		cum += s.weight
		if roll <= cum:
			return s.duplicate()
	return scrap_types[0].duplicate()
