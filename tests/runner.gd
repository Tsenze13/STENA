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

func tp(x: float, z: float, yaw: float, pitch := 0.0, h := 0.0) -> void:
	M.P.tp(x, z, yaw, pitch, h)
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

## быстрый просмотр видов (без прохождения): -- --test --views --shots=/папка
func run_views() -> void:
	var G = M.G; var W = M.W
	await frames(5)
	M._start(); await frames(3)
	var y1 := Stairwell.floor_y(1)
	for v in [["v01_winter", 0.8, 34.0, 0.0, 0.05, y1], ["v02_wall", 0.8, 16.0, 0.0, 0.6, y1], ["v03_door", -1.6, 10.0, 0.0, 0.1, y1],
			["v04_floor1", -1.0, 3.6, PI / 2 + 0.6, 0.0, y1], ["v05_dispatch", -4.0, 1.4, PI / 2 + 0.3, -0.05, y1], ["v06_stairs", -0.6, 3.4, -PI / 2 + 0.5, 0.55, y1],
			["v07_floor6", -1.4, 2.7, -0.45, 0.0, 0.0]]:
		await tp(v[1], v[2], v[3], v[4], v[5]); await wait(0.6); await shot(v[0])
	G.set_line("qf0", true); G.set_line("qf2", true)
	M.open_overlay("panel"); await wait(0.6); await shot("v06_panel_ui"); M.panel_ui.close()
	M.open_overlay("term"); M.term.exec("HINT"); M.term.line = "PO"; await wait(0.6); await shot("v07_terminal"); M.term.line = ""; M.term.close()
	await tp(0.9, -17.1, -PI / 2, 0.05); await wait(0.4); await shot("v08_plaque")
	S_open(G, W)
	await wait(0.5)
	M.P.tp(0, -26, 0); await frames(3)
	await wait(4.0)
	for v in [["v09_shaft", 2.4, -33.5, -PI / 2 + 0.25, 0.08], ["v10_shaft_down", 2.4, -33.5, -PI / 2 + 0.1, -0.75], ["v11_shaft_up", 2.4, -33.5, -PI / 2 - 0.2, 0.8], ["v12_balcony", 0.0, -27.0, -0.9, 0.05]]:
		await tp(v[1], v[2], v[3], v[4]); await wait(0.3); await shot(v[0])
	log_line("ИТОГ: виды сняты"); get_tree().quit(0)

## открыть решётку сразу (для просмотра)
func S_open(G, W) -> void:
	G.S.gate = "open"; W.gate.open = 1.0; W.gate.moving = false
	M.L.set_group("S7", true, 0.0, World.GATE_Z)

