## Автотест главы 0 внутри Godot. Запуск (нужен экран; на сервере — через xvfb-run):
##   godot --path . --rendering-method gl_compatibility -- --test --shots=/папка/для/скриншотов
## Проходит главу через методы main.gd и печатает ok/FAIL и ИТОГ.
extends Node

var M
var fails := []
var shots_dir := ""

func _ready() -> void:
	M = get_parent()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shots="): shots_dir = a.substr(8)
	run.call_deferred()

var logf: FileAccess
func log_line(t: String) -> void:
	printerr(t)
	if shots_dir != "":
		if logf == null: logf = FileAccess.open(shots_dir.path_join("progress.txt"), FileAccess.WRITE)
		logf.store_line(t); logf.flush()

func check(name: String, ok: bool, info = "") -> void:
	log_line(("  ok   " if ok else "  FAIL ") + name + (("  " + str(info)) if str(info) != "" else ""))
	if not ok: fails.append(name)

func frames(n := 1) -> void:
	for i in n: await get_tree().process_frame

func wait(sec: float) -> void:
	await get_tree().create_timer(sec, true, false, false).timeout

func shot(name: String) -> void:
	log_line("  [кадр] %s  t=%d" % [name, Time.get_ticks_msec()])
	if shots_dir == "": return
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(shots_dir.path_join(name + ".png"))

func tp(x: float, z: float, yaw: float, pitch := 0.0) -> void:
	M.P.tp(x, z, yaw, pitch)
	await frames(2)

## идти вперёд sec секунд
func walk(sec: float, dir := Vector2(0, -1)) -> void:
	M.P.input_override = dir
	await wait(sec)
	M.P.input_override = Vector2.ZERO

func key(code: int) -> void:
	var e := InputEventKey.new(); e.physical_keycode = code; e.keycode = code; e.pressed = true
	Input.parse_input_event(e)
	await frames(2)
	var u := e.duplicate(); u.pressed = false; Input.parse_input_event(u)
	await frames(1)

