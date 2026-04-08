extends MeshInstance3D

var _timer: float = 0.0
const DURATION: float = 0.4
var _color: Color = Color(1, 0.42, 0, 1)

func setup(color: Color) -> void:
	_color = color
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(_color.r, _color.g, _color.b, 0.8)
	mat.emission_enabled = true
	mat.emission = _color
	mat.emission_energy_multiplier = 2.0
	mat.no_depth_test = true
	material_override = mat
	rotation.x = -PI / 2

func _process(delta: float) -> void:
	_timer += delta
	var t: float = _timer / DURATION
	scale = Vector3.ONE * (1.0 + t * 3.0)
	var mat = material_override as StandardMaterial3D
	if mat:
		mat.albedo_color.a = (1.0 - t) * 0.8
		mat.emission_energy_multiplier = (1.0 - t) * 2.0
	if _timer >= DURATION:
		queue_free()
