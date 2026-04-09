extends MeshInstance3D
var _skins:Dictionary={"default":Color(0.14,0.08,0.04),"rust":Color(0.3,0.12,0.05),"ash":Color(0.08,0.08,0.1),"gold":Color(0.25,0.2,0.05)}
func _ready()->void:
	if GameManager.has_signal("ground_changed"): GameManager.ground_changed.connect(_apply)
	var g=GameManager.get("current_ground")
	if g: _apply(g)
func _apply(skin_id:String)->void:
	var mat=get_surface_override_material(0)
	if mat and mat is StandardMaterial3D: mat.albedo_color=_skins.get(skin_id,_skins["default"])
