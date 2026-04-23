extends Node3D

@onready var _player: Node3D = get_parent().get_node("Player")

const PIT_POSITIONS := [
	Vector3(-10, 0, -10),
	Vector3( 10, 0, -10),
	Vector3(-10, 0,  5),
	Vector3( 10, 0,  5),
]

# stone materials that fade out when player walks behind the forge
var _fade_mats: Array[StandardMaterial3D] = []

func _ready() -> void:
	_build_main_forge()
	_build_braziers()

func _process(delta: float) -> void:
	if not _player:
		return
	# fade tall forge parts when player is in the back half of the room
	var behind := _player.global_position.z < -3.5
	var target  := 0.18 if behind else 1.0
	for mat in _fade_mats:
		var c := mat.albedo_color
		c.a = lerpf(c.a, target, delta * 6.0)
		mat.albedo_color = c

# ── main forge structure ──────────────────────────────────────────────────────

func _build_main_forge() -> void:
	# Base block — always solid (below camera sightline regardless of player pos)
	_box(Vector3(0, 0.65, -6.0), Vector3(3.2, 1.3, 2.4), _stone(Color(0.30, 0.24, 0.18)))

	# Tall parts — fade when player walks behind
	_fbox(Vector3(0, 2.8,  -7.1),  Vector3(3.4, 3.0,  0.45), Color(0.18, 0.13, 0.09))
	_fbox(Vector3(0, 4.35, -6.3),  Vector3(3.6, 0.35, 2.1),  Color(0.18, 0.13, 0.09))
	_fbox(Vector3(0, 6.5,  -7.1),  Vector3(1.3, 4.3,  0.7),  Color(0.14, 0.10, 0.07))
	_fbox(Vector3(-1.55, 2.05, -6.35), Vector3(0.30, 2.8, 0.9), Color(0.18, 0.13, 0.09))
	_fbox(Vector3( 1.55, 2.05, -6.35), Vector3(0.30, 2.8, 0.9), Color(0.18, 0.13, 0.09))

	# Emissive forge opening — never fades
	_emit(Vector3(0, 0.92, -4.77), Vector3(1.80, 0.78, 0.06), Color(1.0, 0.52, 0.08), 4.0)
	_emit(Vector3(0, 0.53, -4.77), Vector3(2.00, 0.06, 0.06), Color(1.0, 0.30, 0.04), 2.5)
	_emit(Vector3(0, 0.01, -6.0),  Vector3(2.6,  0.05, 1.8),  Color(1.0, 0.26, 0.04), 1.8)

	# Spotlight from forge mouth
	var spot := SpotLight3D.new()
	spot.position         = Vector3(0, 1.1, -5.2)
	spot.rotation_degrees = Vector3(-12, 0, 0)
	spot.light_color      = Color(1.0, 0.52, 0.12)
	spot.light_energy     = 2.8
	spot.spot_range       = 8.0
	spot.spot_angle       = 42.0
	add_child(spot)

# ── braziers at each fire pit ─────────────────────────────────────────────────

func _build_braziers() -> void:
	var stone := _stone(Color(0.24, 0.19, 0.14))
	for pos in PIT_POSITIONS:
		_cyl(pos + Vector3(0, 0.22, 0), 0.60, 0.70, 0.44, stone)
		_cyl(pos + Vector3(0, 0.60, 0), 0.92, 0.62, 0.38, stone)

# ── mesh helpers ──────────────────────────────────────────────────────────────

func _box(pos: Vector3, size: Vector3, mat: StandardMaterial3D) -> void:
	var mi := MeshInstance3D.new()
	mi.position = pos
	var m := BoxMesh.new()
	m.size = size
	mi.mesh = m
	mi.set_surface_override_material(0, mat)
	add_child(mi)

func _fbox(pos: Vector3, size: Vector3, color: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color  = color
	mat.roughness     = 0.96
	mat.metallic      = 0.0
	mat.transparency  = BaseMaterial3D.TRANSPARENCY_ALPHA
	_fade_mats.append(mat)
	_box(pos, size, mat)

func _cyl(pos: Vector3, r_top: float, r_bot: float, h: float, mat: StandardMaterial3D) -> void:
	var mi := MeshInstance3D.new()
	mi.position = pos
	var m := CylinderMesh.new()
	m.top_radius      = r_top
	m.bottom_radius   = r_bot
	m.height          = h
	m.radial_segments = 12
	mi.mesh = m
	mi.set_surface_override_material(0, mat)
	add_child(mi)

func _emit(pos: Vector3, size: Vector3, color: Color, energy: float) -> void:
	var mi := MeshInstance3D.new()
	mi.position = pos
	var m := BoxMesh.new()
	m.size = size
	mi.mesh = m
	var mat := StandardMaterial3D.new()
	mat.emission_enabled           = true
	mat.emission                   = color
	mat.emission_energy_multiplier = energy
	mat.albedo_color               = color
	mi.set_surface_override_material(0, mat)
	add_child(mi)

func _stone(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness    = 0.96
	mat.metallic     = 0.0
	return mat
