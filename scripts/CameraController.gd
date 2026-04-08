extends Camera3D

const ZOOM_SPEED: float = 0.5
const ZOOM_MIN: float = 4.0
const ZOOM_MAX: float = 16.0
const PAN_SPEED: float = 10.0
const PAN_EDGE: float = 50.0  # pixels from screen edge

var _zoom_level: float = 8.0
var _target_pos: Vector3 = Vector3.ZERO

func _ready() -> void:
	_update_camera()

func _unhandled_input(event: InputEvent) -> void:
	# Scroll to zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_level = max(_zoom_level - ZOOM_SPEED, ZOOM_MIN)
			_update_camera()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_level = min(_zoom_level + ZOOM_SPEED, ZOOM_MAX)
			_update_camera()

func _process(delta: float) -> void:
	# Edge panning
	var vp = get_viewport().get_visible_rect().size
	var mouse = get_viewport().get_mouse_position()
	var pan = Vector3.ZERO
	if mouse.x < PAN_EDGE:
		pan.x -= 1.0
	elif mouse.x > vp.x - PAN_EDGE:
		pan.x += 1.0
	if mouse.y < PAN_EDGE:
		pan.z -= 1.0
	elif mouse.y > vp.y - PAN_EDGE:
		pan.z += 1.0
	if pan != Vector3.ZERO:
		_target_pos += pan.normalized() * PAN_SPEED * delta
		_target_pos.x = clamp(_target_pos.x, -10, 10)
		_target_pos.z = clamp(_target_pos.z, -10, 10)
		_update_camera()
	# WASD pan
	var kb_pan = Vector3.ZERO
	if Input.is_action_pressed("ui_left"):
		kb_pan.x -= 1
	if Input.is_action_pressed("ui_right"):
		kb_pan.x += 1
	if Input.is_action_pressed("ui_up"):
		kb_pan.z -= 1
	if Input.is_action_pressed("ui_down"):
		kb_pan.z += 1
	if kb_pan != Vector3.ZERO:
		_target_pos += kb_pan.normalized() * PAN_SPEED * delta
		_target_pos.x = clamp(_target_pos.x, -10, 10)
		_target_pos.z = clamp(_target_pos.z, -10, 10)
		_update_camera()

func _update_camera() -> void:
	var offset = Vector3(0, _zoom_level, _zoom_level)
	position = _target_pos + offset
	look_at(_target_pos, Vector3.UP)
