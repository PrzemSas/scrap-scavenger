extends Area3D

const SPARKS_SCENE = preload("res://scenes/effects/CollectSparks.tscn")
const POPUP_SCENE = preload("res://scenes/effects/CoinPopup.tscn")

var scrap_data: Dictionary = {}
var _bob_time: float = 0.0
var _initial_y: float = 0.0

func setup(data: Dictionary) -> void:
	scrap_data = data
	_initial_y = position.y
	var mesh_inst = $MeshInstance3D
	var col_shape = $CollisionShape3D
	var rarity = data.get("rarity", 0)
	var colors = [Color("#888888"), Color("#ff6a00"), Color("#00e5ff"), Color("#FFD700")]
	
	# Different mesh per scrap type
	var item_id = data.get("id", "can")
	match item_id:
		"can":
			var m = CylinderMesh.new()
			m.top_radius = 0.12
			m.bottom_radius = 0.12
			m.height = 0.3
			mesh_inst.mesh = m
			var s = CylinderShape3D.new()
			s.radius = 0.12
			s.height = 0.3
			col_shape.shape = s
		"bolt":
			var m = CylinderMesh.new()
			m.top_radius = 0.08
			m.bottom_radius = 0.08
			m.height = 0.25
			mesh_inst.mesh = m
			var s = CylinderShape3D.new()
			s.radius = 0.08
			s.height = 0.25
			col_shape.shape = s
		"pipe":
			var m = CylinderMesh.new()
			m.top_radius = 0.06
			m.bottom_radius = 0.06
			m.height = 0.6
			mesh_inst.mesh = m
			mesh_inst.rotation.z = PI / 2
			var s = CylinderShape3D.new()
			s.radius = 0.06
			s.height = 0.6
			col_shape.shape = s
		"cable":
			var m = TorusMesh.new()
			m.inner_radius = 0.06
			m.outer_radius = 0.18
			mesh_inst.mesh = m
			var s = SphereShape3D.new()
			s.radius = 0.2
			col_shape.shape = s
		"battery":
			var m = BoxMesh.new()
			m.size = Vector3(0.25, 0.35, 0.15)
			mesh_inst.mesh = m
			var s = BoxShape3D.new()
			s.size = Vector3(0.25, 0.35, 0.15)
			col_shape.shape = s
		"motor":
			var m = CylinderMesh.new()
			m.top_radius = 0.2
			m.bottom_radius = 0.2
			m.height = 0.3
			mesh_inst.mesh = m
			var s = CylinderShape3D.new()
			s.radius = 0.2
			s.height = 0.3
			col_shape.shape = s
		"gold":
			var m = PrismMesh.new()
			m.size = Vector3(0.3, 0.3, 0.3)
			mesh_inst.mesh = m
			var s = BoxShape3D.new()
			s.size = Vector3(0.3, 0.3, 0.3)
			col_shape.shape = s
		_:
			var m = BoxMesh.new()
			m.size = Vector3(0.3, 0.3, 0.3)
			mesh_inst.mesh = m
	
	# Material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = colors[rarity]
	mat.emission_enabled = true
	mat.emission = colors[rarity]
	mat.emission_energy_multiplier = 0.5 + rarity * 0.4
	mat.metallic = 0.3 + rarity * 0.15
	mat.roughness = 0.7 - rarity * 0.1
	mesh_inst.material_override = mat
	
	# Scale by rarity
	if rarity >= 2:
		mesh_inst.scale = Vector3(1.4, 1.4, 1.4)
	if rarity >= 3:
		mesh_inst.scale = Vector3(1.8, 1.8, 1.8)
	
	# Name label
	var label = $NameLabel
	if label:
		label.text = data.get("name", "")
		label.modulate = colors[rarity]

func _process(delta: float) -> void:
	_bob_time += delta
	position.y = _initial_y + 0.5 + sin(_bob_time * 2.0) * 0.1
	if scrap_data.get("rarity", 0) >= 3:
		rotation.y += delta * 1.5
	elif scrap_data.get("rarity", 0) >= 2:
		rotation.y += delta * 0.5

func _on_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		collect()

func collect() -> void:
	var value = scrap_data.get("value", 1) * GameManager.click_power
	for i in GameManager.click_power:
		if GameManager.inventory.size() < GameManager.max_slots:
			GameManager.add_to_inventory(scrap_data.duplicate())
	GameManager.add_coins(value)
	AudioManager.play_collect()
	# Sparks
	var sparks = SPARKS_SCENE.instantiate()
	sparks.position = global_position
	var rarity = scrap_data.get("rarity", 0)
	var colors = [Color("#888888"), Color("#ff6a00"), Color("#00e5ff"), Color("#FFD700")]
	sparks.color = colors[rarity]
	sparks.emitting = true
	get_tree().current_scene.add_child(sparks)
	get_tree().create_timer(1.0).timeout.connect(sparks.queue_free)
	# Popup
	var popup = POPUP_SCENE.instantiate()
	popup.position = global_position + Vector3(0, 1, 0)
	popup.setup(value, colors[rarity])
	get_tree().current_scene.add_child(popup)
	queue_free()
