## Точка входа: окружение, мир, игрок, руки, интерфейс, взаимодействие, режимы (игра/пауза/оверлеи).
## Уровень — сцена scenes/levels/chapter0.tscn (узел World в main.tscn): его видно и можно править в редакторе.
extends Node3D

const VERSION := "0.7-бета"

## Туман, свечение, экспозиция — правятся в инспекторе узла Main (Environment).
@export var environment: Environment

var W: World
var L: Lights
var P: Player
var G: Game
var B: Body
var wrist: Wrist
var term: Terminal
var disp: DispatchTerminal
var snowfall: CPUParticles3D
var outside_k := 0.0          # 0 — внутри, 1 — снаружи (туман, свет, ветер плавно меняются)
var env_in := {}              # настройки окружения внутри (из Environment) — запоминаем при старте
var target_obj: Node = null
var panel_ui: PanelUI
var hud: Hud
var dust: CPUParticles3D
var started := false
var paused := false
var overlay := ""
var target := ""
var target_label := ""
var relay_t := 0.0
var test_mode := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	test_mode = "--test" in OS.get_cmdline_user_args()
	_inputs()
	_environment()
	W = get_node_or_null("World")
	if W == null:
		W = load("res://scenes/levels/chapter0.tscn").instantiate(); W.name = "World"; add_child(W)
	L = Lights.new(); add_child(L); L.setup(W)
	L.on_relay = _relay
	P = Player.new(); P.process_mode = Node.PROCESS_MODE_PAUSABLE; add_child(P)
	P.global_position = W.spawn; P.yaw = W.spawn_yaw
	## ПТ-1: экран рисуется в своём SubViewport
	var wvp := SubViewport.new(); wvp.size = Vector2i(384, 256); wvp.render_target_update_mode = SubViewport.UPDATE_ALWAYS; add_child(wvp)
	wrist = Wrist.new(); wvp.add_child(wrist)
	G = Game.new(); add_child(G); G.setup(W, L, P, wrist)
	B = Body.new(); add_child(B); B.setup(P, wrist, wvp.get_texture())
	_dust()
	## интерфейс
	hud = Hud.new(); add_child(hud); hud.build(VERSION)
	var ui_layer := CanvasLayer.new(); ui_layer.layer = 5; add_child(ui_layer)
	term = Terminal.new(); ui_layer.add_child(term); term.setup(G, wrist, W.term_viewport)
	panel_ui = PanelUI.new(); ui_layer.add_child(panel_ui); panel_ui.setup(G)
	term.on_close = _close_overlay; panel_ui.on_close = _close_overlay
	if W.dispatch_viewport:
		disp = DispatchTerminal.new(); ui_layer.add_child(disp); disp.setup(G, wrist, W.dispatch_viewport)
		disp.on_close = _close_overlay
		disp.boot(); disp.flush()
	_snow()
	G.on_power = func(prev):
		term.power_changed(prev)
		if panel_ui.is_open: panel_ui.render()
	G.on_toast = hud.toast
	G.on_end = _end
	hud.on_start = _start
	hud.on_resume = _resume
	hud.on_volume = Audio.set_volume
	hud.on_sens = func(v): P.sens = v
	P.frozen = true
	if test_mode:
		var r := Node.new(); r.set_script(load("res://tests/runner.gd")); r.name = "TestRunner"; add_child(r)

func _inputs() -> void:
	var map := {"forward": [KEY_W, KEY_UP], "back": [KEY_S, KEY_DOWN], "left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT], "run": [KEY_SHIFT]}
	for a in map:
		if not InputMap.has_action(a): InputMap.add_action(a)
		for k in map[a]:
			var e := InputEventKey.new(); e.physical_keycode = k; InputMap.action_add_event(a, e)

func _environment() -> void:
	var we := WorldEnvironment.new()
	if environment:
		environment = environment.duplicate()
		we.environment = environment; add_child(we)
		var e := environment
		env_in = {"fog": e.fog_light_color, "fog_d": e.fog_density, "bg": e.background_color, "amb": e.ambient_light_color, "vol": e.volumetric_fog_density, "vol_c": e.volumetric_fog_albedo}
		return
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0, 0, 0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.05, 0.05, 0.055)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.1
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 0.9
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	env.ssao_enabled = true
	env.ssao_intensity = 1.6
	env.ssr_enabled = true
	env.ssr_max_steps = 48
	env.fog_enabled = true
	env.fog_light_color = Color(0, 0, 0)
	env.fog_density = 0.02
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.022
	env.volumetric_fog_albedo = Color(0.7, 0.7, 0.68)
	env.volumetric_fog_anisotropy = 0.55
	env.volumetric_fog_length = 48.0
	env.volumetric_fog_ambient_inject = 0.0
	we.environment = env
	add_child(we)

