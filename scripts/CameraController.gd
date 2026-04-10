extends Camera3D
var _zoom:float=14.0
var _target:Node3D=null
func _ready()->void:
	await get_tree().process_frame
	_target=get_tree().current_scene.get_node_or_null("Player")
func _unhandled_input(ev:InputEvent)->void:
	if ev is InputEventMouseButton:
		if ev.button_index==MOUSE_BUTTON_WHEEL_UP: _zoom=max(_zoom-1.0,7.0)
		elif ev.button_index==MOUSE_BUTTON_WHEEL_DOWN: _zoom=min(_zoom+1.0,24.0)
func _process(delta:float)->void:
	if not is_instance_valid(_target):
		_target=get_tree().current_scene.get_node_or_null("Player"); return
	var look_at_pos:=_target.global_position+Vector3(0,0.8,0)
	var cam_target:=_target.global_position+Vector3(0,_zoom,_zoom*0.75)
	global_position=global_position.lerp(cam_target,delta*7.0)
	look_at(look_at_pos)
