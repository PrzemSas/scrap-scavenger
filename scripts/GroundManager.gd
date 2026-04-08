extends MeshInstance3D

var skins: Dictionary = {
	"default": Color(0.14, 0.08, 0.04),
	"rust": Color(0.3, 0.12, 0.05),
	"ash": Color(0.08, 0.08, 0.1),
	"gold": Color(0.25, 0.2, 0.05),
}

func _ready() -> void:
	GameManager.ground_changed.connect(_on_ground_changed)
	_apply_skin(GameManager.current_ground)

func _on_ground_changed(skin_id: String) -> void:
	_apply_skin(skin_id)

func _apply_skin(skin_id: String) -> void:
	var color = skins.get(skin_id, skins["default"])
	var mat = get_surface_override_material(0) as StandardMaterial3D
	if mat:
		mat.albedo_color = color
