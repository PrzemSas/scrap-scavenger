extends StaticBody3D

# Każdy skin: albedo, emission (color+energy), metallic, roughness
const _SKINS: Dictionary = {
	"default": {
		"albedo":   Color(0.92, 0.88, 0.84, 1),
		"emission": Color(0, 0, 0),
		"emit_e":   0.0,
		"metallic": 0.04,
		"rough":    0.92,
	},
	"rust": {
		"albedo":   Color(0.72, 0.42, 0.28, 1),
		"emission": Color(0.55, 0.12, 0.02),
		"emit_e":   0.35,
		"metallic": 0.18,
		"rough":    0.96,
	},
	"ash": {
		"albedo":   Color(0.52, 0.55, 0.62, 1),
		"emission": Color(0.04, 0.06, 0.14),
		"emit_e":   0.20,
		"metallic": 0.02,
		"rough":    0.98,
	},
	"gold": {
		"albedo":   Color(0.88, 0.74, 0.28, 1),
		"emission": Color(0.50, 0.35, 0.02),
		"emit_e":   0.55,
		"metallic": 0.45,
		"rough":    0.60,
	},
}

func _ready() -> void:
	GameManager.ground_changed.connect(_apply)
	_apply(GameManager.current_ground if GameManager.current_ground != "" else "default")

func _apply(skin_id: String) -> void:
	var s: Dictionary = _SKINS.get(skin_id, _SKINS["default"])
	var mesh_node: MeshInstance3D = get_node_or_null("GroundMesh")
	if not mesh_node:
		return
	var mat := mesh_node.get_surface_override_material(0) as StandardMaterial3D
	if not mat:
		return
	mat.albedo_color          = s.albedo
	mat.emission_enabled      = s.emit_e > 0.0
	mat.emission              = s.emission
	mat.emission_energy_multiplier = s.emit_e
	mat.metallic              = s.metallic
	mat.roughness             = s.rough
