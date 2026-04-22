extends Node3D

const HALF: float   = 50.0
const STEP: float   = 12.5
const POST_R: float = 0.12
const POST_H: float = 3.8
const PIPE_R: float = 0.075
const RAIL_Y: Array = [0.45, 1.35, 2.4]

func _ready() -> void:
	var mat_post := _mat(Color(0.55, 0.28, 0.12, 1), 0.55, 0.82)
	var mat_pipe := _mat(Color(0.70, 0.35, 0.12, 1), 0.42, 0.88)

	var posts_ns: Array[Vector3] = []
	var rails_x:  Array[Vector3] = []
	var posts_ew: Array[Vector3] = []
	var rails_z:  Array[Vector3] = []

	var xs: Array[float] = []
	var v: float = -HALF
	while v <= HALF + 0.01:
		xs.append(v)
		v += STEP

	# N i S (z = ±HALF)
	for wz in [-HALF, HALF]:
		for px in xs:
			posts_ns.append(Vector3(px, POST_H * 0.5, wz))
		for i in range(xs.size() - 1):
			var cx := (xs[i] + xs[i + 1]) * 0.5
			for ry in RAIL_Y:
				rails_x.append(Vector3(cx, ry, wz))

	# E i W (x = ±HALF), narożniki pominięte
	for wx in [-HALF, HALF]:
		for pz in xs:
			if pz == -HALF or pz == HALF:
				continue
			posts_ew.append(Vector3(wx, POST_H * 0.5, pz))
		for i in range(xs.size() - 1):
			var cz := (xs[i] + xs[i + 1]) * 0.5
			for ry in RAIL_Y:
				rails_z.append(Vector3(wx, ry, cz))

	var post_mesh := _cyl_mesh(POST_R, POST_H)
	var rail_mesh := _cyl_mesh(PIPE_R, STEP)

	_make_multi(post_mesh, mat_post, posts_ns, Basis.IDENTITY)
	_make_multi(post_mesh, mat_post, posts_ew, Basis.IDENTITY)
	_make_multi(rail_mesh, mat_pipe, rails_x,  Basis(Vector3.FORWARD, PI * 0.5))
	_make_multi(rail_mesh, mat_pipe, rails_z,  Basis(Vector3.RIGHT,   PI * 0.5))

func _cyl_mesh(r: float, h: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius    = r
	m.bottom_radius = r
	m.height        = h
	return m

func _mat(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic     = metallic
	m.roughness    = roughness
	return m

func _make_multi(mesh: Mesh, mat: StandardMaterial3D,
		positions: Array[Vector3], rot: Basis) -> void:
	if positions.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh             = mesh
	mm.instance_count   = positions.size()
	for i in positions.size():
		mm.set_instance_transform(i, Transform3D(rot, positions[i]))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh        = mm
	mmi.material_override = mat
	add_child(mmi)
