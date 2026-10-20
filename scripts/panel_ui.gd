## Щиток ЩР-6 крупным планом. Рисуется как настоящий щиток: корпус, DIN-рейка, модульные автоматы
## с рычажками, контактор привода, амперметр, сигнальные лампы, бумажные бирки. Масштабируется под экран.
## Щелчок по автомату (или клавиши 1 2 3) — переключить. E или Esc — закрыть.
class_name PanelUI
extends Control

var G: Game
var is_open := false
var on_close: Callable
var ang := -50.0                 # стрелка амперметра, градусы
var lever := {}                  # положение рычажков 0 (низ, O) .. 1 (верх, I)
var hover := ""
var board: _Board
var hint: Label

## автоматы: ключ, имя, подпись, номинал, ширина в модулях
const BRK := [["qf0", "QF0", "ВВОД", Game.LIMIT, 2], ["qf1", "QF1", "А · СВЕТ", 10, 1], ["qf2", "QF2", "Б · ПУЛЬТ", 4, 1]]
const MOD := 80.0                # ширина модуля автомата на чертеже
const DW := 760.0                # размер «чертежа» щитка
const DH := 560.0

func setup(g: Game) -> void:
	G = g
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new(); dim.color = Color(0, 0, 0, 0.62); dim.set_anchors_preset(Control.PRESET_FULL_RECT); dim.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(dim)
	board = _Board.new(); board.ui = self; board.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(board)
	hint = Label.new(); hint.text = "Щёлкай по рычажкам автоматов (или 1 2 3) · E — закрыть щиток"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; hint.add_theme_color_override("font_color", Color(0.62, 0.58, 0.5))
	hint.add_theme_font_size_override("font_size", 15); hint.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(hint)
	for b in BRK: lever[b[0]] = 0.0
	resized.connect(_layout)
	visible = false

## щиток по центру, сколько влезает по высоте и ширине
func _layout() -> void:
	var vs := get_viewport_rect().size
	var s := maxf(0.2, minf(vs.x * 0.94 / DW, (vs.y - 40.0) * 0.94 / DH))
	board.scale = Vector2(s, s)
	board.size = Vector2(DW, DH)
	board.position = Vector2((vs.x - DW * s) / 2, (vs.y - 40.0 - DH * s) / 2)
	hint.position = Vector2(0, board.position.y + DH * s + 8); hint.size = Vector2(vs.x, 24)

## прямоугольник рычажка/автомата в координатах чертежа
func brk_rect(i: int) -> Rect2:
	var x := 112.0
	for j in i: x += BRK[j][4] * MOD + 14.0
	return Rect2(x, 268, BRK[i][4] * MOD, 150)

func _gui_input(e: InputEvent) -> void:
	if not is_open: return
	if e is InputEventMouseMotion or e is InputEventMouseButton:
		var p: Vector2 = (e.position - board.position) / board.scale
		var h := ""
		for i in BRK.size():
			if brk_rect(i).grow(6).has_point(p): h = BRK[i][0]
		if h != hover: hover = h; board.queue_redraw()
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and h != "":
			_toggle(h)

func _toggle(k: String) -> void:
	Audio.play("click")
	G.set_line(k, not G.S[k])
	render()

func render() -> void:
	board.queue_redraw()

func _process(dt: float) -> void:
	if not is_open: return
	_layout()
	var target := -50.0 + 100.0 * minf(G.load_a(), 30.0) / 30.0
	ang += (target - ang) * minf(1.0, dt * 6.0) + (randf() - 0.5) * 0.15 * float(G.load_a() > 0)
	for b in BRK:
		var want := 1.0 if G.S[b[0]] else 0.0
		lever[b[0]] += (want - lever[b[0]]) * minf(1.0, dt * 22.0)
	board.queue_redraw()

func open_ui() -> void:
	is_open = true; visible = true
	_layout()
	for b in BRK: lever[b[0]] = 1.0 if G.S[b[0]] else 0.0
	ang = -50.0 + 100.0 * minf(G.load_a(), 30.0) / 30.0
	render(); Audio.play("heavy", -4.0)

