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
var typing := 0.0
var on_close: Callable
var screen_draw: Control   # экран в мире (SubViewport пульта)
var font: Font

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
	vb.add_child(body)
	var scr := PanelContainer.new()
	var sb2 := StyleBoxFlat.new(); sb2.bg_color = Color(0.02, 0.07, 0.03); sb2.set_corner_radius_all(14); sb2.set_content_margin_all(16)
	scr.add_theme_stylebox_override("panel", sb2)
	body.add_child(scr)
	var inner := VBoxContainer.new(); scr.add_child(inner)
	out = RichTextLabel.new(); out.bbcode_enabled = true; out.scroll_following = true; out.size_flags_vertical = Control.SIZE_EXPAND_FILL
	out.add_theme_font_override("normal_font", font); out.add_theme_font_size_override("normal_font_size", 17)
	out.add_theme_color_override("default_color", Color(GREEN))
	out.add_theme_color_override("font_shadow_color", Color(0.49, 1, 0.6, 0.35)); out.add_theme_constant_override("shadow_outline_size", 4)
	inner.add_child(out)
	input_label = Label.new(); input_label.add_theme_font_override("font", font); input_label.add_theme_font_size_override("font_size", 17)
	input_label.add_theme_color_override("font_color", Color(GREEN))
	inner.add_child(input_label)
	var hint := Label.new(); hint.text = "Пиши команды и жми Enter · Esc — отойти от терминала"
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
		var on: bool = term.G.term_on()
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.012, 0.08, 0.04) if on else Color(0.02, 0.02, 0.02))
		if not on: return
		var ls: Array = term.lines.slice(max(0, term.lines.size() - 13))
		for i in ls.size():
			draw_string(term.font, Vector2(14, 22 + i * 16), str(ls[i]).substr(0, 38), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.49, 1, 0.6))
		draw_string(term.font, Vector2(14, 22 + ls.size() * 16), ">" + term.line + "_", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.49, 1, 0.6))
		var y := 0.0
		while y < size.y:
			draw_rect(Rect2(0, y, size.x, 1), Color(0, 0, 0, 0.25)); y += 3

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

func exec(raw: String) -> void:
	var cmd := raw.strip_edges().to_upper()
	while cmd.contains("  "): cmd = cmd.replace("  ", " ")
	say(">" + cmd, DIMC)
	if cmd == "": return
	var p := cmd.split(" ")
	var c := p[0]; var a1 := p[1] if p.size() > 1 else ""; var a2 := p[2] if p.size() > 2 else ""
	match c:
		"HELP", "?":
			say("КОМАНДЫ:\n  DIR              список файлов\n  READ <ФАЙЛ>      прочитать файл\n  STATUS           состояние участка\n  POWER <A|B|V> <ON|OFF>   питание линии\n  OPEN <ОБЪЕКТ> <КОД>      открыть\n  CLS              очистить экран\n  EXIT             выйти")
		"DIR", "LS":
			say("LOG.TXT       ЖУРНАЛ СМЕНЫ\nMANUAL.TXT    ИНСТРУКЦИЯ ДЕЖУРНОГО\nMAIL.TXT      ВХОДЯЩИЕ ЗАЯВКИ")
		"READ", "TYPE", "CAT":
			if a1 == "":
				say("?УКАЖИТЕ ФАЙЛ: READ LOG.TXT", ERR); return
			var f := a1 if a1.contains(".") else a1 + ".TXT"
			var t := _file(f)
			if t == "":
				say("?ФАЙЛ НЕ НАЙДЕН: " + f, ERR)
			else:
				say(t)
				wrist.add_note({"LOG.TXT": "Журнал смены, уч. 6", "MANUAL.TXT": "Инструкция дежурного", "MAIL.TXT": "Входящие заявки пульта"}[f])
		"STATUS":
			say(_status())
		"POWER":
			if not LINE.has(a1) or (a2 != "ON" and a2 != "OFF"):
				say("?ФОРМАТ: POWER <A|B|V> <ON|OFF>", ERR); return
			var k: String = LINE[a1]; var on := a2 == "ON"
			if G.S[k] == on:
				say("ЛИНИЯ %s УЖЕ %s" % [a1, "ВКЛЮЧЕНА" if on else "ОТКЛЮЧЕНА"]); return
			if G.set_line(k, on) == "trip": return
			Audio.play("relay")
			say("ЛИНИЯ %s %s.  НАГРУЗКА %d / %d А" % [a1, "ВКЛЮЧЕНА" if on else "ОТКЛЮЧЕНА", G.load_a(), Game.LIMIT])
			if k == "qf1" and not on: say("ОСВЕЩЕНИЕ УЧАСТКА ОТКЛЮЧЕНО.", WARN)
		"OPEN":
			var obj := a1.replace("-", "")
			if obj != "GD6":
				say(("?НЕИЗВЕСТНЫЙ ОБЪЕКТ: " + a1 + ". ДОСТУПНО: GD6") if a1 != "" else "?ФОРМАТ: OPEN GD6 <КОД>", ERR); return
			if G.S.gate != "closed": say("РЕШЁТКА ГД-6 УЖЕ ОТКРЫТА"); return
			if a2 == "": say("?НУЖЕН КОД: OPEN GD6 <КОД>", ERR); return
			if not G.S.v: say("НЕТ ПИТАНИЯ ПРИВОДА (ЛИНИЯ V). СМ. MANUAL.TXT", ERR); return
			if a2 != "1987":
				Audio.play("beep_low"); say("НЕВЕРНЫЙ КОД. ПОПЫТКА ЗАРЕГИСТРИРОВАНА.", ERR); return
			say("КОД ПРИНЯТ. ПРИВОД ГД-6 ПУЩЕН.", WARN)
			say("УЧАСТОК 7: СОБСТВЕННЫЙ ВВОД. ОСВЕЩЕНИЕ ВКЛЮЧАЕТСЯ АВТОМАТИЧЕСКИ.", WARN)
			G.open_gate()
		"CLS":
			out.clear(); lines.clear(); screen_draw.queue_redraw()
		"EXIT", "QUIT":
			close()
		"WHO", "WHOAMI":
			say("ДЕЖУРНЫЙ: НЕ ОПРЕДЕЛЁН\nЗАЯВКА 0001 НАЗНАЧЕНА ВАМ.")
		_:
			Audio.play("beep", -6.0); say("?СИНТАКСИЧЕСКАЯ ОШИБКА. HELP — СПИСОК КОМАНД", ERR)

func open_ui() -> void:
	is_open = true; visible = true
	if not booted: boot()

func close() -> void:
	is_open = false; visible = false
	if on_close.is_valid(): on_close.call()

## клавиши, пока терминал открыт
func key(e: InputEventKey) -> void:
	var code := e.physical_keycode
	if code == KEY_ESCAPE: close(); return
	if not G.term_on(): return
	if code == KEY_ENTER or code == KEY_KP_ENTER:
		var l := line; line = ""
		if l.strip_edges() != "": hist.append(l); hi = hist.size()
		Audio.play("key"); exec(l); screen_draw.queue_redraw(); return
	if code == KEY_BACKSPACE:
		line = line.substr(0, max(0, line.length() - 1)); Audio.play("key"); screen_draw.queue_redraw(); return
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
