## Терминал диспетчерской — АСУ «Диспетчер-2». Другая система, чем ЩИТ-80: янтарный экран, свои команды.
## Сюда приходят заявки; TAKE переносит заявку на ПТ-1 и открывает электрозамок лестницы.
## Отправитель заявок не определён — это загадка сюжета.
class_name DispatchTerminal
extends Terminal

const AMB := "#ffb347"
const ADIM := "#a8692a"
const AERR := "#ff6a4a"

const DCMDS := {
	"HELP": ["HELP", "СПИСОК КОМАНД"],
	"LIST": ["LIST", "ЗАЯВКИ"],
	"READ": ["READ <НОМЕР>", "ПРОЧИТАТЬ ЗАЯВКУ"],
	"TAKE": ["TAKE <НОМЕР>", "ВЗЯТЬ ЗАЯВКУ НА ПТ-1"],
	"LOG": ["LOG", "ЖУРНАЛ ПУНКТА"],
	"CLS": ["CLS", "ОЧИСТИТЬ ЭКРАН"],
	"EXIT": ["EXIT", "ОТОЙТИ"],
}

func _init() -> void:
	fg = Color("#ffb347"); fg_dim = Color("#a8692a")
	scr_bg = Color(0.07, 0.035, 0.0); world_bg = Color(0.09, 0.045, 0.0)
	hint_text = "Пиши команды и жми Enter · правая кнопка мыши или F1 — отойти"

func powered() -> bool: return true

## сегодняшняя дата неизвестна — часы пункта сбиты
func _today() -> String:
	return "--.--.----"

func boot() -> void:
	out.clear(); lines.clear()
	say("АСУ «ДИСПЕТЧЕР-2»  ВЕР. 1.07", ADIM)
	say("ПУНКТ: ШЛЮЗ 6 · ДИСПЕТЧЕРСКАЯ", ADIM)
	say("СВЯЗЬ С ЦЕНТРОМ: НЕТ ОТВЕТА", ADIM)
	say("")
	say("ДЕЖУРНЫЙ НА МЕСТЕ.", AMB)
	if G.S.task_taken: say("НОВЫХ ЗАЯВОК НЕТ.", AMB)
	else: say("НОВЫХ ЗАЯВОК: 1.   ВВЕДИТЕ LIST", AMB)
	booted = true

func _orders() -> Array:
	return [
		["0001", _today(), "ШЛЮЗ 6 · 6 ЭТ.", "В РАБОТЕ" if G.S.task_taken else "НОВАЯ"],
		["4471", "20.03.2131", "УЧ.7", "НЕ ВЫПОЛНЕНА"],
		["4470", "19.03.2131", "УЧ.7 · СВЕТ", "НЕ ВЫПОЛНЕНА"],
		["4466", "02.03.2131", "ШЛЮЗ 6 · ЛИФТ Л-2", "НЕ ВЫПОЛНЕНА"],
	]

func _order_text(n: String) -> String:
	match n:
		"0001": return "ЗАЯВКА 0001 · ДАТА НЕ ОПРЕДЕЛЕНА%s\nМЕСТО: ШЛЮЗ 6, ЭТАЖ 6, ЭЛЕКТРОЩИТОВАЯ ЩР-6\nСУТЬ: НЕИСПРАВНОСТЬ ПИТАНИЯ УЧАСТКА 6.\nОТПРАВИТЕЛЬ: НЕ ОПРЕДЕЛЁН\nИСПОЛНИТЕЛЬ: ДЕЖУРНЫЙ (ЕДИНСТВЕННЫЙ НА ОБЪЕКТЕ)\nВЗЯТЬ НА ПТ-1:  TAKE 0001" % ""
		"4471": return "ЗАЯВКА 4471 · 20.03.2131\nМЕСТО: УЧАСТОК 7\nСУТЬ: МАШИНЫ НА ЛИНИИ.\nОТПРАВИТЕЛЬ: КАЛИНИН В.А.\nИСПОЛНИТЕЛЬ: СОМОВ — НЕ ВЕРНУЛСЯ"
		"4470": return "ЗАЯВКА 4470 · 19.03.2131\nМЕСТО: УЧАСТОК 7\nСУТЬ: ВОССТАНОВИТЬ ОСВЕЩЕНИЕ.\nИСПОЛНИТЕЛЬ: СОМОВ\nОТМЕТКА: «НЕ ДАВАТЬ СВЕТ НА 7-Й» (КАЛИНИН)"
		"4466": return "ЗАЯВКА 4466 · 02.03.2131\nМЕСТО: ШЛЮЗ 6, ЛИФТ СЛУЖЕБНЫЙ Л-2\nСУТЬ: ЛИФТ ОБЕСТОЧЕН, ПУЛЬТ ЗАБЛОКИРОВАН.\nНУЖНО: ПИТАНИЕ ШАХТЫ И КОД ПУЛЬТА."
	return ""

