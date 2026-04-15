extends Node3D

@onready var rain_particles: CPUParticles3D = $RainParticles
@onready var fog_overlay: Node3D = $FogOverlay

var _target_rain: bool = false
var _target_fog: bool = false

func _ready() -> void:
	var ws = get_node_or_null("/root/WeatherSystem")
	if ws:
		ws.weather_changed.connect(_on_weather)
	rain_particles.emitting = false

func _on_weather(weather: String) -> void:
	_target_rain = weather == "rain" or weather == "storm"
	_target_fog = weather == "foggy"
	rain_particles.emitting = _target_rain
	if weather == "storm":
		rain_particles.amount = 200
		rain_particles.initial_velocity_min = 8.0
		rain_particles.initial_velocity_max = 12.0
	else:
		rain_particles.amount = 80
		rain_particles.initial_velocity_min = 5.0
		rain_particles.initial_velocity_max = 7.0
	# Mgła zarządzana przez DayNightCycle — nie dotykamy tu fog_density
