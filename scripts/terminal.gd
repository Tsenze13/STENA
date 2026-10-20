## Терминал ЩИТ-80: язык команд, файлы, управление питанием и решёткой.
## Ввод — по физическим клавишам: раскладку переключать не нужно.
class_name Terminal
extends Control

var G: Game
var wrist: Wrist
var is_open := false
var booted := false
var line := ""
var hist: Array[String] = []
var hi := -1
var queue := []            # строки, которые ещё «печатаются»
var lines: Array[String] = []
var out: RichTextLabel
var input_label: Label
var live: Label
var body_box: Control
var typing := 0.0
var on_close: Callable
var screen_draw: Control   # экран в мире (SubViewport пульта)
var font: Font
## вид экрана (у других систем — свои цвета, см. dispatch_terminal.gd)
var fg := Color("#7dff9a")
var fg_dim := Color("#3fa35a")
var scr_bg := Color(0.02, 0.07, 0.03)
var world_bg := Color(0.012, 0.08, 0.04)
var hint_text := "Пиши команды и жми Enter · Tab — дописать · Esc — отойти от терминала"

const GREEN := "#7dff9a"
const WARN := "#ffd36b"
const ERR := "#ff7a6a"
const DIMC := "#3fa35a"

func setup(g: Game, wr: Wrist, world_screen_vp: SubViewport) -> void:
	G = g; wrist = wr
	var f := SystemFont.new(); f.font_names = PackedStringArray(["PT Mono", "Consolas", "DejaVu Sans Mono", "Liberation Mono", "Courier New", "monospace"]); font = f
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new(); dim.color = Color(0, 0, 0, 0.55); dim.set_anchors_preset(Control.PRESET_FULL_RECT); add_child(dim)
	var cc := CenterContainer.new(); cc.set_anchors_preset(Control.PRESET_FULL_RECT); add_child(cc)
	var vb := VBoxContainer.new(); vb.add_theme_constant_override("separation", 10); cc.add_child(vb)
	## корпус монитора и экран
	var body := PanelContainer.new()
	var sb := StyleBoxFlat.new(); sb.bg_color = Color(0.11, 0.11, 0.095); sb.set_corner_radius_all(22); sb.set_content_margin_all(24)
	sb.border_color = Color(0.17, 0.17, 0.14); sb.set_border_width_all(3)
	body.add_theme_stylebox_override("panel", sb)
	body.custom_minimum_size = Vector2(820, 560)
	self.body_box = body
	vb.add_child(body)
	var scr := PanelContainer.new()
	var sb2 := StyleBoxFlat.new(); sb2.bg_color = scr_bg; sb2.set_corner_radius_all(14); sb2.set_content_margin_all(16)
	scr.add_theme_stylebox_override("panel", sb2)
	body.add_child(scr)
	var inner := VBoxContainer.new(); scr.add_child(inner)
	out = RichTextLabel.new(); out.bbcode_enabled = true; out.scroll_following = true; out.size_flags_vertical = Control.SIZE_EXPAND_FILL
	out.add_theme_font_override("normal_font", font); out.add_theme_font_size_override("normal_font_size", 17)
	out.add_theme_color_override("default_color", fg)
	out.add_theme_color_override("font_shadow_color", Color(fg, 0.35)); out.add_theme_constant_override("shadow_outline_size", 4)
	inner.add_child(out)
	input_label = Label.new(); input_label.add_theme_font_override("font", font); input_label.add_theme_font_size_override("font_size", 17)
	input_label.add_theme_color_override("font_color", fg)
	inner.add_child(input_label)
	live = Label.new(); live.add_theme_font_override("font", font); live.add_theme_font_size_override("font_size", 14)
	live.add_theme_color_override("font_color", fg_dim); live.clip_text = true
	inner.add_child(live)
	var hint := Label.new(); hint.text = hint_text
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; hint.add_theme_color_override("font_color", Color(0.55, 0.52, 0.46))
	vb.add_child(hint)
	visible = false
	## экран в мире
	screen_draw = _ScreenDraw.new(); screen_draw.term = self; screen_draw.size = Vector2(320, 240)
	world_screen_vp.add_child(screen_draw)

