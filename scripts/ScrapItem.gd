extends Area3D

var scrap_data: Dictionary = {}
var _bob_time: float = 0.0
var _initial_y: float = 0.0

func setup(data: Dictionary) -> void:
	scrap_data = data
	_initial_y = position.y
	var mesh = $MeshInstance3D
	var mat = StandardMaterial3D.new()
	var colors = [
		Color("#888888"),
		Color("#ff6a00"),
		Color("#00e5ff"),
		Color("#FFD700"),
	]
	var rarity = data.get("rarity", 0)
	mat.albedo_color = colors[rarity]
	mat.emission_enabled = true
	mat.emission = colors[rarity]
	mat.emission_energy_multiplier = 0.5
	mesh.material_override = mat

func _process(delta: float) -> void:
	_bob_time += delta
	position.y = _initial_y + 0.5 + sin(_bob_time * 2.0) * 0.1

func _on_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		collect()

func collect() -> void:
	for i in GameManager.click_power:
		if GameManager.inventory.size() < GameManager.max_slots:
			GameManager.add_to_inventory(scrap_data.duplicate())
	GameManager.add_coins(scrap_data.get("value", 1) * GameManager.click_power)
	queue_free()