## пыль в воздухе: частицы вокруг игрока, освещаются лампами — видны только на свету
func _dust() -> void:
	dust = CPUParticles3D.new()
	dust.amount = 500; dust.lifetime = 14.0; dust.preprocess = 14.0; dust.local_coords = false
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX; dust.emission_box_extents = Vector3(2, 4.5, 9)
	dust.direction = Vector3(0, -1, 0); dust.spread = 180; dust.initial_velocity_min = 0.0; dust.initial_velocity_max = 0.06
	dust.gravity = Vector3(0, -0.01, 0)
	var q := QuadMesh.new(); q.size = Vector2(0.012, 0.012)
	var m := StandardMaterial3D.new(); m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED; m.albedo_color = Color(0.8, 0.78, 0.7, 0.6)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; m.roughness = 1.0
	q.material = m; dust.mesh = q
	add_child(dust)

func toggle_fullscreen() -> void:
	var full := DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)

## снег вокруг игрока (виден, когда он снаружи)
func _snow() -> void:
	snowfall = CPUParticles3D.new()
	snowfall.amount = 1800; snowfall.lifetime = 4.0; snowfall.preprocess = 4.0; snowfall.local_coords = false
	snowfall.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX; snowfall.emission_box_extents = Vector3(14, 1, 14)
	snowfall.direction = Vector3(0.6, -1, 0.15); snowfall.spread = 12; snowfall.initial_velocity_min = 3.0; snowfall.initial_velocity_max = 6.0
	snowfall.gravity = Vector3(1.5, -2, 0)
	var q := QuadMesh.new(); q.size = Vector2(0.03, 0.03)
	var m := StandardMaterial3D.new(); m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED; m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.92, 0.94, 0.97, 0.9); m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	q.material = m; snowfall.mesh = q
	snowfall.visible = false
	add_child(snowfall)

## снаружи: серый метельный туман, светлее фон и окружающий свет; внутри — как в Environment
func _zone(dt: float) -> void:
	var pz := P.global_position.z
	var face := Winter.FACE
	var want := 1.0 if pz > 7.5 else 0.0
	outside_k = move_toward(outside_k, want, dt * 1.5)
	P.surface = "snow" if pz > 7.45 else ""
	snowfall.visible = pz > face
	snowfall.global_position = P.global_position + Vector3(-4, 9, -2)
	Audio.set_wind(clampf((pz - face) / 2.0, 0.0, 1.0) * (0.35 + 0.65 * outside_k))
	if W.winter: W.winter.visible = pz > 3.0 or P.global_position.y < -12.0
	if env_in.is_empty(): return
	var e := environment; var k := outside_k
	e.fog_light_color = env_in.fog.lerp(Color(0.24, 0.255, 0.28), k)
	e.fog_density = lerpf(env_in.fog_d, 0.045, k)
	e.background_color = env_in.bg.lerp(Color(0.23, 0.245, 0.27), k)
	e.ambient_light_color = env_in.amb.lerp(Color(0.42, 0.45, 0.5), k)
	e.volumetric_fog_density = lerpf(env_in.vol, 0.045, k)
	e.volumetric_fog_albedo = env_in.vol_c.lerp(Color(0.85, 0.88, 0.92), k)

func _start() -> void:
	started = true
	hud.start_screen.visible = false
	Audio.start(); G.start()
	P.frozen = false
	_capture(true)

func _capture(on: bool) -> void:
	if test_mode: return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if on else Input.MOUSE_MODE_VISIBLE

func _pause() -> void:
	paused = true; get_tree().paused = true; hud.pause_screen.visible = true; _capture(false)

func _resume() -> void:
	paused = false; get_tree().paused = false; hud.pause_screen.visible = false; _capture(true)

func open_overlay(kind: String) -> void:
	overlay = kind; P.frozen = true; _capture(false); hud.set_prompt("")
	match kind:
		"term": term.open_ui()
		"disp": disp.open_ui()
		"panel": panel_ui.open_ui()
		"note": hud.note_screen.visible = true; Audio.play("step", -8.0); wrist.add_note("Записка В. Калинина")

func _close_overlay() -> void:
	overlay = ""; P.frozen = false
	if not G.S.ended: _capture(true)

func _end() -> void:
	var tw := create_tween(); tw.tween_property(hud.fade, "color:a", 1.0, 2.5)
	await get_tree().create_timer(2.6).timeout
	_capture(false)
	var s := int(G.S.t)
	hud.show_end("Глава 0 · Электрощитовая\nВремя: %02d:%02d%s\n\nДальше — магистраль, машины и первые ответы." % [s / 60, s % 60, (" · выбило ввод: %d" % G.S.trips) if G.S.trips else ""])