## рисует последние строки на кинескопе пульта
class _ScreenDraw extends Control:
	var term
	func _draw() -> void:
		var on: bool = term.powered()
		draw_rect(Rect2(Vector2.ZERO, size), term.world_bg if on else Color(0.02, 0.02, 0.02))
		if not on: return
		var ls: Array = term.lines.slice(max(0, term.lines.size() - 13))
		for i in ls.size():
			draw_string(term.font, Vector2(14, 22 + i * 16), str(ls[i]).substr(0, 38), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, term.fg)
		draw_string(term.font, Vector2(14, 22 + ls.size() * 16), ">" + term.line + "_", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, term.fg)
		var y := 0.0
		while y < size.y:
			draw_rect(Rect2(0, y, size.x, 1), Color(0, 0, 0, 0.25)); y += 3

## есть ли питание (у пульта ЩИТ-80 — линия Б; у других терминалов — свои правила)
func powered() -> bool: return G.term_on()

func say(text: String, col := "") -> void:
	for l in text.split("\n"):
		queue.append([l, col])

func _process(dt: float) -> void:
	## печать по строке за раз — быстро, но с ощущением старого терминала
	typing -= dt
	while queue.size() > 0 and typing <= 0:
		var q = queue.pop_front()
		var txt: String = q[0].replace("[", "[lb]")
		out.append_text(("[color=%s]%s[/color]\n" % [q[1], txt]) if q[1] != "" else txt + "\n")
		lines.append(q[0])
		if lines.size() > 200: lines.remove_at(0)
		typing = 0.035
		screen_draw.queue_redraw()
	if is_open:
		input_label.text = "> " + line + ("█" if int(Time.get_ticks_msec() / 500) % 2 == 0 else " ")
		live.text = live_hint()

func flush() -> void:
	while queue.size() > 0:
		typing = 0
		_process(0.0)

func text() -> String:
	flush()
	return out.get_parsed_text()

func boot() -> void:
	out.clear(); lines.clear()
	say("ЩИТ-80  ВЕРСИЯ 4.1   (С) ЗАВОД «ЭКВАТОР» 1986", DIMC)
	say("ПРОВЕРКА ПАМЯТИ ......... 64К  НОРМА", DIMC)
	say("ПУЛЬТ ДЕЖУРНОГО · УЧАСТОК 6")
	say("ПОСЛЕДНИЙ ВХОД: 20.03.1991  03:12  (КАЛИНИН В.)")
	say("")
	say("НОВЫЕ ЗАЯВКИ: 1.   ВВЕДИТЕ HELP ДЛЯ СПИСКА КОМАНД.", WARN)
	booted = true

func _file(f: String) -> String:
	match f:
		"LOG.TXT":
			return "ЖУРНАЛ СМЕНЫ · УЧАСТОК 6\n14.03.91  Опять гул за решёткой, со стороны 7-го. Свет на 7-м не давал.\n17.03.91  Машины на линии 7. Ходят по ночам, когда дают ток.\n          Шум от них — как от лифта, только ближе.\n19.03.91  Пропал Сомов. Ушёл чинить свет на 7-м. Рация молчит.\n20.03.91  Решётку закрыл. Код сбросил на год ввода участка.\n          Если ты это читаешь — не давай свет на 7-й.\n          Они идут на ток.                         В.К."
		"MANUAL.TXT":
			return "ИНСТРУКЦИЯ ДЕЖУРНОГО ЭЛЕКТРИКА\n1. Ввод щита ЩР-6 рассчитан на %d А. При перегрузке\n   вводной автомат QF0 отключается. Включать вручную на щите.\n2. Нагрузки: А — освещение %d А, Б — пульт %d А,\n   V — привод решётки ГД-6 %d А.\n3. Линия V управляется только с пульта:  POWER V ON\n   Линии А и Б можно отключать и с пульта:  POWER A OFF\n4. Решётка открывается при поданном питании привода:\n   OPEN GD6 <КОД>\n5. Состояние участка:  STATUS" % [Game.LIMIT, Game.LOAD.A, Game.LOAD.B, Game.LOAD.V]
		"MAIL.TXT":
			var d := Time.get_date_dict_from_system()
			var ds := "%02d.%02d.%d" % [d.day, d.month, d.year]
			return "ВХОДЯЩИЕ ЗАЯВКИ\n4471  20.03.1991  УЧ.7  МАШИНЫ НА ЛИНИИ        НЕ ВЫПОЛНЕНА\n0001  %s  УЧ.6  НЕИСПРАВНОСТЬ ЭЛЕКТРОЩИТОВОЙ\n                         ИСПОЛНИТЕЛЬ: НАЗНАЧЕН\n                         СТАТУС: ИСПОЛНИТЕЛЬ НА МЕСТЕ\nОТПРАВИТЕЛЬ: —" % ds
	return ""

