extends Node3D
var _bob: float = 0.0
func _process(delta: float) -> void:
	_bob += delta
	$SignText.position.y = 1.3 + sin(_bob * 1.5) * 0.03
