extends OmniLight3D

var _t: float = 0.0
var _base: float = 0.6
var _base_range: float = 14.0

func _process(delta: float) -> void:
	_t += delta
	# Overlay trzech sinusoid o różnej częstotliwości + losowy szum = realistyczny flicker
	var flicker = sin(_t * 7.3) * 0.07 + sin(_t * 3.1) * 0.05 + sin(_t * 15.0) * 0.03
	light_energy = _base + flicker + randf_range(-0.02, 0.02)
	omni_range = _base_range + sin(_t * 1.8) * 1.2
	# Lekka zmiana koloru — od pomarańczowego do białawego
	light_color = Color(1.0, 0.5 + sin(_t * 2.5) * 0.05, 0.1 + sin(_t * 4.0) * 0.05)
