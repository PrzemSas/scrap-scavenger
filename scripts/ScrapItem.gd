extends Area3D

const SPARKS = preload("res://scenes/effects/CollectSparks.tscn")
const POPUP  = preload("res://scenes/effects/CoinPopup.tscn")
const AURA   = preload("res://scenes/effects/RarityAura.tscn")

var scrap_data: Dictionary = {}
var _bob: float = 0.0
var _iy: float = 0.0
var _collected: bool = false
var _rarity_light: OmniLight3D = null

# [path, scale, rotation_euler]
const _GLB := {
	"can":           ["res://assets/models/polyhaven/Barrel_01/Barrel_01_2k.glb",                             0.20, Vector3.ZERO],
	"bolt":          ["res://assets/models/polyhaven/crowbar_01/crowbar_01_2k.glb",                           0.35, Vector3(0, 0, -PI/2)],
	"pipe":          ["res://assets/models/polyhaven/modular_airduct_circular_01/modular_airduct_circular_01_2k.glb", 0.30, Vector3.ZERO],
	"cable":         ["res://assets/models/polyhaven/modular_electric_cables/modular_electric_cables_2k.glb", 0.35, Vector3.ZERO],
	"battery":       ["res://assets/models/polyhaven/propane_tank/propane_tank_2k.glb",                       0.35, Vector3.ZERO],
	"coil":          ["res://assets/models/polyhaven/old_tyre/old_tyre_2k.glb",                               0.22, Vector3(PI/2, 0, 0)],
	"motor":         ["res://assets/models/polyhaven/bench_vice_01/bench_vice_01_2k.glb",                     0.28, Vector3.ZERO],
	"gear":          ["res://assets/models/polyhaven/rusted_wheel_rim_01/rusted_wheel_rim_01_2k.glb",         0.25, Vector3(PI/2, 0, 0)],
	"concrete_slab": ["res://assets/models/polyhaven/concrete_road_barrier/concrete_road_barrier_2k.glb",     0.14, Vector3.ZERO],
	"wiring":        ["res://assets/models/polyhaven/modular_electric_cables/modular_electric_cables_2k.glb", 0.28, Vector3(0, PI/4, 0)],
}

const _RARITY_COLORS := [Color("#888888"), Color("#ff6a00"), Color("#00e5ff"), Color("#FFD700")]

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"): collect()

func setup(data: Dictionary) -> void:
	scrap_data = data
	_iy = position.y
	var r: int = data.get("rarity", 0)
	var id: String = data.get("id", "can")

	_build_mesh(id, r, data)
	_add_rarity_fx(r)
	_setup_collision(r)

	var nl = get_node_or_null("NameLabel")
	if nl:
		nl.text = data.get("name", "")
		nl.modulate = _RARITY_COLORS[r]
		nl.visible = r >= 2

func _build_mesh(id: String, r: int, data: Dictionary) -> void:
	var mi: MeshInstance3D = $MeshInstance3D

	if id in _GLB:
		var info: Array = _GLB[id]
		var packed: PackedScene = load(info[0])
		if packed:
			var node: Node3D = packed.instantiate()
			node.scale = Vector3.ONE * float(info[1])
			var rot: Vector3 = info[2]
			if rot != Vector3.ZERO:
				node.rotation = rot
			add_child(node)
			mi.visible = false
			if r >= 2:
				node.scale *= 1.3
			if r >= 3:
				node.scale *= 1.35
			return

	# Procedural mesh for items without a GLB match
	_build_procedural(mi, id, r, data)

