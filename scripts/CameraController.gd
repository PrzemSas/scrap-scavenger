extends Camera3D
var _zoom:float=8.0
var _target:Vector3=Vector3.ZERO
var _shake:float=0.0
func shake(amount:float=0.3,decay:float=5.0)->void:
	_shake=amount
func _unhandled_input(ev:InputEvent)->void:
	if ev is InputEventMouseButton:
		if ev.button_index==MOUSE_BUTTON_WHEEL_UP: _zoom=max(_zoom-0.5,4.0); _update()
		elif ev.button_index==MOUSE_BUTTON_WHEEL_DOWN: _zoom=min(_zoom+0.5,16.0); _update()
func _process(delta:float)->void:
	var kb=Vector3.ZERO
	if Input.is_action_pressed("ui_left"): kb.x-=1
	if Input.is_action_pressed("ui_right"): kb.x+=1
	if Input.is_action_pressed("ui_up"): kb.z-=1
	if Input.is_action_pressed("ui_down"): kb.z+=1
	if kb!=Vector3.ZERO:
		_target+=kb.normalized()*10.0*delta
		_target.x=clamp(_target.x,-10,10); _target.z=clamp(_target.z,-10,10)
		_update()
	if _shake>0.01:
		h_offset=randf_range(-_shake,_shake); v_offset=randf_range(-_shake,_shake)
		_shake=lerpf(_shake,0.0,5.0*delta)
	else: h_offset=0.0; v_offset=0.0
func _update()->void:
	position=_target+Vector3(0,_zoom,_zoom); look_at(_target,Vector3.UP)
