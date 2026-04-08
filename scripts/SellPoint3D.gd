extends Area3D

var _hovered: bool = false
var _bob_time: float = 0.0

func _ready() -> void:
	GameManager.inventory_changed.connect(_update_value)
	_update_value()

func _process(delta: float) -> void:
	_bob_time += delta
	if _hovered:
		$Sign.modulate.a = 0.6 + sin(_bob_time * 4.0) * 0.4
		$GlowLight.light_energy = 0.5 + sin(_bob_time * 3.0) * 0.2
	else:
		$Sign.modulate.a = 0.8
		$GlowLight.light_energy = 0.3

func _update_value() -> void:
	var total = 0
	for item in GameManager.inventory:
		total += item.get("value", 1)
	if total > 0:
		$ValueLabel.text = "%dc" % total
		$ValueLabel.visible = true
	else:
		$ValueLabel.visible = false

func _on_input_event(_cam: Node, event: InputEvent, _pos: Vector3, _norm: Vector3, _idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if GameManager.inventory.size() > 0:
			GameManager.sell_all()
			AudioManager.play_sell()

func _on_mouse_entered() -> void:
	_hovered = true

func _on_mouse_exited() -> void:
	_hovered = false
