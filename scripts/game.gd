## Состояние сцены и сюжет: питание участка, перегрузка, решётка, заявки на ПТ-1, финал прототипа.
class_name Game
extends Node

const LIMIT := 20
const LOAD := {"A": 10, "B": 4, "V": 14}

var W: World
var L: Lights
var P: Player
var wrist: Wrist
var S := {
	"qf0": false,   # вводной автомат (выбит)
	"qf1": true,    # А — освещение
	"qf2": false,   # Б — пульт
	"v": false,     # V — привод решётки, только с пульта
	"trips": 0, "entered": false, "gate": "closed", "t": 0.0, "ended": false, "dark": false, "raised_once": false,
}
var events := []
var on_power: Callable      # терминал и щиток подписываются
var on_toast: Callable
var on_end: Callable

func setup(w: World, l: Lights, p: Player, wr: Wrist) -> void:
	W = w; L = l; P = p; wrist = wr

func toast(txt: String, sec := 3.5) -> void:
	if on_toast.is_valid(): on_toast.call(txt, sec)

func goal(txt: String) -> void:
	S.goal = txt
	wrist.set_goal(txt)

func pager(txt: String) -> void:
	wrist.notify(txt)
	if not S.raised_once:
		toast("Новая заявка на ПТ-1 — нажми Tab", 4.0)

func later(sec: float, fn: Callable) -> void:
	events.append({"t": S.t + sec, "fn": fn})

## ---------- питание ----------
func load_a() -> int:
	if not S.qf0: return 0
	return (LOAD.A if S.qf1 else 0) + (LOAD.B if S.qf2 else 0) + (LOAD.V if S.v else 0)

func term_on() -> bool: return S.qf0 and S.qf2
func lights_a() -> bool: return S.qf0 and S.qf1

func _apply(prev: Dictionary) -> void:
	L.set_group("A", lights_a(), 0.12, 0.0)
	Audio.set_hum(1.0 if lights_a() else 0.0)
	if on_power.is_valid(): on_power.call(prev)
	_progress()

## любое переключение — только здесь: проверка перегрузки и обновление всего остального
func set_line(k: String, val: bool) -> String:
	var prev := S.duplicate()
	S[k] = val
	if k == "qf0" and not val: S.v = false
	if S.qf0 and load_a() > LIMIT:
		var over := load_a()
		S.qf0 = false; S.v = false; S.trips += 1
		Audio.play("bang")
		toast("Выбило вводной автомат: нагрузка %d А при пределе %d А" % [over, LIMIT])
		goal("Снова включи ввод на щитке ЩР-6. Нагрузка — не больше 20 А")
		_apply(prev)
		return "trip"
	_apply(prev)
	return "ok"

func _progress() -> void:
	if S.gate != "closed" or not S.entered: return
	if not S.qf0: goal("Включи питание участка на щитке ЩР-6 в нише справа")
	elif not S.qf2: goal("Подай питание на терминал — линия Б на щитке")
	else: goal("Открой решётку ГД-6 с терминала")

func enter_corridor() -> void:
	if S.entered: return
	S.entered = true
	pager("ЗАЯВКА 0001\nУЧ.6 · Восстановить питание.\nОткрыть ГД-6. Срочно.")
	later(1.2, func(): if not P.flash_on and not S.qf0: toast("Темно. F — фонарик", 4.0))
	_progress()

## ---------- решётка ----------
func open_gate() -> void:
	if S.gate != "closed": return
	S.gate = "opening"; W.gate.moving = true
	Audio.play("grind", -4.0); goal("")
	later(5.6, func():
		S.gate = "open"; W.gate.moving = false; Audio.play("heavy")
		later(1.4, func(): L.set_group("S7", true, 0.07, World.GATE_Z))
		later(5.5, func():
			pager("ЗАЯВКА 0002\nУЧ.7 · Неисправность.\nМашины на линии. Срочно.")
			goal("Иди дальше по коридору"))
		later(14.0, func(): Audio.play("clang", -14.0, 1.0, true)))

## ---------- финал: свет гаснет издалека, что-то идёт ----------
func _start_dark() -> void:
	if S.dark: return
	S.dark = true
	var far := W.lamps.filter(func(l): return l.grp == "S7" and l.pos.z < -95 and l.pos.z > -700)
	far.sort_custom(func(a, b): return a.pos.z < b.pos.z)
	for i in far.size():
		var l: Dictionary = far[i]
		later(i * 0.055, func(): l.dead = true)
	var dur := far.size() * 0.055
	if W.shaft: W.shaft.switch_off(dur * 0.9)
	later(0.5, func(): Audio.play("clang", -16.0, 0.9, true))
	later(dur * 0.5, func(): Audio.play("clang", -10.0, 0.95, true))
	later(dur + 1.5, func():
		Audio.play("clang", -6.0, 1.0, true)
		toast("Что-то идёт по коридору", 3.0))
	later(dur + 5.0, func(): Audio.play("clang", -2.0))
	later(dur + 8.0, func(): Audio.play("clang", 2.0))
	later(dur + 10.0, func():
		Audio.play("bang", -4.0)
		for l in W.lamps: l.dead = true
		P.flash_on = false; P.frozen = true
		pager("ЗАЯВКА 0003\nУЧ.7 · Исполнитель на месте.\nЗаявка принята."))
	later(dur + 14.0, end)

func end() -> void:
	if S.ended: return
	S.ended = true
	if on_end.is_valid(): on_end.call()

func update(dt: float) -> void:
	S.t += dt
	var i := events.size() - 1
	while i >= 0:
		if S.t >= events[i].t:
			var e = events[i]; events.remove_at(i); e.fn.call()
		i -= 1
	var pz := P.global_position.z
	if not S.entered and pz < -0.6: enter_corridor()
	if S.gate == "open" and pz < World.SHAFT[0] + 5.0 and W.shaft and not W.shaft.on:
		W.shaft.switch_on()
		Audio.play("relay", -6.0)
		later(1.5, func(): Audio.play("clang", -14.0, 0.7, true))
	if S.gate == "open" and pz < -45: _start_dark()
	## решётка и маячок
	if W.gate.moving: W.gate.open = min(1.0, W.gate.open + dt / 5.4)
	W.gate.node.position.y = W.gate.open * W.gate.lift + (sin(S.t * 40.0) * 0.004 if W.gate.moving else 0.0)
	W.gate.shape.disabled = W.gate.open > 0.6
	W.beacon.node.rotation.y += dt * 7.0 if W.gate.moving else 0.0
	W.beacon.lamp.material_override = Tex.glow("beacon_on", Color(1, 0.6, 0.12), 4.0) if W.gate.moving else Tex.plain("beacon_off", Color(0.23, 0.13, 0.02), 0.3)
	W.beacon.light.light_energy = 6.0 if W.gate.moving else 0.0
	## дверь
	W.door.open += (W.door.target - W.door.open) * min(1.0, dt * 2.2)
	W.door.pivot.rotation.y = W.door.open * 1.75
	W.door.shape.disabled = W.door.open > 0.6
	## щиток и индикатор пульта
	W.panel.update(S, load_a(), dt)
	W.console.led.material_override = Tex.glow("led_on", Color(0.2, 1, 0.4), 3.0) if term_on() else Tex.glow("led_off", Color(0.2, 0.05, 0.05))

func start() -> void:
	pager("ВЫЗОВ\nНеисправность.\nЭлектрощитовая · 6 этаж.")
	goal("Найди электрощитовую")
	_apply(S.duplicate())
