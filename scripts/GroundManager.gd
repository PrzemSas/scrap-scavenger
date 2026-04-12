extends StaticBody3D

# Tint multipliers applied on top of the albedo texture.
# Color(1,1,1) = texture shows as-is. Darker = tinted.
var _skins: Dictionary = {
	"default": Color(1.0, 1.0, 1.0),
	"rust":    Color(1.0, 0.75, 0.55),
	"ash":     Color(0.65, 0.70, 0.80),
	"gold":    Color(1.0, 0.88, 0.50),
}

func _ready() -> void:
	if GameManager.has_signal("ground_changed"):
		GameManager.ground_changed.connect(_apply)
	var g = GameManager.get("current_ground")
	if g:
		_apply(g)
	else:
		_apply("default")

func _apply(skin_id: String) -> void:
	var mesh_node: MeshInstance3D = get_node_or_null("GroundMesh")
	if not mesh_node:
		return
	var mat = mesh_node.get_surface_override_material(0)
	if mat and mat is StandardMaterial3D:
		mat.albedo_color = _skins.get(skin_id, _skins["default"])