func _build_procedural(mi: MeshInstance3D, id: String, r: int, _data: Dictionary) -> void:
	var mat := StandardMaterial3D.new()

	match id:
		"chip":
			var m := BoxMesh.new(); m.size = Vector3(0.22, 0.04, 0.17); mi.mesh = m
			mat.albedo_color = Color("#1A3A4A"); mat.metallic = 0.9; mat.roughness = 0.15
			mat.emission_enabled = true; mat.emission = Color("#00AAFF"); mat.emission_energy_multiplier = 0.6 + r * 0.4
		"gold":
			var m := SphereMesh.new(); m.radius = 0.14; m.height = 0.28; mi.mesh = m
			mat.albedo_color = Color("#FFD700"); mat.metallic = 1.0; mat.roughness = 0.05
			mat.emission_enabled = true; mat.emission = Color("#FFAA00"); mat.emission_energy_multiplier = 0.8 + r * 0.6
		"crystal":
			var m := PrismMesh.new(); m.size = Vector3(0.14, 0.44, 0.14); mi.mesh = m
			mat.albedo_color = Color("#80FFFF"); mat.metallic = 0.0; mat.roughness = 0.0
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; mat.albedo_color.a = 0.72
			mat.emission_enabled = true; mat.emission = Color("#00FFEE"); mat.emission_energy_multiplier = 1.0 + r * 0.8
		"stone_chunk":
			var m := SphereMesh.new(); m.radius = 0.17; m.height = 0.26; mi.mesh = m
			mat.albedo_color = Color("#8A7A6A"); mat.metallic = 0.0; mat.roughness = 0.95
		"steel_beam":
			var m := BoxMesh.new(); m.size = Vector3(0.72, 0.09, 0.11); mi.mesh = m
			mat.albedo_color = Color("#607D8B"); mat.metallic = 0.75; mat.roughness = 0.5
		"alloy_frame":
			var m := BoxMesh.new(); m.size = Vector3(0.44, 0.08, 0.34); mi.mesh = m
			mat.albedo_color = Color("#88AACC"); mat.metallic = 0.85; mat.roughness = 0.3
			mat.emission_enabled = true; mat.emission = Color("#4488AA"); mat.emission_energy_multiplier = 0.3 + r * 0.2
		"titanium_plate":
			var m := BoxMesh.new(); m.size = Vector3(0.42, 0.05, 0.34); mi.mesh = m
			mat.albedo_color = Color("#C0C8D8"); mat.metallic = 0.95; mat.roughness = 0.2
		"nano_chip":
			var m := BoxMesh.new(); m.size = Vector3(0.18, 0.03, 0.14); mi.mesh = m
			mat.albedo_color = Color("#001520"); mat.metallic = 0.9; mat.roughness = 0.08
			mat.emission_enabled = true; mat.emission = Color("#00FFFF"); mat.emission_energy_multiplier = 1.8 + r * 0.8
		"reactor_core":
			var m := SphereMesh.new(); m.radius = 0.18; m.height = 0.36; mi.mesh = m
			mat.albedo_color = Color("#CC2060"); mat.metallic = 0.6; mat.roughness = 0.2
			mat.emission_enabled = true; mat.emission = Color("#FF1060"); mat.emission_energy_multiplier = 2.5 + r * 1.2
		"scrap_drone":
			var m := CylinderMesh.new(); m.top_radius = 0.16; m.bottom_radius = 0.16; m.height = 0.08; mi.mesh = m
			mat.albedo_color = Color("#40C0C0"); mat.metallic = 0.7; mat.roughness = 0.3
			mat.emission_enabled = true; mat.emission = Color("#20A0A0"); mat.emission_energy_multiplier = 0.6
		_:
			var m := BoxMesh.new(); m.size = Vector3(0.3, 0.3, 0.3); mi.mesh = m
			var base: Color = _RARITY_COLORS[r]
			mat.albedo_color = base; mat.emission_enabled = true; mat.emission = base
			mat.emission_energy_multiplier = 0.4 + r * 0.3; mat.metallic = 0.3 + r * 0.15; mat.roughness = 0.7 - r * 0.1

	mi.material_override = mat
	if r >= 2: mi.scale = Vector3(1.4, 1.4, 1.4)
	if r >= 3: mi.scale = Vector3(1.8, 1.8, 1.8)

func _add_rarity_fx(r: int) -> void:
	if r < 1: return

	_rarity_light = OmniLight3D.new()
	_rarity_light.light_color = _RARITY_COLORS[r]
	_rarity_light.light_energy = 0.6 + r * 0.9
	_rarity_light.omni_range = 1.8 + r * 0.6
	_rarity_light.position = Vector3(0, 0.25, 0)
	add_child(_rarity_light)

	if r >= 2:
		var aura: CPUParticles3D = AURA.instantiate()
		aura.color = _RARITY_COLORS[r]
		if r >= 3:
			aura.amount = 14
			aura.scale = Vector3(1.5, 1.5, 1.5)
		add_child(aura)

func _setup_collision(r: int) -> void:
	var cs: CollisionShape3D = $CollisionShape3D
	var sphere := SphereShape3D.new()
	sphere.radius = 1.0 + r * 0.15
	cs.shape = sphere

func _process(delta: float) -> void:
	if _collected: return
	_bob += delta
	position.y = _iy + 0.35 + sin(_bob * 2.0) * 0.08
	var r: int = scrap_data.get("rarity", 0)
	if r >= 3:
		rotation.y += delta * 1.5
	elif r >= 2:
		rotation.y += delta * 0.5
	if _rarity_light:
		var base_energy: float = 0.6 + r * 0.9
		_rarity_light.light_energy = base_energy * (0.80 + sin(_bob * 3.5) * 0.20)

func collect() -> void:
	if _collected or not is_inside_tree() or is_queued_for_deletion(): return
	_collected = true
	var pos := global_position
	AudioManager.play_collect_typed(scrap_data.get("id", ""))
	var sp = SPARKS.instantiate()
	var r: int = scrap_data.get("rarity", 0)
	if scrap_data.get("category", "") == "building":
		GameManager.add_to_inventory(scrap_data.duplicate())
		sp.position = pos; sp.color = Color("#9E9E9E")
		get_tree().current_scene.add_child(sp); sp.emitting = true
		get_tree().create_timer(1.0).timeout.connect(sp.queue_free)
		queue_free()
		return
	var val: int = scrap_data.get("value", 1) * GameManager.click_power
	for i in GameManager.click_power:
		if GameManager.inventory.size() < GameManager.max_slots:
			GameManager.add_to_inventory(scrap_data.duplicate())
	if r >= 2:
		var cam = get_tree().current_scene.get_node_or_null("Camera3D")
		if cam and cam.has_method("shake"):
			cam.shake(0.15 if r < 3 else 0.5, 5.0)
	sp.position = pos; sp.color = _RARITY_COLORS[r]
	get_tree().current_scene.add_child(sp); sp.emitting = true
	get_tree().create_timer(1.0).timeout.connect(sp.queue_free)
	var pp = POPUP.instantiate()
	pp.position = pos + Vector3(0, 1, 0)
	pp.setup(val, _RARITY_COLORS[r])
	get_tree().current_scene.add_child(pp)
	queue_free()
