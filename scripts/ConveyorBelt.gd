extends Node3D

# Visual conveyor — activates when auto_sort is purchased
var active: bool = false
var _anim_offset: float = 0.0

func _ready() -> void:
	visible = false
	GameManager.upgrade_purchased.connect(_check)
	_check("")

func _check(_id: String) -> void:
	active = GameManager.upgrades.get("auto_sort", 0) > 0
	visible = active
	$Indicator.light_energy = 0.5 if active else 0.0

func _process(delta: float) -> void:
	if not active:
		return
	_anim_offset += delta * 2.0
	var belt_mat = $Belt.surface_material_override[0] as StandardMaterial3D
	if belt_mat:
		belt_mat.uv1_offset.x = _anim_offset