func run() -> void:
	if "--views" in OS.get_cmdline_user_args():
		await run_views(); return
	var G = M.G; var S = G.S; var W = M.W
	await frames(5)
	await shot("00_start")
	log_line("Старт")
	M._start()
	await frames(3)
	check("игра запущена", M.started and not M.hud.start_screen.visible)
	## мышь: движение должно поворачивать взгляд, даже когда курсор над прицелом в центре
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	await frames(2)
	var y0: float = M.P.yaw
	var mm := InputEventMouseMotion.new(); mm.relative = Vector2(120, 0); mm.position = get_viewport().get_visible_rect().size / 2
	get_viewport().push_input(mm)
	await frames(2)
	check("мышь поворачивает взгляд", Input.mouse_mode != Input.MOUSE_MODE_CAPTURED or absf(M.P.yaw - y0) > 0.1, [y0, M.P.yaw, Input.mouse_mode])
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var y1 := Stairwell.floor_y(1)
	log_line("Улица")
	check("старт снаружи, у подножия Стены", M.P.global_position.z > 20.0 and M.P.global_position.y < -14.0, M.P.global_position)
	await wait(1.5)
	check("снаружи метель и серый туман", M.outside_k > 0.5 and M.snowfall.visible and M.P.surface == "snow", M.outside_k)
	await shot("01_winter")
	check("ноги на высоте игрока, а не над головой", absf(M.B.legs_root.global_position.y - M.P.global_position.y) < 0.05, [M.B.legs_root.global_position.y, M.P.global_position.y])
	await tp(0.8, 20.0, 0.0, 0.55, y1)
	await wait(0.6)
	await shot("01b_wall_up")
	await walk(1.0)
	check("по снегу можно идти", M.P.global_position.z < 19.8 and absf(M.P.global_position.y - y1) < 0.3, M.P.global_position)

	log_line("Шлюз")
	await tp(-1.6, 8.6, 0.0, 0.0, y1)
	check("смотрим на наружную дверь", M.pick_target() == "obj" and M.target_obj.name == "OuterDoor", [M.target, M.target_obj])
	M.interact(); await wait(1.5)
	check("наружная дверь открылась", M.target_obj == null or M.target_obj.open > 0.8)
	await tp(-1.6, 6.0, 0.0, 0.0, y1)
	await walk(1.4)
	check("вошли в шлюз", S.inside and M.P.global_position.z < 4.6, M.P.global_position)
	await wait(1.2)
	check("внутри туман обычный", M.outside_k < 0.2, M.outside_k)
	check("задача: в диспетчерскую", M.wrist.goal.contains("диспетчерск"), M.wrist.goal)
	await tp(-1.0, 3.6, PI / 2 + 0.6, 0.0, y1)
	await shot("02_lock_floor1")
	## лестница заперта, пока не взята заявка
	await tp(1.35, 0.3, PI, 0.0, y1)
	check("решётка ЛК-1 заперта", M.pick_target() == "obj" and M.target_obj.locked, M.target)
	await walk(1.2, Vector2(0, -1))
	check("без заявки на лестницу не пройти", M.P.global_position.z < 0.75, M.P.global_position)

	log_line("Диспетчерская")
	await tp(-2.3, 0.9, PI / 2, 0.0, y1)
	check("дверь диспетчерской", M.pick_target() == "obj" and M.target_obj.name == "DispatchDoor", M.target)
	M.interact(); await wait(1.5)
	await tp(-5.6, 0.5, PI / 2, -0.1, y1)
	check("пульт диспетчерской", M.pick_target() == "dispatch", M.target)
	await shot("03_dispatch")
	M.interact(); await frames(2)
	check("терминал диспетчерской открыт", M.overlay == "disp" and M.disp.visible)
	for c in ["LIST", "0001", "LOG"]:
		M.disp.exec(c)
	var dt: String = M.disp.text()
	check("заявки и журнал пункта", dt.contains("НОВАЯ") and dt.contains("ОТПРАВИТЕЛЬ: НЕ ОПРЕДЕЛЁН") and dt.contains("ВХОД ДЕЖУРНОГО"))
	M.disp.exec("TAKE 0001")
	await wait(0.6)
	await shot("03b_dispatch_ui")
	check("заявка на ПТ-1, лестница открыта", S.task_taken and M.wrist.orders[0].contains("ЗАЯВКА 0001") and not W.gate_lk1.locked)
	M.disp.close()

	log_line("Лестница")
	await tp(1.35, 0.3, PI, 0.0, y1)
	M.pick_target(); M.interact(); await wait(1.2)
	await tp(1.35, 0.45, PI, 0.0, y1)
	await walk(2.5)
	check("по лестнице поднимаемся", M.P.global_position.y > y1 + 0.8, M.P.global_position)
	await tp(-1.0, 1.0, PI / 2 + 0.9, 0.1, Stairwell.floor_y(3))
	await shot("04_floor3")
	await tp(-0.6, 3.4, -PI / 2 + 0.5, 0.55, 0.0)
	await shot("04b_stairs_up")
	await tp(1.35, 0.3, PI, 0.0, 0.0)
	check("на 7 этаж не пройти", M.pick_target() == "obj" and M.target_obj.locked, M.target)
	await tp(-1.4, 2.7, -0.45, 0.0, 0.0)
	await wait(0.5)
	await shot("05_floor6")
	await tp(-2.5, 3.0, PI / 2 + 0.1, 0.0, 0.0)
	check("лифт без питания", M.pick_target() == "lift", M.target)

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
	M.P.toggle_flash(); M.B.click(); await wait(0.5)
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
	await tp(0.9, -17.1, -PI / 2, 0.05)
	await wait(0.3)
	await shot("07c_plaque")
	if "--quick" in OS.get_cmdline_user_args():
		log_line("ИТОГ: быстрая проверка картинки"); get_tree().quit(0); return

	log_line("Терминал")
	await tp(2.2, -8.85, -PI / 2, -0.32)
	await wait(0.3)
	await shot("08_terminal_world")
	M.open_overlay("term")
	await frames(2)
	for c in [KEY_H, KEY_E, KEY_L, KEY_P, KEY_ENTER]:
		await key(c)
	check("HELP печатается с клавиатуры", M.term.text().contains("POWER <A|B|V>"))
	for c in ["DIR", "LOG", "STATUS"]:
		M.term.exec(c)
	var txt: String = M.term.text()
	check("файлы и статус (файл открывается по имени, без READ)", txt.contains("LOG.TXT") and txt.contains("Они идут на ток") and txt.contains("НАГРУЗКА: 14 / 20"))
	M.term.exec("POWR")
	check("опечатка: подсказка ближайшей команды", M.term.text().contains("ВОЗМОЖНО: POWER"))
	M.term.exec("READ MANUL")
	check("опечатка в файле: подсказка", M.term.text().contains("ВОЗМОЖНО: MANUAL.TXT"))
	M.term.exec("POWER")
	check("POWER без параметров объясняет формат", M.term.text().contains("СЕЙЧАС: A ВКЛ"))
	M.term.exec("HINT")
	check("HINT даёт совет", M.term.text().contains("СОВЕТ: ПРИВОДУ НУЖНО"))
	M.term.line = "PO"
	check("подсказка при наборе", M.term.live_hint().begins_with("POWER <A|B|V>"), M.term.live_hint())
	M.term.line = "MAN"; M.term.complete()
	check("Tab дописывает", M.term.line == "MANUAL.TXT ", M.term.line)
	M.term.line = "POWER "
	M.term.exec("OPEN GD6 1987")
	check("без питания привода не открыть", M.term.text().contains("НЕТ ПИТАНИЯ ПРИВОДА") and S.gate == "closed")
	await wait(0.3)
	await shot("09_terminal_ui")
	M.term.line = ""
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
	check("огни колодца включаются", M.W.shaft.on and M.W.shaft.visible)
	await tp(2.4, -33.5, -PI / 2 + 0.25, 0.08)
	await wait(3.0)
	await shot("11d_shaft")
	await tp(2.4, -33.5, -PI / 2 + 0.1, -0.75)
	await shot("11e_shaft_down")
	await tp(2.4, -33.5, -PI / 2 - 0.2, 0.8)
	await shot("11f_shaft_up")
	await tp(3.0, -33.5, -PI / 2, 0)
	await walk(1.0, Vector2(0, -1))
	check("с балкона не упасть", M.P.global_position.x < 3.9, M.P.global_position.x)

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
