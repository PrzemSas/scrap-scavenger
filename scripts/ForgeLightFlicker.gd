extends OmniLight3D

var _t: float = 0.0
var _base: float
var _base_range: float
var _base_color: Color

func _ready() -> void:
	_base = light_energy
	_base_range = omni_range
	_base_color = light_color
	_t = randf() * 100.0  # faza startowa żeby światła nie migały synchronicznie

func _process(delta: float) -> void:
	_t += delta
	var flicker = sin(_t * 7.3) * 0.07 + sin(_t * 3.1) * 0.05 + sin(_t * 15.0) * 0.03
	light_energy = _base + _base * flicker + randf_range(-0.02, 0.02) * _base
	omni_range = _base_range + sin(_t * 1.8) * 1.2
	light_color = Color(
		_base_color.r,
		_base_color.g + sin(_t * 2.5) * 0.04,
		_base_color.b + sin(_t * 4.0) * 0.03
	)
