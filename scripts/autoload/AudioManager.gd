extends Node

var _players: Array[AudioStreamPlayer] = []
const POOL_SIZE: int = 8

# Procedural beep generator for placeholder sounds
func _ready() -> void:
	for i in POOL_SIZE:
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)

func play_collect() -> void:
	_play_beep(800.0, 0.08)

func play_sell() -> void:
	_play_beep(1200.0, 0.1)
	# Double beep
	get_tree().create_timer(0.12).timeout.connect(func(): _play_beep(1600.0, 0.08))

func play_sort_correct() -> void:
	_play_beep(1000.0, 0.06)
	get_tree().create_timer(0.08).timeout.connect(func(): _play_beep(1400.0, 0.06))

func play_sort_wrong() -> void:
	_play_beep(200.0, 0.15)

func play_smelt_done() -> void:
	_play_beep(600.0, 0.05)
	get_tree().create_timer(0.07).timeout.connect(func(): _play_beep(900.0, 0.05))
	get_tree().create_timer(0.14).timeout.connect(func(): _play_beep(1200.0, 0.08))

func play_upgrade() -> void:
	_play_beep(500.0, 0.06)
	get_tree().create_timer(0.1).timeout.connect(func(): _play_beep(700.0, 0.06))
	get_tree().create_timer(0.2).timeout.connect(func(): _play_beep(1000.0, 0.1))

func play_error() -> void:
	_play_beep(150.0, 0.2)

func play_achievement() -> void:
	_play_beep(800.0, 0.06)
	get_tree().create_timer(0.1).timeout.connect(func(): _play_beep(1000.0, 0.06))
	get_tree().create_timer(0.2).timeout.connect(func(): _play_beep(1200.0, 0.06))
	get_tree().create_timer(0.3).timeout.connect(func(): _play_beep(1600.0, 0.12))

func play_prestige() -> void:
	for i in 6:
		var freq = 400.0 + i * 200.0
		get_tree().create_timer(i * 0.15).timeout.connect(func(): _play_beep(freq, 0.1))

func play_click() -> void:
	_play_beep(600.0, 0.03)

func _play_beep(freq: float, duration: float) -> void:
	var sample_rate = 22050.0
	var samples = int(sample_rate * duration)
	var audio = AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_8_BITS
	audio.mix_rate = int(sample_rate)
	audio.stereo = false
	var data = PackedByteArray()
	data.resize(samples)
	for i in samples:
		var t = float(i) / sample_rate
		var envelope = 1.0 - (t / duration)  # Linear fade
		var wave = sin(t * freq * TAU) * envelope
		data[i] = int((wave * 0.5 + 0.5) * 255)
	audio.data = data
	for p in _players:
		if not p.playing:
			p.stream = audio
			p.volume_db = -12.0
			p.play()
			return
	_players[0].stream = audio
	_players[0].play()
