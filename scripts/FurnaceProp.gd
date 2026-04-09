extends Node3D

var _is_active := false
var _glow_time := 0.0

func _process(delta):
    _glow_time += delta

    var door = $Door
    if door == null: return

    var mat = null
    if door is MeshInstance3D:
        mat = door.get_surface_override_material(0)
    if mat == null: return

    var light = $FireLight

    if _is_active:
        var pulse = (sin(_glow_time * 3.0) + 1.0) * 0.5
        mat.emission_energy_multiplier = 0.5 + pulse
        if light:
            light.light_energy = 0.5 + pulse * 0.5
