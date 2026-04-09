extends DirectionalLight3D
var _time:float=0.3
func _process(delta:float)->void:
	_time+=delta*0.02
	if _time>1.0: _time-=1.0
	light_energy=lerpf(0.15,0.8,maxf(sin(_time*PI),0.0))
	if _time<0.25: light_color=Color(0.15,0.2,0.4).lerp(Color(1,0.4,0.15),_time/0.25)
	elif _time<0.5: light_color=Color(1,0.4,0.15).lerp(Color(1,0.85,0.6),(_time-0.25)/0.25)
	elif _time<0.75: light_color=Color(1,0.85,0.6).lerp(Color(1,0.4,0.15),(_time-0.5)/0.25)
	else: light_color=Color(1,0.4,0.15).lerp(Color(0.15,0.2,0.4),(_time-0.75)/0.25)
	rotation_degrees.x=lerpf(-17.0,-70.0,sin(_time*PI))