func exec(raw: String) -> void:
	var cmd := raw.strip_edges().to_upper()
	while cmd.contains("  "): cmd = cmd.replace("  ", " ")
	say(">" + cmd, ADIM)
	if cmd == "": return
	var p := cmd.split(" ")
	var c: String = {"?": "HELP", "LS": "LIST", "DIR": "LIST", "QUIT": "EXIT", "CLEAR": "CLS"}.get(p[0], p[0])
	var a1 := p[1] if p.size() > 1 else ""
	## номер заявки без команды — прочитать
	if _order_text(c) != "":
		say(_order_text(c)); return
	match c:
		"HELP":
			var t := "КОМАНДЫ:"
			for k in DCMDS: t += "\n  %-16s %s" % [DCMDS[k][0], DCMDS[k][1]]
			t += "\nЗАЯВКУ МОЖНО ОТКРЫТЬ ПО НОМЕРУ:  0001"
			say(t)
		"LIST":
			var t := "№     ДАТА        МЕСТО               СОСТОЯНИЕ"
			for o in _orders(): t += "\n%-5s %-11s %-19s %s" % o
			say(t)
			if not G.S.task_taken: say("ПРОЧИТАТЬ: READ 0001 · ВЗЯТЬ: TAKE 0001", ADIM)
		"READ", "TYPE":
			if a1 == "": say("?КАКУЮ ЗАЯВКУ? ПРИМЕР: READ 0001", AERR); return
			var n := a1.lpad(4, "0")
			if _order_text(n) == "": say("?НЕТ ЗАЯВКИ %s. СПИСОК: LIST" % a1, AERR); return
			say(_order_text(n))
		"TAKE":
			var n := a1.lpad(4, "0") if a1 != "" else ""
			if n == "": say("?КАКУЮ ЗАЯВКУ? ПРИМЕР: TAKE 0001", AERR); return
			if n != "0001":
				if _order_text(n) != "": say("ЗАЯВКА %s ЗАКРЫТА ЦЕНТРОМ. ВЗЯТЬ НЕЛЬЗЯ." % n, AERR)
				else: say("?НЕТ ЗАЯВКИ %s. СПИСОК: LIST" % a1, AERR)
				return
			if G.S.task_taken: say("ЗАЯВКА 0001 УЖЕ НА ПТ-1."); return
			Audio.play("relay")
			say("ЗАЯВКА 0001 ПЕРЕДАНА НА ПТ-1.", AMB)
			say("ДОПУСК НА ЛЕСТНИЦУ ВЫДАН. ЭЛЕКТРОЗАМОК ЛК-1 ОТКРЫТ.", AMB)
			G.take_task()
		"LOG":
			say("ЖУРНАЛ ПУНКТА · ШЛЮЗ 6\n02.03.31  ЛИФТ Л-2 ОБЕСТОЧЕН. ХОДИМ ПЕШКОМ.          КАЛИНИН\n19.03.31  СОМОВ УШЁЛ НА УЧ.7. СВЯЗИ НЕТ.            КАЛИНИН\n20.03.31  УХОЖУ НАВЕРХ. ЗАЯВКИ ПРИНИМАЕТ АВТОМАТ.   КАЛИНИН\n--.--.--  ......................................\n--.--.----  ВХОД ДЕЖУРНОГО. ЛИЧНОСТЬ НЕ ПОДТВЕРЖДЕНА.")
		"CLS":
			out.clear(); lines.clear(); screen_draw.queue_redraw()
		"EXIT":
			close()
		_:
			Audio.play("beep", -6.0)
			var g := Terminal._closest(c, DCMDS.keys())
			say("?НЕТ КОМАНДЫ «%s».%s" % [c, (" ВОЗМОЖНО: " + DCMDS[g][0]) if g != "" else " HELP — СПИСОК"], AERR)

func live_hint() -> String:
	var l := line.strip_edges().to_upper()
	if l == "": return "HELP — КОМАНДЫ · LIST — ЗАЯВКИ"
	var c: String = l.split(" ")[0]
	if DCMDS.has(c): return DCMDS[c][0] + " — " + DCMDS[c][1]
	var m := DCMDS.keys().filter(func(k): return k.begins_with(c))
	if m.size() == 1: return DCMDS[m[0]][0] + " — " + DCMDS[m[0]][1]
	if m.size() > 1: return "ЕСТЬ: " + " ".join(m)
	return "НЕТ ТАКОЙ КОМАНДЫ · HELP — СПИСОК"

func complete() -> void:
	var p := line.to_upper().split(" ")
	var w := p[p.size() - 1]
	var words: Array = DCMDS.keys() if p.size() == 1 else (["0001", "4471", "4470", "4466"] if p[0] in ["READ", "TAKE"] else [])
	var m := words.filter(func(x): return x.begins_with(w))
	if m.size() != 1: Audio.play("beep", -12.0); return
	line = line.substr(0, line.length() - w.length()) + m[0] + (" " if p.size() == 1 else "")
	Audio.play("key", -6.0); screen_draw.queue_redraw()

func power_changed(_prev: Dictionary) -> void:
	pass
