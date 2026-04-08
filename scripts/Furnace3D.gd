extends Node3D

var _is_active: bool = false
var _glow_time: float = 0.0

func _ready() -> void:
	GameManager.sorted_changed.connect(_check)
	GameManager.ingots_changed.connect(_check)

func _check() -> void:
	set_active(GameManager.sorted_materials.size() > 0 or GameManager.ingots.size() > 0)

func _process(delta: float) -> void:
	_glow_time += delta
	var light = get_node_or_null("FireLight")
	var smoke = get_node_or_null("SmokePuff")
	if smoke == null:
		smoke = get_node_or_null("SmokeSpawn")
	if _is_active:
		var pulse: float = (sin(_glow_time * 3.0) + 1.0) * 0.5
		if light:
			light.light_energy = 0.5 + pulse * 0.5
		if smoke:
			smoke.emitting = true
	else:
		if light:
			light.light_energy = lerpf(light.light_energy, 0.0, delta * 2.0)
		if smoke:
			smoke.emitting = false

func set_active(active: bool) -> void:
	_is_active = active
