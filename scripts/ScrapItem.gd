extends Area3D

const SPARKS_SCENE = preload("res://scenes/effects/CollectSparks.tscn")
const POPUP_SCENE = preload("res://scenes/effects/CoinPopup.tscn")

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
	mat.emission_energy_multiplier = 0.5 + rarity * 0.3
	mesh.material_override = mat
	# Scale rare items slightly bigger
	if rarity >= 2:
		mesh.scale = Vector3(1.3, 1.3, 1.3)
	if rarity >= 3:
		mesh.scale = Vector3(1.6, 1.6, 1.6)

func _process(delta: float) -> void:
	_bob_time += delta
	position.y = _initial_y + 0.5 + sin(_bob_time * 2.0) * 0.1
	# Legendary slow rotation
	if scrap_data.get("rarity", 0) >= 3:
		rotation.y += delta * 1.5

func _on_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		collect()

func collect() -> void:
	var value = scrap_data.get("value", 1) * GameManager.click_power
	# Add to inventory
	for i in GameManager.click_power:
		if GameManager.inventory.size() < GameManager.max_slots:
			GameManager.add_to_inventory(scrap_data.duplicate())
	GameManager.add_coins(value)
	# Spawn sparks
	var sparks = SPARKS_SCENE.instantiate()
	sparks.position = global_position
	var rarity = scrap_data.get("rarity", 0)
	var colors = [Color("#888888"), Color("#ff6a00"), Color("#00e5ff"), Color("#FFD700")]
	sparks.color = colors[rarity]
	sparks.emitting = true
	get_tree().current_scene.add_child(sparks)
	# Auto-remove sparks
	get_tree().create_timer(1.0).timeout.connect(sparks.queue_free)
	# Spawn coin popup
	var popup = POPUP_SCENE.instantiate()
	popup.position = global_position + Vector3(0, 1, 0)
	popup.setup(value, colors[rarity])
	get_tree().current_scene.add_child(popup)
	# Remove self
	queue_free()
