extends CharacterBody3D
const SPEED:=5.5
const GRAVITY:=22.0
var _footstep_t:float=0.0
func _ready()->void:
	add_to_group("player")
func _physics_process(delta:float)->void:
	var cam:Camera3D=get_viewport().get_camera_3d()
	var input_dir:=Vector2.ZERO
	if Input.is_action_pressed("ui_left"): input_dir.x-=1
	if Input.is_action_pressed("ui_right"): input_dir.x+=1
	if Input.is_action_pressed("ui_up"): input_dir.y-=1
	if Input.is_action_pressed("ui_down"): input_dir.y+=1
	var dir:=Vector3.ZERO
	if input_dir!=Vector2.ZERO:
		if cam:
			var cf:=-cam.global_basis.z; cf.y=0
			var cr:=cam.global_basis.x; cr.y=0
			if cf.length_squared()>0.001: cf=cf.normalized()
			if cr.length_squared()>0.001: cr=cr.normalized()
			dir=(cf*(-input_dir.y)+cr*input_dir.x).normalized()
		else:
			dir=Vector3(input_dir.x,0,input_dir.y).normalized()
	if dir.length_squared()>0:
		rotation.y=lerp_angle(rotation.y,atan2(-dir.x,-dir.z),0.18)
		_footstep_t+=delta
		if _footstep_t>=0.38:
			_footstep_t=0.0
			if AudioManager.has_method("play_footstep"): AudioManager.play_footstep()
	else:
		_footstep_t=0.0
	velocity.x=dir.x*SPEED
	velocity.z=dir.z*SPEED
	if not is_on_floor(): velocity.y-=GRAVITY*delta
	else: velocity.y=0.0
	move_and_slide()
