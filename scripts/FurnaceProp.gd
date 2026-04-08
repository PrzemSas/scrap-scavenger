extends Node3D
var _is_active: bool = false
var _glow_time: float = 0.0
func _process(delta: float) -> void:
	_glow_time += delta
	var door_mat = $Door.surface_material_override[0] as StandardMaterial3D
	var light = $FireLight
	var smoke = $SmokeSpawn
	if _is_active:
		var pulse = (sin(_glow_time * 3.0) + 1.0) * 0.5
		door_mat.emission_energy_multiplier = 0.5 + pulse * 1.0
		light.light_energy = 0.5 + pulse * 0.5
		smoke.emitting = true
	else:
		door_mat.emission_energy_multiplier = 0.0
		light.light_energy = 0.0
		smoke.emitting = false
func set_active(active: bool) -> void:
	_is_active = active
