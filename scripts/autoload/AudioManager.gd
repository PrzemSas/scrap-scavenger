extends Node

var _players: Array[AudioStreamPlayer] = []
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _music_active: AudioStreamPlayer
var _music_fade_target: float = -22.0
var _music_fade_speed: float = 1.5  # dB/s

const TRACKS := {
	"junkyard": "res://assets/audio/theme_trashinus.mp3",
	"forge":    "res://assets/audio/theme_chainfire.mp3",
	"menu":     "res://assets/audio/theme_gorweld.mp3",
	"pause":    "res://assets/audio/pause_music.mp3",
}

# Playlisty per zona — losowa kolejność
const PLAYLISTS := {
	"junkyard": [
		"res://assets/audio/theme_trashinus.mp3",
		"res://assets/audio/theme_ambient1.mp3",
		"res://assets/audio/theme_ambient2.mp3",
		"res://assets/audio/theme_alligator1.wav",
		"res://assets/audio/theme_alligator2.wav",
	],
	"forge": [
		"res://assets/audio/theme_chainfire.mp3",
		"res://assets/audio/theme_chainfire2.mp3",
		"res://assets/audio/theme_alligator1.wav",
	],
	"menu": [
		"res://assets/audio/theme_gorweld.mp3",
	],
}

var _current_zone: String = ""
var _playlist: Array = []
var _playlist_index: int = 0

func _ready() -> void:
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music_a = AudioStreamPlayer.new()
	_music_a.bus = "Master"
	_music_a.volume_db = -80.0
	add_child(_music_a)
	_music_b = AudioStreamPlayer.new()
	_music_b.bus = "Master"
	_music_b.volume_db = -80.0
	add_child(_music_b)
	_music_active = _music_a

func _process(delta: float) -> void:
	if _music_active and _music_active.playing:
		var cur := _music_active.volume_db
		if not is_equal_approx(cur, _music_fade_target):
			_music_active.volume_db = move_toward(cur, _music_fade_target, _music_fade_speed * delta)
	# Auto-next track gdy skończy się aktualny
	if _current_zone != "" and _music_active and not _music_active.playing and _playlist.size() > 1:
		_playlist_index = (_playlist_index + 1) % _playlist.size()
		_play_path(_playlist[_playlist_index])

func play_music(track: String, vol_db: float = -22.0) -> void:
	var path: String = TRACKS.get(track, "")
	if path == "":
		return
	if _music_active.playing and _music_active.stream and \
			_music_active.stream.resource_path == path:
		_music_fade_target = vol_db
		return
	_play_path(path, vol_db)

func play_zone(zone: String, vol_db: float = -22.0) -> void:
	if zone == _current_zone:
		return
	_current_zone = zone
	var pl: Array = PLAYLISTS.get(zone, [])
	if pl.is_empty():
		play_music(zone, vol_db)
		return
	_playlist = pl.duplicate()
	_playlist.shuffle()
	_playlist_index = 0
	_play_path(_playlist[0], vol_db)

func _play_path(path: String, vol_db: float = -22.0) -> void:
	if _music_active.playing and _music_active.stream and \
			_music_active.stream.resource_path == path:
		_music_fade_target = vol_db
		return
	var stream := load(path) as AudioStream
	if not stream:
		return
	_music_active.stream = stream
	_music_active.volume_db = -80.0
	_music_active.play()
	_music_fade_target = vol_db

func stop_music() -> void:
	_music_fade_target = -80.0
	await get_tree().create_timer(1.2).timeout
	_music_active.stop()

func set_music_volume(vol_db: float) -> void:
	_music_fade_target = vol_db

func play_collect() -> void:
	_beep(800.0, 0.08)

func play_collect_typed(id: String) -> void:
	match id:
		"can":      _beep_multi(440.0, 0.12, [1.0, 2.0, 0.4])   # metaliczny clink
		"bolt":     _beep_multi(300.0, 0.10, [1.0, 1.5, 0.3])   # ciężki klęk
		"pipe":     _beep_multi(160.0, 0.22, [1.0, 3.0, 0.2])   # rezonans rury
		"cable":    _beep_square(700.0, 0.07)                    # elektryczny trzask
		"battery":  _beep(920.0, 0.09)                           # czysty beep
		"chip":     _beep(1600.0, 0.04)                          # krótki pisk
		"coil":     _beep_sweep(650.0, 150.0, 0.20)             # sprężyna boing↓
		"motor":    _beep_multi(95.0,  0.18, [1.0, 2.0, 3.0])   # buczenie silnika
		"gear":     _beep_square(220.0, 0.12)                    # metaliczny zgrzyt
		"gold":     _beep_multi(1400.0, 0.24, [1.0, 2.0, 0.5])  # jasny dzwonek
		"crystal":  _beep_sweep(2200.0, 800.0, 0.45)            # kryształowy ton↓
		_:          play_collect()
func play_sell() -> void:
	# Dwa szybkie wznoszące tony — "ka-ching"
	_beep_multi(600.0, 0.07, [1.0, 1.5])
	await get_tree().create_timer(0.07).timeout
	_beep_multi(900.0, 0.10, [1.0, 2.0])
