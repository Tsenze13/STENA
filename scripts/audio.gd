## Звук: всё синтезируется при запуске (файлов нет). Автозагрузка «Audio».
## Шины: Master ← Reverb (длинный хвост коридора) ← Far (глухой далёкий звук).
extends Node

const SR := 22050
var streams := {}
var players: Array[AudioStreamPlayer] = []
var hum: AudioStreamPlayer
var amb: AudioStreamPlayer
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.seed = 7
	_buses()
	_make_all()
	for i in 16:
		var p := AudioStreamPlayer.new(); add_child(p); players.append(p)
	set_volume(0.6)
	amb = AudioStreamPlayer.new(); amb.stream = streams.amb; amb.volume_db = -16; amb.bus = "Reverb"; add_child(amb)
	hum = AudioStreamPlayer.new(); hum.stream = streams.hum; hum.volume_db = -80; add_child(hum)

func start() -> void:
	if not amb.playing: amb.play()
	if not hum.playing: hum.play()

func _buses() -> void:
	if AudioServer.get_bus_index("Reverb") == -1:
		AudioServer.add_bus(); var i := AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, "Reverb"); AudioServer.set_bus_send(i, "Master")
		var rv := AudioEffectReverb.new(); rv.room_size = 0.95; rv.damping = 0.35; rv.wet = 0.25; rv.dry = 0.8; rv.spread = 1.0
		AudioServer.add_bus_effect(i, rv)
		AudioServer.add_bus(); var j := AudioServer.bus_count - 1
		AudioServer.set_bus_name(j, "Far"); AudioServer.set_bus_send(j, "Reverb")
		var lp := AudioEffectLowPassFilter.new(); lp.cutoff_hz = 900
		AudioServer.add_bus_effect(j, lp)

## воспроизвести звук; far — через глухую шину (далеко)
func play(name: String, db := 0.0, pitch := 1.0, far := false) -> void:
	if not streams.has(name):
		return
	var s = streams[name]
	if s is Array:
		s = s[_rng.randi() % s.size()]
	for p in players:
		if not p.playing:
			p.stream = s; p.volume_db = db; p.pitch_scale = pitch; p.bus = "Far" if far else "Reverb"; p.play()
			return

func set_hum(v: float) -> void:
	hum.volume_db = lerp(-60.0, -28.0, clamp(v, 0.0, 1.0)) if v > 0.01 else -80.0

func set_volume(v: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(max(v * 0.4, 0.0005)))  # громкость 100% ≈ −8 дБ: синтез громкий