func _status() -> String:
	var S := G.S
	var st := func(on): return "ВКЛ " if on else "ОТКЛ"
	return "УЧАСТОК 6 · ЩИТ ЩР-6 · ВВОД %d А · %s\n  A  ОСВЕЩЕНИЕ    %2d А   %s\n  Б  ПУЛЬТ        %2d А   %s\n  V  ПРИВОД ГД-6  %2d А   %s\nНАГРУЗКА: %d / %d А\nРЕШЁТКА ГД-6: %s" % [
		Game.LIMIT, "НОРМА" if S.qf0 else "ОТКЛ", Game.LOAD.A, st.call(S.qf1), Game.LOAD.B, st.call(S.qf2), Game.LOAD.V, st.call(S.v),
		G.load_a(), Game.LIMIT, "ЗАКРЫТА" if S.gate == "closed" else "ОТКРЫТА"]

const LINE := {"A": "qf1", "B": "qf2", "V": "v"}
const FILES := ["LOG.TXT", "MANUAL.TXT", "MAIL.TXT"]
const NOTE_NAME := {"LOG.TXT": "Журнал смены, уч. 6", "MANUAL.TXT": "Инструкция дежурного", "MAIL.TXT": "Входящие заявки пульта"}
## команда → [как писать, что делает, подробно]
const CMDS := {
	"HELP": ["HELP [КОМАНДА]", "СПИСОК КОМАНД", "HELP POWER — ПОДРОБНО ПРО КОМАНДУ POWER."],
	"DIR": ["DIR", "СПИСОК ФАЙЛОВ", "ПОКАЗЫВАЕТ ФАЙЛЫ В ПАМЯТИ ПУЛЬТА."],
	"READ": ["READ <ФАЙЛ>", "ПРОЧИТАТЬ ФАЙЛ", "READ LOG  ИЛИ ПРОСТО  LOG.\nРАСШИРЕНИЕ .TXT МОЖНО НЕ ПИСАТЬ."],
	"STATUS": ["STATUS", "СОСТОЯНИЕ УЧАСТКА", "ЛИНИИ, НАГРУЗКА, РЕШЁТКА."],
	"POWER": ["POWER <A|B|V> <ON|OFF>", "ПИТАНИЕ ЛИНИИ", "POWER A OFF — ОТКЛЮЧИТЬ ОСВЕЩЕНИЕ.\nPOWER V ON — ПОДАТЬ ПИТАНИЕ НА ПРИВОД РЕШЁТКИ.\nВВОД ЩИТА — 20 А. БОЛЬШЕ — ВЫБЬЕТ АВТОМАТ."],
	"OPEN": ["OPEN GD6 <КОД>", "ОТКРЫТЬ РЕШЁТКУ", "НУЖНО ПИТАНИЕ ПРИВОДА (ЛИНИЯ V) И КОД ИЗ 4 ЦИФР.\nПРИМЕР: OPEN GD6 1234"],
	"HINT": ["HINT", "ЧТО ДЕЛАТЬ ДАЛЬШЕ", "СОВЕТ ДЕЖУРНОМУ ПО ТЕКУЩЕЙ ОБСТАНОВКЕ."],
	"CLS": ["CLS", "ОЧИСТИТЬ ЭКРАН", "СТИРАЕТ ВСЁ С ЭКРАНА."],
	"EXIT": ["EXIT", "ОТОЙТИ ОТ ПУЛЬТА", "ТО ЖЕ, ЧТО ESC."],
}
const ALIAS := {"?": "HELP", "LS": "DIR", "TYPE": "READ", "CAT": "READ", "QUIT": "EXIT", "CLEAR": "CLS", "STAT": "STATUS"}
var bad_codes := 0

