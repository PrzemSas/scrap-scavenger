extends DirectionalLight3D

@export var cycle_speed: float = 0.02
@export var min_energy: float = 0.15
@export var max_energy: float = 0.8

var _time: float = 0.3

var day_color: Color = Color(1, 0.85, 0.6)
var sunset_color: Color = Color(1, 0.4, 0.15)
var night_color: Color = Color(0.15, 0.2, 0.4)

func _process(delta: float) -> void:
	_time += delta * cycle_speed
	if _time > 1.0:
		_time -= 1.0
	
	var energy_curve: float = sin(_time * PI)
	light_energy = lerpf(min_energy, max_energy, maxf(energy_curve, 0.0))
	
	if _time < 0.25:
		light_color = night_color.lerp(sunset_color, _time / 0.25)
	elif _time < 0.5:
		light_color = sunset_color.lerp(day_color, (_time - 0.25) / 0.25)
	elif _time < 0.75:
		light_color = day_color.lerp(sunset_color, (_time - 0.5) / 0.25)
	else:
		light_color = sunset_color.lerp(night_color, (_time - 0.75) / 0.25)
	
	rotation_degrees.x = lerpf(-17.0, -70.0, sin(_time * PI))