## ---------- синтез ----------
func _wav(data: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var bytes := PackedByteArray(); bytes.resize(data.size() * 2)
	for i in data.size():
		bytes.encode_s16(i * 2, int(clamp(data[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS; w.mix_rate = SR; w.stereo = false; w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD; w.loop_begin = 0; w.loop_end = data.size()
	return w

func _buf(sec: float) -> PackedFloat32Array:
	var b := PackedFloat32Array(); b.resize(int(sec * SR)); return b

## шум через простой фильтр: lp — доля сглаживания (0..1), hp — вычитание медленной части
func _noise(sec: float, amp: float, decay: float, lp := 1.0, hp := 0.0) -> PackedFloat32Array:
	var b := _buf(sec); var y := 0.0; var slow := 0.0
	for i in b.size():
		var t := float(i) / SR
		y += (_rng.randf_range(-1, 1) - y) * lp
		slow += (y - slow) * 0.02
		var v := y - slow * hp
		b[i] = v * amp * exp(-t * decay)
	return b

func _tone(sec: float, f0: float, f1: float, amp: float, decay: float, wave := "sin") -> PackedFloat32Array:
	var b := _buf(sec); var ph := 0.0
	for i in b.size():
		var t := float(i) / SR
		var f: float = lerp(f0, f1, t / sec)
		ph += TAU * f / SR
		var w := sin(ph)
		if wave == "sq": w = 1.0 if w > 0 else -1.0
		elif wave == "saw": w = fmod(ph / TAU, 1.0) * 2.0 - 1.0
		b[i] = w * amp * exp(-t * decay)
	return b

func _mix(a: PackedFloat32Array, b: PackedFloat32Array, offset := 0) -> PackedFloat32Array:
	var n: int = max(a.size(), b.size() + offset)
	var o := PackedFloat32Array(); o.resize(n)
	for i in a.size(): o[i] = a[i]
	for i in b.size(): o[i + offset] += b[i]
	return o

func _make_all() -> void:
	## щелчок автомата: удар + сухой треск
	streams.click = _wav(_mix(_tone(0.18, 180, 60, 0.6, 25), _noise(0.04, 0.4, 90, 1.0, 1.0)))
	streams.heavy = _wav(_mix(_tone(0.4, 110, 40, 0.8, 9), _noise(0.08, 0.5, 40, 0.6, 1.0)))
	streams.bang = _wav(_mix(_tone(0.9, 80, 30, 1.0, 4), _noise(0.6, 0.8, 6, 0.35)))
	streams.key = _wav(_noise(0.02, 0.25, 200, 1.0, 1.0))
	var steps := []
	for k in 4:
		steps.append(_wav(_mix(_noise(0.09, 0.5, 45, 0.25), _tone(0.06, 90 + k * 8, 50, 0.3, 50))))
	streams.step = steps
	streams.beep = _wav(_tone(0.12, 880, 880, 0.18, 6, "sq"))
	streams.beep_low = _wav(_tone(0.3, 220, 220, 0.2, 4, "sq"))
	streams.beep_hi = _wav(_tone(0.08, 1200, 1200, 0.15, 8, "sq"))
	var pg := _tone(0.08, 2000, 2000, 0.12, 2, "sq")
	pg = _mix(pg, _tone(0.08, 2000, 2000, 0.12, 2, "sq"), int(0.14 * SR))
	pg = _mix(pg, _tone(0.14, 2400, 2400, 0.12, 2, "sq"), int(0.28 * SR))
	streams.pager = _wav(pg)
	streams.relay = _wav(_mix(_tone(0.08, 240, 120, 0.4, 40), _noise(0.02, 0.25, 150, 1.0, 1.0)))
	streams.door = _wav(_mix(_grind(1.4, 0.45, 0.05), _tone(0.4, 140, 60, 0.5, 8)))
	streams.grind = _wav(_grind(5.2, 0.6, 0.03))
	streams.clang = _wav(_clang())
	streams.amb = _wav(_ambience(), true)
	streams.hum = _wav(_hum(), true)

## скрежет: шум через «плавающий» резонанс + низкий гул
func _grind(sec: float, amp: float, lp: float) -> PackedFloat32Array:
	var b := _buf(sec); var y := 0.0; var y2 := 0.0; var ph := 0.0
	for i in b.size():
		var t := float(i) / SR
		var env: float = min(1.0, t / 0.2) * min(1.0, (sec - t) / 0.3)
		var mod := 0.5 + 0.5 * sin(t * 7.0 + sin(t * 2.3) * 3.0)
		y += (_rng.randf_range(-1, 1) - y) * (lp + mod * 0.08)
		y2 += (y - y2) * 0.3
		ph += TAU * (45.0 + mod * 20.0) / SR
		b[i] = (y2 * 3.0 + fmod(ph / TAU, 1.0) * 0.3 - 0.15) * amp * env
	return b

## далёкий металлический удар: частичные тона разной длины
func _clang() -> PackedFloat32Array:
	var b := _buf(2.6)
	for p in [[180.0, 1.0, 2.5], [431.0, 0.6, 1.8], [797.0, 0.4, 1.2], [1263.0, 0.25, 0.8], [2310.0, 0.15, 0.5]]:
		var f: float = p[0] * _rng.randf_range(0.98, 1.02)
		for i in b.size():
			var t := float(i) / SR
			b[i] += sin(TAU * f * t) * p[1] * 0.3 * exp(-t * 4.0 / p[2])
	return b

## фон: «дыхание» Стены (низкий шум с медленной волной) + суббас; длина кратна периоду петли
func _ambience() -> PackedFloat32Array:
	var b := _buf(8.0); var y := 0.0; var y2 := 0.0
	for i in b.size():
		var t := float(i) / SR
		var cut := 0.006 + 0.004 * (0.5 + 0.5 * sin(TAU * t / 8.0))
		y += (_rng.randf_range(-1, 1) - y) * cut
		y2 += (y - y2) * cut
		b[i] = y2 * 9.0 + sin(TAU * 38.0 * t) * 0.08
	## сгладить шов петли
	for i in 2000:
		var k := float(i) / 2000.0
		b[i] = b[i] * k + b[b.size() - 2000 + i] * (1.0 - k)
	return b

## сетевой гул 50 Гц: 100 Гц и гармоники, ровно целое число периодов
func _hum() -> PackedFloat32Array:
	var b := _buf(1.0)
	for i in b.size():
		var t := float(i) / SR
		b[i] = (fmod(100.0 * t, 1.0) * 2.0 - 1.0) * 0.12 + sin(TAU * 200.0 * t) * 0.06 + sin(TAU * 300.0 * t) * 0.03
	return b