## расстояние Левенштейна — для «возможно, вы имели в виду»
static func _dist(a: String, b: String) -> int:
	var prev := []
	for j in b.length() + 1: prev.append(j)
	for i in a.length():
		var cur := [i + 1]
		for j in b.length():
			cur.append(mini(mini(cur[j] + 1, prev[j + 1] + 1), prev[j] + (0 if a[i] == b[j] else 1)))
		prev = cur
	return prev[b.length()]

## ближайшее слово из списка (или "", если ничего похожего)
static func _closest(w: String, words: Array) -> String:
	var best := ""; var bd := 99
	for x in words:
		var d := _dist(w, x)
		if x.begins_with(w) and w.length() >= 2: d = mini(d, 1)
		if d < bd: bd = d; best = x
	return best if bd <= maxi(1, w.length() / 3) else ""

## имя файла: LOG, LOG.TXT, log.txt → LOG.TXT; "" если такого нет
static func _file_name(w: String) -> String:
	var f := w if w.contains(".") else w + ".TXT"
	return f if f in FILES else ""

func _read(f: String) -> void:
	say(_file(f))
	wrist.add_note(NOTE_NAME[f])

func _line_state() -> String:
	var S := G.S
	return "A %s · Б %s · V %s" % ["ВКЛ" if S.qf1 else "ОТКЛ", "ВКЛ" if S.qf2 else "ОТКЛ", "ВКЛ" if S.v else "ОТКЛ"]

## совет по обстановке
func _hint() -> String:
	var S := G.S
	if S.gate != "closed": return "РЕШЁТКА ОТКРЫТА. ИДИТЕ НА УЧАСТОК 7."
	if not S.v:
		if G.load_a() + Game.LOAD.V > Game.LIMIT:
			return "ПРИВОДУ НУЖНО %d А, СВОБОДНО %d А.\nОСВОБОДИТЕ НАГРУЗКУ: ОТКЛЮЧИТЕ ЛИШНЮЮ ЛИНИЮ (POWER A OFF),\nПОТОМ ПОДАЙТЕ ПИТАНИЕ НА ПРИВОД: POWER V ON" % [Game.LOAD.V, Game.LIMIT - G.load_a()]
		return "ПОДАЙТЕ ПИТАНИЕ НА ПРИВОД РЕШЁТКИ: POWER V ON"
	if bad_codes > 0:
		return "КОД СБРОШЕН ДЕЖУРНЫМ. ПОИЩИТЕ ЕГО В ЖУРНАЛЕ СМЕНЫ (LOG)\nИ НА ТАБЛИЧКАХ У РЕШЁТКИ."
	return "ПРИВОД ГОТОВ. ВВЕДИТЕ: OPEN GD6 <КОД>"

func _unknown(c: String) -> void:
	Audio.play("beep", -6.0)
	var guess := _closest(c, CMDS.keys())
	var gf := _closest(c, FILES.map(func(f): return f.get_basename()))
	if guess != "":
		say("?НЕТ КОМАНДЫ «%s». ВОЗМОЖНО: %s" % [c, CMDS[guess][0]], ERR)
	elif gf != "":
		say("?НЕТ КОМАНДЫ «%s». ВОЗМОЖНО, ФАЙЛ: %s" % [c, gf + ".TXT"], ERR)
	else:
		say("?НЕИЗВЕСТНАЯ КОМАНДА «%s»." % c, ERR)
		say("КОМАНДЫ: " + " ".join(CMDS.keys()) + "   (HELP — ПОДРОБНЕЕ)", DIMC)

