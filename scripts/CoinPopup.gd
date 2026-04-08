extends Label3D

var _timer: float = 0.0
const DURATION: float = 0.8
const RISE_SPEED: float = 3.0

func setup(amount: int, color: Color) -> void:
	text = "+%d" % amount
	modulate = color

func _process(delta: float) -> void:
	_timer += delta
	position.y += RISE_SPEED * delta
	modulate.a = 1.0 - (_timer / DURATION)
	if _timer >= DURATION:
		queue_free()