func close() -> void:
	is_open = false; visible = false; hover = ""; Audio.play("click", -6.0)
	if on_close.is_valid(): on_close.call()

func key(e: InputEventKey) -> void:
	var c := e.physical_keycode
	if c == KEY_ESCAPE or c == KEY_E or c == KEY_P: close()
	elif c >= KEY_1 and c <= KEY_3: _toggle(BRK[c - KEY_1][0])

## ================= рисунок щитка =================
class _Board extends Control:
	var ui
	var font: Font
	var pen: Font
	var grain: Texture2D

	func _ready() -> void:
		var f := SystemFont.new(); f.font_names = PackedStringArray(["Oswald", "Bahnschrift SemiCondensed", "Arial Narrow", "DejaVu Sans Condensed", "sans-serif"]); f.font_weight = 600; font = f
		var p := SystemFont.new(); p.font_names = PackedStringArray(["Segoe Print", "Comic Sans MS", "DejaVu Serif"]); pen = p
		var img := Tex.noise_image(256, 5, 0.06, 1.2, 1.0, 4)
		grain = ImageTexture.create_from_image(img)

	func txt(s: String, pos: Vector2, fs: int, col: Color, w := -1.0, f: Font = null, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
		draw_string(f if f else font, pos, s, align, w, fs, col)

	func screw(c: Vector2, r := 5.0) -> void:
		draw_circle(c, r, Color(0.62, 0.62, 0.6)); draw_circle(c, r, Color(0.25, 0.25, 0.24), false, 1.0)
		draw_line(c - Vector2(r * 0.7, 0), c + Vector2(r * 0.7, 0), Color(0.25, 0.25, 0.24), 1.5)

	func lamp(c: Vector2, on: bool, col: Color, label: String) -> void:
		draw_circle(c, 21, Color(0.72, 0.72, 0.7)); draw_circle(c, 21, Color(0.3, 0.3, 0.3), false, 1.5)
		if on:
			draw_circle(c, 30, Color(col.r, col.g, col.b, 0.18))
			draw_circle(c, 15, col.lightened(0.15)); draw_circle(c - Vector2(4, 5), 5, Color(1, 1, 0.9, 0.8))
		else:
			draw_circle(c, 15, col.darkened(0.75)); draw_circle(c - Vector2(4, 5), 4, Color(1, 1, 1, 0.12))
		_tag(Rect2(c.x - 40, c.y + 28, 80, 22), label)

	## бумажная бирка: текст сам ужимается, чтобы влезть
	func _tag(r: Rect2, s: String) -> void:
		draw_rect(r, Color(0.86, 0.85, 0.8)); draw_rect(r, Color(0.2, 0.2, 0.2), false, 1.0)
		var fs := 14
		while fs > 8 and font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > r.size.x - 6: fs -= 1
		txt(s, Vector2(r.position.x, r.position.y + r.size.y / 2 + fs * 0.36), fs, Color(0.1, 0.1, 0.1), r.size.x, null, HORIZONTAL_ALIGNMENT_CENTER)

	func _draw() -> void:
		var G: Game = ui.G
		var S: Dictionary = G.S
		var W := size.x; var H := size.y
		## корпус: серо-зелёная эмаль, внутри задняя панель
		draw_rect(Rect2(6, 10, W, H), Color(0, 0, 0, 0.45))
		draw_rect(Rect2(0, 0, W, H), Color(0.42, 0.46, 0.42))
		draw_texture_rect(grain, Rect2(0, 0, W, H), true, Color(1, 1, 1, 0.08))
		draw_rect(Rect2(0, 0, W, H), Color(0.2, 0.22, 0.2), false, 3.0)
		var inn := Rect2(26, 26, W - 52, H - 52)
		draw_rect(inn, Color(0.31, 0.33, 0.31))
		draw_texture_rect(grain, inn, true, Color(1, 1, 1, 0.1))
		draw_rect(inn, Color(0.16, 0.17, 0.16), false, 2.0)
		## петли слева, винты по углам
		for y in [90.0, H - 90.0]:
			draw_rect(Rect2(-8, y - 26, 14, 52), Color(0.3, 0.32, 0.3)); draw_rect(Rect2(-8, y - 26, 14, 52), Color(0.15, 0.15, 0.15), false, 1.0)
		for c in [Vector2(40, 40), Vector2(W - 40, 40), Vector2(40, H - 40), Vector2(W - 40, H - 40)]:
			screw(c, 6)
		## ввод кабелей сверху (сальник) и шапка
		draw_rect(Rect2(118, 26, 150, 22), Color(0.18, 0.19, 0.18))
		for gx in [152.0, 232.0]: draw_circle(Vector2(gx, 37), 9, Color(0.08, 0.08, 0.08))
		txt("ЩР-6", Vector2(300, 82), 44, Color(0.86, 0.72, 0.18))
		txt("~380/220 В · 50 Гц · ВВОД 20 А", Vector2(300, 106), 15, Color(0.85, 0.84, 0.78))
		var tri := PackedVector2Array([Vector2(W - 92, 86), Vector2(W - 62, 36), Vector2(W - 32, 86)])
		draw_colored_polygon(tri, Color(0.95, 0.78, 0.1)); draw_polyline(tri + PackedVector2Array([tri[0]]), Color(0.08, 0.08, 0.08), 3.0)
		txt("⚡", Vector2(W - 74, 80), 26, Color(0.08, 0.08, 0.08))
		## амперметр (справа вверху)
		var ac := Vector2(562, 202)
		draw_rect(Rect2(ac.x - 92, ac.y - 82, 184, 128), Color(0.1, 0.1, 0.1))
		draw_rect(Rect2(ac.x - 84, ac.y - 74, 168, 112), Color(0.9, 0.88, 0.8))
		var piv := ac + Vector2(0, 26)
		for a in range(0, 31, 1):
			var t := deg_to_rad(-90.0 - 50.0 + 100.0 * a / 30.0)
			var big := a % 5 == 0
			var col := Color(0.7, 0.12, 0.1) if a > 20 else Color(0.1, 0.1, 0.1)
			draw_line(piv + Vector2(cos(t), sin(t)) * (82.0 if big else 86.0), piv + Vector2(cos(t), sin(t)) * 92.0, col, 2.0 if big else 1.0)
			if big: txt(str(a), piv + Vector2(cos(t), sin(t)) * 70.0 + Vector2(-12, 6), 14, col, 24, null, HORIZONTAL_ALIGNMENT_CENTER)
		draw_arc(piv, 95, deg_to_rad(-140.0 + 100.0 * 20.0 / 30.0), deg_to_rad(-40.0), 12, Color(0.7, 0.12, 0.1), 4.0)
		txt("A", piv + Vector2(-6, -24), 18, Color(0.1, 0.1, 0.1))
		txt("Э8030", piv + Vector2(30, 6), 10, Color(0.3, 0.3, 0.3))
		var na := deg_to_rad(-90.0 + ui.ang)
		draw_line(piv, piv + Vector2(cos(na), sin(na)) * 88.0, Color(0.05, 0.05, 0.05), 2.5)
		draw_circle(piv, 6, Color(0.1, 0.1, 0.1))
		draw_rect(Rect2(ac.x - 84, ac.y - 74, 168, 50), Color(1, 1, 1, 0.06))
		screw(Vector2(ac.x - 86, ac.y - 76), 4); screw(Vector2(ac.x + 86, ac.y - 76), 4)
		## сигнальные лампы
		lamp(Vector2(330, 178), S.qf0, Color(1, 0.22, 0.12), "СЕТЬ")
		lamp(Vector2(420, 178), S.v, Color(1, 0.62, 0.12), "ПРИВОД ГД-6")
		## вводной кабель к QF0 и медная гребёнка от QF0 к остальным
		var r0: Rect2 = ui.brk_rect(0)
		for k in 2:
			var x := r0.position.x + PanelUI.MOD / 2 + k * PanelUI.MOD
			draw_line(Vector2(x, 46), Vector2(x, r0.position.y + 10), Color(0.12, 0.12, 0.12) if k == 0 else Color(0.4, 0.22, 0.12), 6.0)
		var last: Rect2 = ui.brk_rect(PanelUI.BRK.size() - 1)
		var kx := last.end.x + 14.0
		var bus_y := 258.0
		draw_line(Vector2(r0.position.x + PanelUI.MOD, bus_y), Vector2(kx + 60, bus_y), Color(0.72, 0.45, 0.2), 5.0)
		draw_line(Vector2(r0.position.x + PanelUI.MOD, bus_y), Vector2(r0.position.x + PanelUI.MOD, r0.position.y + 2), Color(0.72, 0.45, 0.2), 4.0)
		for i in range(1, PanelUI.BRK.size()):
			var r: Rect2 = ui.brk_rect(i)
			draw_line(Vector2(r.position.x + PanelUI.MOD / 2, bus_y), Vector2(r.position.x + PanelUI.MOD / 2, r.position.y + 6), Color(0.72, 0.45, 0.2), 4.0)
		draw_line(Vector2(kx + 60, bus_y), Vector2(kx + 60, 270), Color(0.72, 0.45, 0.2), 4.0)
		## DIN-рейка
		var ry := 343.0
		draw_rect(Rect2(92, ry - 18, W - 184, 36), Color(0.68, 0.68, 0.66))
		draw_rect(Rect2(92, ry - 18, W - 184, 36), Color(0.35, 0.35, 0.34), false, 1.0)
		var sx := 100.0
		while sx < W - 100: draw_rect(Rect2(sx, ry - 4, 14, 8), Color(0.45, 0.45, 0.44)); sx += 26.0
		screw(Vector2(104, ry), 5); screw(Vector2(W - 104, ry), 5)
		## автоматы
		for i in PanelUI.BRK.size():
			_breaker(i, S)
		## контактор КМ-V
		var kr := Rect2(kx, 263, 120, 160)
		draw_rect(kr, Color(0.24, 0.25, 0.24)); draw_rect(kr, Color(0.1, 0.1, 0.1), false, 1.5)
		for j in 3:
			screw(Vector2(kx + 24 + j * 36, 280), 6); screw(Vector2(kx + 24 + j * 36, 406), 6)
		draw_rect(Rect2(kx + 30, 318, 60, 40), Color(0.06, 0.06, 0.06))
		draw_rect(Rect2(kx + 38, 326 if S.v else 336, 44, 24), Color(0.85, 0.2, 0.12) if S.v else Color(0.3, 0.3, 0.28))
		txt("КМ-V", Vector2(kx, 308), 16, Color(0.86, 0.85, 0.78), 120, null, HORIZONTAL_ALIGNMENT_CENTER)
		txt("ПМЛ-1100", Vector2(kx, 378), 11, Color(0.6, 0.6, 0.56), 120, null, HORIZONTAL_ALIGNMENT_CENTER)
		txt("упр. с пульта", Vector2(kx, 394), 11, Color(0.6, 0.6, 0.56), 120, null, HORIZONTAL_ALIGNMENT_CENTER)
		## бирки под автоматами
		var tag_y := 428.0
		for i in PanelUI.BRK.size():
			var r: Rect2 = ui.brk_rect(i)
			_tag(Rect2(r.position.x, tag_y, r.size.x, 24), "%s %d А" % [PanelUI.BRK[i][2], PanelUI.BRK[i][3]])
		_tag(Rect2(kx, tag_y, 120, 24), "V · ПРИВОД 14 А")
		## записка от руки
		var note := Rect2(112, 466, 480, 60)
		draw_set_transform(note.position + note.size / 2, -0.012)
		draw_rect(Rect2(-note.size / 2, note.size), Color(0.92, 0.9, 0.8))
		draw_rect(Rect2(-note.size.x / 2 + 200, -note.size.y / 2 - 8, 60, 16), Color(0.85, 0.8, 0.55, 0.7))
		txt("Ввод 20 А! Свет 10 + пульт 4 + привод 14 = 28 — выбьет.", Vector2(-note.size.x / 2 + 12, -6), 14, Color(0.15, 0.17, 0.4), -1, pen)
		txt("Привод (V) — только с пульта.                    В.К.", Vector2(-note.size.x / 2 + 12, 20), 14, Color(0.15, 0.17, 0.4), -1, pen)
		draw_set_transform(Vector2.ZERO)

	func _breaker(i: int, S: Dictionary) -> void:
		var b: Array = PanelUI.BRK[i]
		var r: Rect2 = ui.brk_rect(i)
		var on: bool = S[b[0]]
		var tripped: bool = b[0] == "qf0" and not on and S.trips > 0
		var body := Color(0.93, 0.9, 0.8) if b[0] == "qf0" else Color(0.9, 0.9, 0.87)
		draw_rect(Rect2(r.position + Vector2(3, 4), r.size), Color(0, 0, 0, 0.35))
		draw_rect(r, body); draw_rect(r, Color(0.35, 0.35, 0.33), false, 1.5)
		## клеммы сверху и снизу
		for m in b[4]:
			var cx: float = r.position.x + PanelUI.MOD / 2 + m * PanelUI.MOD
			draw_rect(Rect2(cx - 14, r.position.y + 2, 28, 18), Color(0.18, 0.18, 0.18)); screw(Vector2(cx, r.position.y + 11), 6)
			draw_rect(Rect2(cx - 14, r.end.y - 20, 28, 18), Color(0.18, 0.18, 0.18)); screw(Vector2(cx, r.end.y - 11), 6)
		## рычажок в окне
		var win := Rect2(r.position.x + 10, r.position.y + 34, r.size.x - 20, 70)
		draw_rect(win, Color(0.2, 0.2, 0.2))
		var k: float = ui.lever[b[0]]
		var lv := Rect2(win.position.x + 4, win.position.y + 4 + (1.0 - k) * 30.0, win.size.x - 8, 32)
		draw_rect(lv, Color(0.08, 0.08, 0.08) if b[0] != "qf0" else Color(0.55, 0.1, 0.08))
		draw_rect(Rect2(lv.position.x, lv.position.y + (0 if k > 0.5 else lv.size.y - 5), lv.size.x, 5), Color(1, 1, 1, 0.15))
		if ui.hover == b[0]: draw_rect(r.grow(4), Color(1, 0.75, 0.3), false, 2.0)
		txt("I", Vector2(r.end.x - 9, win.position.y + 14), 12, Color(0.1, 0.1, 0.1))
		txt("O", Vector2(r.end.x - 10, win.end.y - 2), 12, Color(0.1, 0.1, 0.1))
		## окошко индикатора и маркировка
		draw_rect(Rect2(r.position.x + 12, win.end.y + 6, 18, 9), Color(0.75, 0.15, 0.1) if on else Color(0.2, 0.55, 0.2))
		txt(b[1], Vector2(r.position.x + 34, win.end.y + 15), 13, Color(0.1, 0.1, 0.1))
		txt("C%d" % b[3], Vector2(r.position.x + 12, win.end.y + 31), 12, Color(0.3, 0.3, 0.3))
		if tripped:
			var tr := Rect2(r.position.x - 6, r.position.y - 26, r.size.x + 12, 22)
			draw_rect(tr, Color(0.75, 0.12, 0.08)); txt("ВЫБИЛО", Vector2(tr.position.x, tr.end.y - 5), 14, Color(1, 0.95, 0.85), tr.size.x, null, HORIZONTAL_ALIGNMENT_CENTER)
