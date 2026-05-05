extends Label3D

var _t: float = 0.0
const DURATION: float = 1.05

func setup(amount: int, color: Color) -> void:
	text = "+%d" % amount
	modulate = color
	font_size = 48 + int(clampf(amount / 15.0, 0.0, 40.0))
	outline_size = 7
	outline_modulate = Color(0.0, 0.0, 0.0, 0.75)
	scale = Vector3(1.7, 1.7, 1.7)

func _process(delta: float) -> void:
	_t += delta
	# Scale: 1.7 -> 1.0 in first 0.18s, then hold
	var sc := lerpf(1.7, 1.0, minf(_t / 0.18, 1.0))
	scale = Vector3(sc, sc, sc)
	position.y += 3.8 * delta
	# Fade: solid until 0.65, then fade out
	modulate.a = 1.0 - maxf((_t - 0.65) / 0.40, 0.0)
	if _t >= DURATION:
		queue_free()
