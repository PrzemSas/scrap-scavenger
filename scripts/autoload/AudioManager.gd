extends Node

var _players: Array[AudioStreamPlayer] = []

func _ready() -> void:
	for i in 8:
		var p = AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)

func play_collect() -> void:
	_beep(800.0, 0.08)
func play_sell() -> void:
	_beep(1200.0, 0.1)
func play_sort_correct() -> void:
	_beep(1000.0, 0.06)
func play_sort_wrong() -> void:
	_beep(200.0, 0.15)
func play_smelt_done() -> void:
	_beep(900.0, 0.08)
func play_upgrade() -> void:
	_beep(700.0, 0.08)
func play_error() -> void:
	_beep(150.0, 0.2)
func play_achievement() -> void:
	_beep(1200.0, 0.1)
func play_prestige() -> void:
	_beep(600.0, 0.15)
func play_click() -> void:
	_beep(600.0, 0.03)

func _beep(freq: float, dur: float) -> void:
	var sr: float = 22050.0
	var samples: int = int(sr * dur)
	var audio = AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_8_BITS
	audio.mix_rate = int(sr)
	var data = PackedByteArray()
	data.resize(samples)
	for i in samples:
		var t: float = float(i) / sr
		var env: float = 1.0 - (t / dur)
		data[i] = int((sin(t * freq * TAU) * env * 0.5 + 0.5) * 255)
	audio.data = data
	for p in _players:
		if not p.playing:
			p.stream = audio
			p.volume_db = -12.0
			p.play()
			return
