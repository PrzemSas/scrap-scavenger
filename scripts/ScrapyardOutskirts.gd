extends Node3D

const INNER: float = 50.0
const OUTER: float = 110.0

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42

	# UNSHADED — kolor zawsze widoczny, nie zależy od oświetlenia
	var mat_dirt    := _mat(Color(0.52, 0.42, 0.28), false)
	var mat_ruin    := _mat(Color(0.62, 0.56, 0.48), false)
	var mat_rust    := _mat(Color(0.72, 0.32, 0.10), false)
	var mat_dark    := _mat(Color(0.38, 0.32, 0.26), false)
	var mat_chimney := _mat(Color(0.44, 0.40, 0.36), false)
	var mat_cap     := _mat(Color(0.18, 0.16, 0.14), false)

	_outer_ground(mat_dirt)
	_structures(rng, mat_ruin, mat_rust, mat_dark, mat_chimney, mat_cap)

# ── grunt zewnętrzny ────────────────────────────────────────────────────────

func _outer_ground(mat: StandardMaterial3D) -> void:
	var pm := PlaneMesh.new()
	pm.size = Vector2(OUTER * 2.0, OUTER * 2.0)
	var mi := MeshInstance3D.new()
	mi.mesh = pm
	mi.set_surface_override_material(0, mat)
	mi.position.y = -0.02
	add_child(mi)

# ── struktury w tle ─────────────────────────────────────────────────────────

func _structures(rng: RandomNumberGenerator,
		mat_ruin, mat_rust, mat_dark, mat_chimney, mat_cap) -> void:

	# Kominy
	var chimney_pos: Array[Vector3] = []
	var cap_pos:     Array[Vector3] = []
	for i in 10:
		var p := _ring(rng, 58.0, 90.0)
		chimney_pos.append(p + Vector3(0, 5.0, 0))
		cap_pos.append(p + Vector3(0, 9.6, 0))
	_multi_cyl(chimney_pos, 0.45, 0.38, 10.0, mat_chimney)
	_multi_cyl(cap_pos,     0.65, 0.65, 0.5,  mat_cap)

	# Ruiny ścian
	for i in 16:
		var p   := _ring(rng, 55.0, 95.0)
		var w   := rng.randf_range(4.0, 16.0)
		var h   := rng.randf_range(2.0, 7.0)
		var d   := rng.randf_range(0.6, 2.2)
		var rot := rng.randf_range(-PI, PI)
		_box_mi(p + Vector3(0, h * 0.5, 0), Vector3(w, h, d), rot, mat_ruin)

	# Góry złomu
	for i in 12:
		var p := _ring(rng, 53.0, 88.0)
		var r := rng.randf_range(3.0, 9.0)
		var h := rng.randf_range(1.5, 5.0)
		_cyl_mi(p + Vector3(0, h * 0.5, 0), r, r * 0.6, h, mat_rust)

	# Leżące belki
	for i in 14:
		var p   := _ring(rng, 53.0, 92.0)
		var l   := rng.randf_range(4.0, 14.0)
		var rot := rng.randf_range(-PI, PI)
		_box_mi(p + Vector3(0, 0.2, 0), Vector3(l, 0.4, 0.4), rot, mat_dark)

	# Zbiorniki
	for i in 10:
		var p := _ring(rng, 54.0, 82.0)
		var h := rng.randf_range(1.5, 4.0)
		_cyl_mi(p + Vector3(0, h * 0.5, 0), 1.2, 1.2, h, mat_rust)

# ── helpers ──────────────────────────────────────────────────────────────────

func _ring(rng: RandomNumberGenerator, mn: float, mx: float) -> Vector3:
	var a := rng.randf_range(0.0, TAU)
	var d := rng.randf_range(mn, mx)
	return Vector3(cos(a) * d, 0.0, sin(a) * d)

func _mat(color: Color, shaded: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color  = color
	if not shaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

func _box_mi(pos: Vector3, size: Vector3, rot_y: float,
		mat: StandardMaterial3D) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.set_surface_override_material(0, mat)
	mi.position   = pos
	mi.rotation.y = rot_y
	add_child(mi)

func _cyl_mi(pos: Vector3, r_top: float, r_bot: float, h: float,
		mat: StandardMaterial3D) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius    = r_top
	mesh.bottom_radius = r_bot
	mesh.height        = h
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	add_child(mi)

func _multi_cyl(positions: Array[Vector3], r_top: float, r_bot: float,
		h: float, mat: StandardMaterial3D) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius    = r_top
	mesh.bottom_radius = r_bot
	mesh.height        = h
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh             = mesh
	mm.instance_count   = positions.size()
	for i in positions.size():
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, positions[i]))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh        = mm
	mmi.material_override = mat
	add_child(mmi)
