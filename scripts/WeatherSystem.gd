extends Node

signal weather_changed(weather: String)

var current_weather: String = "clear"
var _timer: float = 0.0
var weather_duration: float = 120.0  # seconds per weather phase

var weather_types: Array = [
	{"id": "clear", "spawn_mult": 1.0, "value_mult": 1.0, "desc": "Clear skies"},
	{"id": "windy", "spawn_mult": 1.3, "value_mult": 1.0, "desc": "Wind blows in more scrap"},
	{"id": "rain", "spawn_mult": 1.0, "value_mult": 1.5, "desc": "Rain washes out rare items"},
	{"id": "storm", "spawn_mult": 0.7, "value_mult": 2.0, "desc": "Storm! Less scrap, higher value"},
	{"id": "foggy", "spawn_mult": 1.0, "value_mult": 1.0, "desc": "Thick fog... mysterious"},
]

func _ready() -> void:
	_set_weather("clear")

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= weather_duration:
		_timer = 0.0
		_roll_weather()

func _roll_weather() -> void:
	var pick = weather_types[randi() % weather_types.size()]
	_set_weather(pick.id)

func _set_weather(w: String) -> void:
	current_weather = w
	weather_changed.emit(w)
	var config = get_weather_config()
	GameManager.notification.emit("☁ Weather: %s" % config.desc)

func get_weather_config() -> Dictionary:
	for w in weather_types:
		if w.id == current_weather:
			return w
	return weather_types[0]

func get_spawn_mult() -> float:
	return get_weather_config().spawn_mult

func get_value_mult() -> float:
	return get_weather_config().value_mult