func exec(raw: String) -> void:
	var cmd := raw.strip_edges().to_upper()
	while cmd.contains("  "): cmd = cmd.replace("  ", " ")
	say(">" + cmd, DIMC)
	if cmd == "": return
	var p := cmd.split(" ")
	var c: String = ALIAS.get(p[0], p[0]); var a1 := p[1] if p.size() > 1 else ""; var a2 := p[2] if p.size() > 2 else ""
	## имя файла вместо команды: LOG, LOG.TXT
	if not CMDS.has(c) and _file_name(c) != "":
		_read(_file_name(c)); return
	match c:
		"HELP":
			if a1 != "":
				var k: String = ALIAS.get(a1, a1)
				if not CMDS.has(k):
					var g := _closest(k, CMDS.keys())
					say("?НЕТ КОМАНДЫ «%s»%s" % [a1, (". ВОЗМОЖНО: " + g) if g != "" else ""], ERR); return
				say(CMDS[k][0] + "   " + CMDS[k][1] + "\n" + CMDS[k][2]); return
			var t := "КОМАНДЫ:"
			for k in CMDS: t += "\n  %-24s %s" % [CMDS[k][0], CMDS[k][1]]
			t += "\nФАЙЛ МОЖНО ОТКРЫТЬ ПО ИМЕНИ:  LOG\nTAB — ДОПИСАТЬ СЛОВО · СТРЕЛКИ — ПРОШЛЫЕ КОМАНДЫ"
			say(t)
		"DIR":
			say("LOG.TXT       ЖУРНАЛ СМЕНЫ\nMANUAL.TXT    ИНСТРУКЦИЯ ДЕЖУРНОГО\nMAIL.TXT      ВХОДЯЩИЕ ЗАЯВКИ\nОТКРЫТЬ:  READ LOG  ИЛИ ПРОСТО  LOG")
		"READ":
			if a1 == "":
				say("?КАКОЙ ФАЙЛ? ПРИМЕР: READ LOG", ERR); say("ФАЙЛЫ: " + " ".join(FILES), DIMC); return
			var f := _file_name(a1)
			if f == "":
				var g := _closest(a1.get_basename(), FILES.map(func(x): return x.get_basename()))
				say("?ФАЙЛ НЕ НАЙДЕН: %s%s" % [a1, (". ВОЗМОЖНО: " + g + ".TXT") if g != "" else ""], ERR)
				say("ФАЙЛЫ: " + " ".join(FILES), DIMC); return
			_read(f)
		"STATUS":
			say(_status())
		"HINT":
			say("СОВЕТ: " + _hint(), WARN)
		"POWER":
			if a1 in ["ON", "OFF", "1", "0"] and a2 != "": var tmp := a1; a1 = a2; a2 = tmp
			if a2 == "1": a2 = "ON"
			elif a2 == "0": a2 = "OFF"
			if a1 == "":
				say("ФОРМАТ: POWER <A|B|V> <ON|OFF>   НАПРИМЕР: POWER A OFF", WARN)
				say("СЕЙЧАС: " + _line_state() + "   (A — СВЕТ, Б — ПУЛЬТ, V — ПРИВОД ГД-6)", DIMC); return
			if not LINE.has(a1):
				say("?НЕТ ЛИНИИ «%s». ЛИНИИ: A (СВЕТ), B (ПУЛЬТ), V (ПРИВОД ГД-6)" % a1, ERR); return
			var k: String = LINE[a1]
			if a2 != "ON" and a2 != "OFF":
				say("?ВКЛЮЧИТЬ ИЛИ ОТКЛЮЧИТЬ? ЛИНИЯ %s СЕЙЧАС %s.  ВВЕДИТЕ: POWER %s %s" % [a1, "ВКЛ" if G.S[k] else "ОТКЛ", a1, "OFF" if G.S[k] else "ON"], ERR); return
			var on := a2 == "ON"
			if G.S[k] == on:
				say("ЛИНИЯ %s УЖЕ %s" % [a1, "ВКЛЮЧЕНА" if on else "ОТКЛЮЧЕНА"]); return
			if k == "qf2" and not on:
				say("ВНИМАНИЕ: ЛИНИЯ Б ПИТАЕТ ЭТОТ ПУЛЬТ. ВКЛЮЧИТЬ ОБРАТНО — ТОЛЬКО НА ЩИТКЕ.", WARN)
			if on and G.load_a() + Game.LOAD[a1] > Game.LIMIT:
				say("ВНИМАНИЕ: НАГРУЗКА БУДЕТ %d А ПРИ ВВОДЕ %d А." % [G.load_a() + Game.LOAD[a1], Game.LIMIT], WARN)
			if G.set_line(k, on) == "trip": return
			Audio.play("relay")
			say("ЛИНИЯ %s %s.  НАГРУЗКА %d / %d А" % [a1, "ВКЛЮЧЕНА" if on else "ОТКЛЮЧЕНА", G.load_a(), Game.LIMIT])
			if k == "qf1" and not on: say("ОСВЕЩЕНИЕ УЧАСТКА ОТКЛЮЧЕНО.", WARN)
		"OPEN":
			var obj := a1.replace("-", "")
			if a1 == "":
				say("ФОРМАТ: OPEN GD6 <КОД>   (ГД-6 — РЕШЁТКА В КОНЦЕ КОРИДОРА)", WARN); return
			if obj != "GD6":
				say("?НЕИЗВЕСТНЫЙ ОБЪЕКТ: %s. С ЭТОГО ПУЛЬТА ДОСТУПНО: GD6" % a1, ERR); return
			if G.S.gate != "closed": say("РЕШЁТКА ГД-6 УЖЕ ОТКРЫТА"); return
			if a2 == "": say("?НУЖЕН КОД ИЗ 4 ЦИФР. ПРИМЕР: OPEN GD6 1234", ERR); return
			if not G.S.v: say("НЕТ ПИТАНИЯ ПРИВОДА (ЛИНИЯ V). ВВЕДИТЕ: POWER V ON", ERR); say("ПРИВОДУ НУЖНО %d А. СЕЙЧАС ЗАНЯТО %d ИЗ %d А." % [Game.LOAD.V, G.load_a(), Game.LIMIT], DIMC); return
			if a2 != "1987":
				bad_codes += 1
				Audio.play("beep_low"); say("НЕВЕРНЫЙ КОД. ПОПЫТКА ЗАРЕГИСТРИРОВАНА.", ERR)
				if bad_codes >= 2: say("КОД СБРОШЕН ДЕЖУРНЫМ — СМ. ЖУРНАЛ СМЕНЫ (LOG).", DIMC)
				return
			say("КОД ПРИНЯТ. ПРИВОД ГД-6 ПУЩЕН.", WARN)
			say("УЧАСТОК 7: СОБСТВЕННЫЙ ВВОД. ОСВЕЩЕНИЕ ВКЛЮЧАЕТСЯ АВТОМАТИЧЕСКИ.", WARN)
			G.open_gate()
		"CLS":
			out.clear(); lines.clear(); screen_draw.queue_redraw()
		"EXIT":
			close()
		"WHO", "WHOAMI":
			say("ДЕЖУРНЫЙ: НЕ ОПРЕДЕЛЁН\nЗАЯВКА 0001 НАЗНАЧЕНА ВАМ.")
		_:
			_unknown(c)

