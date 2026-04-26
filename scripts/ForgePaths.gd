extends Node3D

const _DIFF  = preload("res://assets/textures/ground/path_floor_diff.jpg")
const _NOR   = preload("res://assets/textures/ground/path_floor_nor.jpg")
const _ROUGH = preload("res://assets/textures/ground/path_floor_rough.jpg")

const WIDTH := 2.5

# East entrance of the forge structure → Shop / Sell
const FORGE_EXIT := Vector3(9.0, 0.0, 0.0)
const SHOP_POS   := Vector3(35.0, 0.0, 18.0)
const SELL_POS   := Vector3(38.0, 0.0, -36.0)

func _ready() -> void:
	_add_path(FORGE_EXIT, SHOP_POS)
	_add_path(FORGE_EXIT, SELL_POS)

func _add_path(from: Vector3, to: Vector3) -> void:
	var dir    := to - from
	var length := dir.length()
	var mid    := (from + to) * 0.5

	var mi := MeshInstance3D.new()
	mi.position   = Vector3(mid.x, 0.01, mid.z)
	mi.rotation.y = atan2(dir.x, dir.z)

	var m := PlaneMesh.new()
	m.size = Vector2(WIDTH, length)
	mi.mesh = m
	mi.set_surface_override_material(0, _make_mat(length))
	add_child(mi)

func _make_mat(length: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color          = Color(0.82, 0.78, 0.70, 1)
	mat.albedo_texture        = _DIFF
	mat.normal_enabled        = true
	mat.normal_texture        = _NOR
	mat.normal_scale          = 1.0
	mat.roughness_texture     = _ROUGH
	mat.roughness             = 0.80
	mat.emission_enabled      = true
	mat.emission              = Color(0.18, 0.14, 0.04, 1)
	mat.emission_energy_multiplier = 0.6
	mat.uv1_scale             = Vector3(1.0, length / WIDTH, 1.0)
	return mat