## ---------- ввод ----------
func _input(e: InputEvent) -> void:
	## правая кнопка мыши — отойти от терминала (без Escape)
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_RIGHT:
		if overlay == "term": term.close(); get_viewport().set_input_as_handled(); return
		if overlay == "disp": disp.close(); get_viewport().set_input_as_handled(); return
	if not (e is InputEventKey) or not e.pressed or e.echo:
		if e is InputEventMouseButton and e.pressed and started and overlay == "" and not paused and not G.S.ended:
			_capture(true)
		return
	## полный экран: F11 или Alt+Enter — в любой момент
	if e.physical_keycode == KEY_F11 or (e.physical_keycode == KEY_ENTER and e.alt_pressed):
		toggle_fullscreen(); get_viewport().set_input_as_handled(); return
	if not started or G.S.ended: return
	var k: int = e.physical_keycode
	if overlay == "term": term.key(e); get_viewport().set_input_as_handled(); return
	if overlay == "disp": disp.key(e); get_viewport().set_input_as_handled(); return
	if overlay == "panel": panel_ui.key(e); get_viewport().set_input_as_handled(); return
	if overlay == "note":
		if k == KEY_E or k == KEY_ESCAPE or k == KEY_P: hud.note_screen.visible = false; _close_overlay()
		return
	if paused:
		if k == KEY_ESCAPE or k == KEY_P: _resume()
		return
	match k:
		KEY_TAB:
			wrist.raise(not wrist.raised)
			if wrist.raised: G.S.raised_once = true
		KEY_1, KEY_2, KEY_3:
			if wrist.raised: wrist.set_page(k - KEY_1)
		KEY_E: interact()
		KEY_F:
			P.toggle_flash(); B.click()
		KEY_ESCAPE, KEY_P: _pause()
	get_viewport().set_input_as_handled()

## ---------- взаимодействие ----------
func _prompt_for(a: String) -> String:
	match a:
		"obj": return target_obj.prompt_text() if is_instance_valid(target_obj) else ""
		"dispatch": return "E — сесть за терминал диспетчерской"
		"lift": return "Служебный лифт %s · нет питания, пульт заблокирован" % target_label
		"door": return "E — закрыть дверь" if W.door.target else "E — открыть дверь"
		"panel": return "E — открыть щиток ЩР-6"
		"terminal": return "E — встать за терминал" if G.term_on() else "Терминал без питания"
		"note": return "E — прочитать записку"
		"plaque": return "Участок 6 · введён в эксплуатацию в 2047"
		"locked": return "Дверь %s · заперта" % target_label
		"gate": return "Решётка ГД-6 заперта. Привод — с пульта" if G.S.gate == "closed" else ""
	return ""

func interact() -> void:
	if target == "": return
	B.reach()
	match target:
		"obj":
			if is_instance_valid(target_obj): target_obj.use(self)
		"dispatch":
			if disp: open_overlay("disp")
		"lift":
			Audio.play("click"); G.toast("Лифт обесточен. Нужно питание шахты и код пульта")
		"door":
			if not W.door.target: W.door.target = 1.0; Audio.play("door")
			else: W.door.target = 0.0; Audio.play("door", -4.0, 1.15)
		"panel": open_overlay("panel")
		"terminal":
			if G.term_on(): open_overlay("term")
			else: Audio.play("click"); G.toast("Терминал без питания. Нужна линия Б на щитке")
		"note": open_overlay("note")
		"locked": Audio.play("click"); G.toast("Заперто. Замок без питания")

func pick_target() -> String:
	var from := P.cam.global_position
	var to := from + -P.cam.global_transform.basis.z * 2.3
	var q := PhysicsRayQueryParameters3D.create(from, to, 2)
	q.collide_with_areas = false; q.collide_with_bodies = true
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	target = ""; target_label = ""; target_obj = null
	if hit and hit.collider.has_meta("act"):
		target = hit.collider.get_meta("act"); target_label = hit.collider.get_meta("label", "")
		target_obj = hit.collider.get_meta("obj") if hit.collider.has_meta("obj") else null
	hud.set_prompt(_prompt_for(target) if (target != "" and overlay == "") else "")
	return target

func _relay(l: Dictionary) -> void:
	var d: float = abs(l.pos.z - P.global_position.z)
	if d > 80 or relay_t > 0: return
	relay_t = 0.05
	Audio.play("relay", -4.0 - d * 0.3, 1.0, d > 25)

## ---------- кадр ----------
func _process(dt: float) -> void:
	relay_t -= dt
	if started and not paused:
		G.update(dt)
		L.update(dt, P.cam.global_position)
		var near := func(n: Node3D) -> bool: return n != null and Vector2(P.global_position.x - n.global_position.x, P.global_position.z - n.global_position.z).length() < 2.6
		if near.call(W.panel_node): wrist.set_link("ЩР-6 · " + (("НАГРУЗКА %d/20 А" % G.load_a()) if G.S.qf0 else "ВВОД ОТКЛ"))
		elif near.call(W.console_node): wrist.set_link("ПУЛЬТ · " + ("ГОТОВ" if G.term_on() else "НЕТ ПИТАНИЯ"))
		else: wrist.set_link("")
		pick_target()
	elif not started:
		L.update(dt, P.cam.global_position)
	B.busy = overlay != ""
	B.update(dt, P.cam)
	dust.global_position = Vector3(0, 4.5, P.global_position.z)
	dust.visible = P.global_position.z < -0.3 and P.global_position.y > -1.0
	## дальние планы рисуем только там, откуда их видно
	var pz := P.global_position.z
	if W.shaft: W.shaft.visible = pz < World.GATE_Z + 6.0
	_zone(dt)