## подсказка под строкой ввода: как пишется команда, которую сейчас набирают
func live_hint() -> String:
	var l := line.strip_edges(false, true).to_upper()
	if l.strip_edges() == "": return "HELP — КОМАНДЫ · HINT — СОВЕТ · TAB — ДОПИСАТЬ · ↑ — ПРОШЛАЯ КОМАНДА"
	var p := l.strip_edges().split(" ")
	var c: String = ALIAS.get(p[0], p[0])
	if CMDS.has(c): return CMDS[c][0] + " — " + CMDS[c][1]
	if _file_name(c) != "": return "ENTER — ПРОЧИТАТЬ " + _file_name(c)
	var m := []
	for k in CMDS: if k.begins_with(c): m.append(k)
	for f in FILES: if f.begins_with(c): m.append(f)
	if m.size() == 1 and CMDS.has(m[0]): return CMDS[m[0]][0] + " — " + CMDS[m[0]][1] + " · TAB — ДОПИСАТЬ"
	if m.size() > 0: return "TAB — ДОПИСАТЬ: " + " ".join(m)
	return "НЕТ ТАКОЙ КОМАНДЫ · HELP — СПИСОК"

## Tab: дописать слово
func complete() -> void:
	var p := line.to_upper().split(" ")
	var w := p[p.size() - 1]
	var words := []
	if p.size() == 1: words = CMDS.keys() + FILES
	else:
		var c: String = ALIAS.get(p[0], p[0])
		match c:
			"READ": words = FILES
			"HELP": words = CMDS.keys()
			"POWER": words = ["A", "B", "V"] if p.size() == 2 else ["ON", "OFF"]
			"OPEN": words = ["GD6"] if p.size() == 2 else []
	var m := words.filter(func(x): return x.begins_with(w))
	if m.is_empty(): Audio.play("beep", -12.0); return
	var pre := line.substr(0, line.length() - w.length())
	if m.size() == 1:
		line = pre + m[0] + ("" if m[0].contains(".") and p.size() > 1 else " ")
	else:
		## общий префикс
		var cp: String = m[0]
		for x in m:
			while not x.begins_with(cp): cp = cp.substr(0, cp.length() - 1)
		if cp.length() > w.length(): line = pre + cp
		else: say("  " + "  ".join(m), DIMC)
	Audio.play("key", -6.0); screen_draw.queue_redraw()

