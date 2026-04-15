extends Camera3D

var _zoom: float = 14.0
var _target: Node3D = null
var _shake_amount: float = 0.0
var _shake_freq:  float = 5.0
var _shake_t:     float = 0.0

func _ready() -> void:
	await get_tree().process_frame
	_target = get_tree().current_scene.get_node_or_null("Player")

func shake(amount: float, freq: float = 5.0) -> void:
	_shake_amount = amount
	_shake_freq   = freq
	_shake_t      = 0.0

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		if   ev.button_index == MOUSE_BUTTON_WHEEL_UP:   _zoom = max(_zoom - 1.0, 7.0)
		elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN: _zoom = min(_zoom + 1.0, 24.0)

func _process(delta: float) -> void:
	if not is_instance_valid(_target):
		_target = get_tree().current_scene.get_node_or_null("Player")
		return
	var look_at_pos := _target.global_position + Vector3(0, 0.8, 0)
	var cam_target  := _target.global_position + Vector3(0, _zoom, _zoom * 0.75)
	global_position  = global_position.lerp(cam_target, delta * 7.0)
	look_at(look_at_pos)
	# Shake
	if _shake_amount > 0.0:
		_shake_t += delta * _shake_freq
		var ox: float = sin(_shake_t * 2.3) * _shake_amount
		var oy: float = cos(_shake_t * 3.7) * _shake_amount * 0.4
		global_position += Vector3(ox, oy, 0.0)
		_shake_amount = move_toward(_shake_amount, 0.0, delta * 5.0)