func play_sort_correct() -> void:
	# Krótki czysty ping w górę
	_beep_sweep(700.0, 1100.0, 0.12)
func play_sort_wrong() -> void:
	# Niski brzęk — "nie"
	_beep_multi(180.0, 0.18, [1.0, 1.5, 0.5])
func play_smelt_done() -> void:
	# Metaliczny klang z harmonicznymi
	_beep_multi(520.0, 0.22, [1.0, 2.0, 3.0, 0.5])
func play_upgrade() -> void:
	# Trzy wznoszące tony
	_beep(500.0, 0.06)
	await get_tree().create_timer(0.06).timeout
	_beep(700.0, 0.06)
	await get_tree().create_timer(0.06).timeout
	_beep(1000.0, 0.10)
func play_error() -> void:
	_beep_square(140.0, 0.2)
func play_achievement() -> void:
	# Fanfara — cztery tony w górę
	for freq in [600.0, 750.0, 900.0, 1200.0]:
		_beep_multi(freq, 0.08, [1.0, 2.0])
		await get_tree().create_timer(0.07).timeout
func play_prestige() -> void:
	# Długi sweep w górę + harmoniczne — dramatyczny efekt
	_beep_sweep(300.0, 1800.0, 0.6)
	await get_tree().create_timer(0.1).timeout
	_beep_multi(900.0, 0.4, [1.0, 2.0, 3.0])
func play_click() -> void:
	_beep(600.0, 0.03)

func play_footstep() -> void:
	_footstep_thud()

func _play_wav(audio: AudioStreamWAV, vol_db: float = -12.0) -> void:
	for p in _players:
		if not p.playing:
			p.stream = audio
			p.volume_db = vol_db
			p.play()
			return

# Sinus z harmonicznymi — metaliczne dźwięki
func _beep_multi(freq: float, dur: float, harmonics: Array) -> void:
	var sr := 22050.0
	var samples := int(sr * dur)
	var audio := AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_8_BITS
	audio.mix_rate = int(sr)
	var data := PackedByteArray()
	data.resize(samples)
	for i in samples:
		var t := float(i) / sr
		var env := pow(1.0 - float(i) / samples, 1.5)
		var v := 0.0
		var total := 0.0
		for hi in harmonics.size():
			var amp: float = harmonics[hi]
			v += sin(t * freq * float(hi + 1) * TAU) * amp
			total += amp
		data[i] = int(clampf(v / total * env * 0.5 + 0.5, 0.0, 1.0) * 255)
	audio.data = data
	_play_wav(audio)

# Fala kwadratowa — ostry, elektryczny dźwięk
func _beep_square(freq: float, dur: float) -> void:
	var sr := 22050.0
	var samples := int(sr * dur)
	var audio := AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_8_BITS
	audio.mix_rate = int(sr)
	var data := PackedByteArray()
	data.resize(samples)
	for i in samples:
		var t := float(i) / sr
		var env := pow(1.0 - float(i) / samples, 2.0)
		var v := 1.0 if fmod(t * freq, 1.0) < 0.5 else -1.0
		data[i] = int(clampf(v * env * 0.45 + 0.5, 0.0, 1.0) * 255)
	audio.data = data
	_play_wav(audio)

# Sweep częstotliwości — sprężyna / kryształ
func _beep_sweep(freq_start: float, freq_end: float, dur: float) -> void:
	var sr := 22050.0
	var samples := int(sr * dur)
	var audio := AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_8_BITS
	audio.mix_rate = int(sr)
	var data := PackedByteArray()
	data.resize(samples)
	var phase := 0.0
	for i in samples:
		var progress := float(i) / float(samples)
		var freq := freq_start + (freq_end - freq_start) * progress
		phase += freq / sr * TAU
		var env := pow(1.0 - progress, 0.8)
		data[i] = int(clampf(sin(phase) * env * 0.5 + 0.5, 0.0, 1.0) * 255)
	audio.data = data
	_play_wav(audio)

# Miękki krok — filtrowany szum + niski thump, bez wysokich częstotliwości
func _footstep_thud() -> void:
	var sr := 22050.0
	var dur := 0.09
	var samples := int(sr * dur)
	var audio := AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_8_BITS
	audio.mix_rate = int(sr)
	var data := PackedByteArray()
	data.resize(samples)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var lp := 0.0  # stan filtra low-pass
	for i in samples:
		var progress := float(i) / float(samples)
		# Obwiednia: szybki atak, wolne zanikanie
		var env := exp(-progress * 14.0)
		# Szum przefiltrowany low-pass (alpha=0.12 → tylko niskie freq)
		lp = lerp(lp, rng.randf_range(-1.0, 1.0), 0.12)
		# Niski "thump" sinusowy (stąpnięcie)
		var thump := sin(progress * PI) * exp(-progress * 22.0)
		var v := (lp * 0.35 + thump * 0.65) * env
		data[i] = int(clampf(v * 0.5 + 0.5, 0.0, 1.0) * 255)
	audio.data = data
	_play_wav(audio, -22.0)

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
	_play_wav(audio)