func open_ui() -> void:
	is_open = true; visible = true
	## окно терминала — сколько влезает в экран
	var vs := get_viewport_rect().size
	body_box.custom_minimum_size = Vector2(minf(820.0, vs.x * 0.94), minf(560.0, vs.y * 0.86))
	if not booted: boot()

func close() -> void:
	is_open = false; visible = false
	if on_close.is_valid(): on_close.call()

## клавиши, пока терминал открыт
func key(e: InputEventKey) -> void:
	var code := e.physical_keycode
	if code == KEY_ESCAPE: close(); return
	if not powered(): return
	if code == KEY_ENTER or code == KEY_KP_ENTER:
		var l := line; line = ""
		if l.strip_edges() != "": hist.append(l); hi = hist.size()
		Audio.play("key"); exec(l); screen_draw.queue_redraw(); return
	if code == KEY_BACKSPACE:
		line = line.substr(0, max(0, line.length() - 1)); Audio.play("key"); screen_draw.queue_redraw(); return
	if code == KEY_TAB:
		complete(); return
	if code == KEY_UP:
		if hi > 0: hi -= 1; line = hist[hi]
		return
	if code == KEY_DOWN:
		if hi < hist.size() - 1: hi += 1; line = hist[hi]
		else: hi = hist.size(); line = ""
		return
	var ch := ""
	if code >= KEY_A and code <= KEY_Z: ch = char(code)
	elif code >= KEY_0 and code <= KEY_9: ch = char(code)
	elif code >= KEY_KP_0 and code <= KEY_KP_9: ch = char(KEY_0 + code - KEY_KP_0)
	elif code == KEY_SPACE: ch = " "
	elif code == KEY_MINUS or code == KEY_KP_SUBTRACT: ch = "-"
	elif code == KEY_PERIOD or code == KEY_KP_PERIOD: ch = "."
	elif code == KEY_SLASH and e.shift_pressed: ch = "?"
	elif code == KEY_7 and e.shift_pressed: ch = "?"
	if ch != "" and line.length() < 48:
		line += ch; Audio.play("key", -6.0); screen_draw.queue_redraw()

## питание пропало/появилось
func power_changed(prev: Dictionary) -> void:
	var was: bool = prev.qf0 and prev.qf2
	var now := G.term_on()
	if was and not now:
		booted = false; queue.clear()
		if is_open:
			out.append_text("[color=%s]*** ПИТАНИЕ ПРОПАЛО ***[/color]\n" % ERR)
			get_tree().create_timer(0.9).timeout.connect(func(): if is_open and not G.term_on(): close())
		lines.clear()
	if not was and now:
		Audio.play("beep_hi"); lines = ["ЩИТ-80", "ГОТОВ."]
	screen_draw.queue_redraw()
