extends Camera3D
const ZOOM_SPEED: float = 0.5
const ZOOM_MIN: float = 4.0
const ZOOM_MAX: float = 16.0
const PAN_SPEED: float = 10.0
const PAN_EDGE: float = 50.0
var _zoom_level: float = 8.0
var _target_pos: Vector3 = Vector3.ZERO
var _shake_amount: float = 0.0
var _shake_decay: float = 5.0
func _ready() -> void:
	_update_camera()
	GameManager.achievement_unlocked.connect(_on_ach)
func _on_ach(_id: String) -> void:
	shake(2.0)
func shake(amount: float = 3.0, decay: float = 5.0) -> void:
	_shake_amount = amount
	_shake_decay = decay
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_level = max(_zoom_level - ZOOM_SPEED, ZOOM_MIN); _update_camera()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_level = min(_zoom_level + ZOOM_SPEED, ZOOM_MAX); _update_camera()
func _process(delta: float) -> void:
	var vp = get_viewport().get_visible_rect().size
	var mouse = get_viewport().get_mouse_position()
	var pan = Vector3.ZERO
	if mouse.x < PAN_EDGE: pan.x -= 1
	elif mouse.x > vp.x - PAN_EDGE: pan.x += 1
	if mouse.y < PAN_EDGE: pan.z -= 1
	elif mouse.y > vp.y - PAN_EDGE: pan.z += 1
	var kb = Vector3.ZERO
	if Input.is_action_pressed("ui_left"): kb.x -= 1
	if Input.is_action_pressed("ui_right"): kb.x += 1
	if Input.is_action_pressed("ui_up"): kb.z -= 1
	if Input.is_action_pressed("ui_down"): kb.z += 1
	var tp = pan + kb
	if tp != Vector3.ZERO:
		_target_pos += tp.normalized() * PAN_SPEED * delta
		_target_pos.x = clamp(_target_pos.x, -10, 10)
		_target_pos.z = clamp(_target_pos.z, -10, 10)
	_update_camera()
	if _shake_amount > 0.05:
		h_offset = randf_range(-_shake_amount, _shake_amount) * 0.01
		v_offset = randf_range(-_shake_amount, _shake_amount) * 0.01
		_shake_amount = lerpf(_shake_amount, 0.0, _shake_decay * delta)
	else:
		h_offset = 0; v_offset = 0; _shake_amount = 0
func _update_camera() -> void:
	position = _target_pos + Vector3(0, _zoom_level, _zoom_level)
	look_at(_target_pos, Vector3.UP)
