extends Node3D

@onready var rain_particles: CPUParticles3D = $RainParticles
@onready var dust_particles: CPUParticles3D = $DustParticles
@onready var fog_overlay: Node3D = $FogOverlay

func _ready() -> void:
	var ws = get_node_or_null("/root/WeatherSystem")
	if ws:
		ws.weather_changed.connect(_on_weather)
	rain_particles.emitting = false
	dust_particles.emitting = false

func _on_weather(weather: String) -> void:
	rain_particles.emitting = weather == "rain" or weather == "storm"
	dust_particles.emitting = weather == "windy" or weather == "storm"

	match weather:
		"storm":
			rain_particles.amount = 220
			rain_particles.initial_velocity_min = 9.0
			rain_particles.initial_velocity_max = 14.0
			dust_particles.amount = 200
			dust_particles.initial_velocity_min = 7.0
			dust_particles.initial_velocity_max = 13.0
			dust_particles.color = Color(0.60, 0.42, 0.18, 0.30)
		"windy":
			dust_particles.amount = 140
			dust_particles.initial_velocity_min = 3.5
			dust_particles.initial_velocity_max = 8.0
			dust_particles.color = Color(0.65, 0.48, 0.22, 0.22)
		"rain":
			rain_particles.amount = 80
			rain_particles.initial_velocity_min = 5.0
			rain_particles.initial_velocity_max = 7.0