func run() -> void:
	var G = M.G; var S = G.S; var W = M.W
	await frames(5)
	await shot("00_start")
	log_line("Старт")
	M._start()
	await frames(3)
	check("игра запущена", M.started and not M.hud.start_screen.visible)
	check("на ПТ-1 вызов", M.wrist.orders.size() > 0 and M.wrist.orders[0].contains("Электрощитовая"))
	await wait(1.0)
	await shot("01_landing")

	log_line("Дверь")
	await tp(0, 1.3, 0)
	check("смотрим на дверь", M.pick_target() == "door", M.target)
	await tp(0, 1.0, 0, 0.35)
	await shot("02_door")
	await tp(0, 1.3, 0)
	M.pick_target(); M.interact()
	await wait(2.5)
	check("дверь открылась", W.door.open > 0.9 and W.door.shape.disabled)
	await tp(0, -1, 0)
	await wait(0.3)
	check("вошли в коридор, пришла заявка", S.entered and M.wrist.orders[0].contains("ЗАЯВКА 0001"))
	await tp(-0.4, -1.5, 0.05, 0.03)
	await shot("03_corridor_dark")
	M.P.toggle_flash(); await wait(0.5)
	await shot("03b_flashlight")
	M.P.toggle_flash()

	log_line("Тело и ПТ-1")
	check("новая заявка не прочитана", M.wrist.unread)
	await key(KEY_TAB)
	await wait(0.6)
	check("Tab поднимает ПТ-1 и читает заявку", M.wrist.raised and not M.wrist.unread)
	await shot("04_wrist_dark")
	await key(KEY_2)
	check("страница «Задача»", M.wrist.page == 1 and M.wrist.goal.contains("щитке"), M.wrist.goal)
	await key(KEY_1)
	await key(KEY_TAB)
	await wait(0.4)
	check("ПТ-1 опущен", not M.wrist.raised)

	log_line("Стены держат")
	await tp(0, -3, -PI / 2)
	await walk(2.5)
	check("в стену не пройти", M.P.global_position.x < 1.75 and M.P.global_position.x > 1.4, M.P.global_position.x)
	await tp(0, -15, 0)
	await walk(3.0)
	check("решётка держит", M.P.global_position.z > -19.95, M.P.global_position.z)

	log_line("Щиток")
	await tp(2.4, -7.1, -PI / 2)
	check("смотрим на щиток", M.pick_target() == "panel", M.target)
	check("ПТ-1 на связи со щитком", M.wrist.link.begins_with("ЩР-6"), M.wrist.link)
	await tp(2.2, -8.85, -PI / 2, -0.32)
	check("терминал без питания", M.pick_target() == "terminal" and not G.term_on(), M.target)
	await tp(2.4, -7.1, -PI / 2)
	M.open_overlay("panel")
	await frames(2)
	check("щиток открыт", M.panel_ui.visible)
	M.panel_ui._toggle("qf0")
	check("ввод включился, свет есть", S.qf0 and G.lights_a())
	M.panel_ui._toggle("qf2")
	check("терминал запитан, нагрузка 14 А", G.term_on() and G.load_a() == 14)
	await wait(0.5)
	await shot("05_panel_ui")
	await key(KEY_ESCAPE)
	check("щиток закрылся", not M.panel_ui.visible and M.overlay == "")
	await wait(1.5)
	await tp(2.3, -7.1, -PI / 2 + 0.35, -0.05)
	await shot("06_panel_model")
	await tp(-0.6, -1.5, 0.05, 0.02)
	await shot("07_corridor_lit")
	await tp(0.3, -2, 0.1, 0.62)
	await shot("07b_height")

	log_line("Терминал")
	await tp(2.2, -8.85, -PI / 2, -0.32)
	await wait(0.3)
	await shot("08_terminal_world")
	M.open_overlay("term")
	await frames(2)
	for c in [KEY_H, KEY_E, KEY_L, KEY_P, KEY_ENTER]:
		await key(c)
	check("HELP печатается с клавиатуры", M.term.text().contains("POWER <A|B|V>"))
	for c in ["DIR", "READ LOG", "STATUS"]:
		M.term.exec(c)
	var txt: String = M.term.text()
	check("файлы и статус", txt.contains("LOG.TXT") and txt.contains("Они идут на ток") and txt.contains("НАГРУЗКА: 14 / 20"))
	M.term.exec("OPEN GD6 1987")
	check("без питания привода не открыть", M.term.text().contains("НЕТ ПИТАНИЯ ПРИВОДА") and S.gate == "closed")
	await shot("09_terminal_ui")
	M.term.exec("POWER V ON")
	check("перегрузка выбивает ввод", not S.qf0 and S.trips == 1)
	await wait(1.3)
	check("терминал погас и закрылся", not M.term.visible and not G.term_on())
	G.set_line("qf0", true)
	M.open_overlay("term")
	for c in ["POWER A OFF", "POWER V ON", "OPEN GD6 1111"]:
		M.term.exec(c)
	check("свет выключен, привод запитан", not G.lights_a() and S.v and G.load_a() == 18)
	check("неверный код отклонён", M.term.text().contains("НЕВЕРНЫЙ КОД") and S.gate == "closed")
	M.term.exec("OPEN GD-6 1987")
	check("решётка пошла", S.gate == "opening")
	M.term.close()

	log_line("Решётка и участок 7")
	await tp(0, -8, 0, 0.05)
	await wait(3.0)
	await shot("10_gate_rising")
	await wait(4.0)
	check("решётка открыта", S.gate == "open" and W.gate.shape.disabled)
	Engine.time_scale = 3.0
	await wait(14.0)
	Engine.time_scale = 1.0
	var lit: int = W.lamps.filter(func(l): return l.grp == "S7" and l.lvl > 0.5).size()
	check("свет на участке 7 включился до горизонта", lit > 200, lit)
	check("вторая заявка", M.wrist.orders[0].contains("ЗАЯВКА 0002"))
	await tp(0, -12, 0, 0.02)
	await wait(0.3)
	await shot("11_endless")
	M.wrist.raise(true); await wait(0.6)
	await shot("11b_wrist_lit")
	M.wrist.raise(false)
	await tp(0, -12, 0.3, -1.25)
	await walk(0.4)
	M.P.pitch = -1.25
	await shot("11c_legs")
	await tp(0, -25, 0)
	await walk(1.5)
	check("за решётку можно пройти", M.P.global_position.z < -26, M.P.global_position.z)

	log_line("Финал")
	await tp(0, -50, 0)
	Engine.time_scale = 3.0
	await wait(10.0)
	Engine.time_scale = 1.0
	await shot("12_dark_wave")
	Engine.time_scale = 4.0
	await wait(25.0)
	Engine.time_scale = 1.0
	await wait(3.0)
	check("финал прототипа", S.ended and M.hud.end_screen.visible)
	await shot("13_end")
	log_line("")
	log_line("ИТОГ: всё в порядке" if fails.is_empty() else "ИТОГ: провалено %d: %s" % [fails.size(), ", ".join(fails)])
	get_tree().quit(1 if fails.size() else 0)
