extends OmniLight3D

var _t: float = 0.0
var _base: float
var _base_range: float
var _orig_base: float
var _orig_range: float

func _ready() -> void:
	_t = randf() * 100.0
	_base = light_energy
	_base_range = omni_range
	_orig_base = _base
	_orig_range = _base_range
	_spawn_fire()
	_spawn_smoke()
	await get_tree().process_frame
	var dnc: Node = get_tree().current_scene.get_node_or_null("SunLight")
	if dnc and dnc.has_signal("is_night_changed"):
		dnc.is_night_changed.connect(_on_night_changed)
		if dnc.get("is_night"):
			_on_night_changed(true)

func _process(delta: float) -> void:
	_t += delta
	var f := sin(_t * 8.2) * 0.14 + sin(_t * 3.7) * 0.09 + sin(_t * 17.5) * 0.04
	light_energy = maxf(0.05, _base + _base * f + randf_range(-0.04, 0.04) * _base)
	omni_range = _base_range + sin(_t * 2.3) * 0.9
	light_color = Color(1.0, 0.35 + sin(_t * 3.1) * 0.07, 0.04 + sin(_t * 5.3) * 0.03)

func _on_night_changed(night: bool) -> void:
	if night:
		_base = _orig_base * 1.8
		_base_range = _orig_range * 1.4
		for ch in get_children():
			if ch is CPUParticles3D and ch.lifetime <= 1.5:
				ch.amount = 32
	else:
		_base = _orig_base
		_base_range = _orig_range
		for ch in get_children():
			if ch is CPUParticles3D and ch.lifetime <= 1.5:
				ch.amount = 22

func _spawn_fire() -> void:
	var p := CPUParticles3D.new()
	p.emitting = true
	p.amount = 22
	p.lifetime = 1.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(0.22, 0.08, 0.22)
	p.direction = Vector3(0.0, 1.0, 0.0)
	p.spread = 18.0
	p.gravity = Vector3(0, 0.6, 0)
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 2.8
	p.scale_amount_min = 0.06
	p.scale_amount_max = 0.20
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.90, 0.25, 1.0))
	grad.set_color(1, Color(1.0, 0.18, 0.02, 0.0))
	p.color_ramp = grad
	p.position = Vector3(0, 0.55, 0)
	add_child(p)

func _spawn_smoke() -> void:
	var p := CPUParticles3D.new()
	p.emitting = true
	p.amount = 14
	p.lifetime = 6.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(0.18, 0.05, 0.18)
	p.direction = Vector3(0.1, 1.0, 0.05)
	p.spread = 22.0
	p.gravity = Vector3(0.12, 0.06, 0)
	p.initial_velocity_min = 0.4
	p.initial_velocity_max = 1.4
	p.scale_amount_min = 0.10
	p.scale_amount_max = 0.42
	var grad := Gradient.new()
	grad.set_color(0, Color(0.28, 0.22, 0.18, 0.55))
	grad.set_color(1, Color(0.14, 0.11, 0.09, 0.0))
	p.color_ramp = grad
	p.position = Vector3(0, 1.3, 0)
	add_child(p)
