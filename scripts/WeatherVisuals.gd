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
	# Fog handled by environment
	var env_node = get_tree().current_scene.get_node_or_null("WorldEnvironment")
	if env_node and env_node.environment:
		if _target_fog:
			env_node.environment.fog_density = 0.05
		else:
			env_node.environment.fog_density = 0.01
