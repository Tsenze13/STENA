@tool
## Диспетчерская на 1 этаже шлюза — комната героя. Сюда приходят заявки (терминал «Диспетчер-2» —
## отдельная сцена DispatchConsole). На стене мнемосхема участка с мигающей лампой неисправности,
## шкаф, стул, раскладушка. Вход — дверь из шлюза (левая стена площадки 1 этажа).
class_name DispatchRoom
extends LevelPart

const X0 := -7.6
const X1 := -3.2
const Z0 := -1.2
const Z1 := 2.2

var lamps: Array = []
var mimic: _Mimic

func _build() -> void:
	lamps = []
	var y0 := Stairwell.floor_y(1)
	var H := 2.9
	var band := Tex.paint_band(); var conc := Tex.concrete()
	var two := func(size: Vector3, pos: Vector3):
		wall(Vector3(size.x, 1.5, size.z), Vector3(pos.x, y0 + 0.75, pos.z), band)
		wall(Vector3(size.x, H - 1.5, size.z), Vector3(pos.x, y0 + 1.5 + (H - 1.5) / 2, pos.z), conc)
	var cx := (X0 + X1) / 2; var cz := (Z0 + Z1) / 2
	two.call(Vector3(0.2, 0, Z1 - Z0 + 0.4), Vector3(X0 - 0.1, 0, cz))
	two.call(Vector3(X1 - X0 + 0.2, 0, 0.2), Vector3(cx, 0, Z0 - 0.1))
	two.call(Vector3(X1 - X0 + 0.2, 0, 0.2), Vector3(cx, 0, Z1 + 0.1))
	wall(Vector3(X1 - X0, 0.14, Z1 - Z0), Vector3(cx, y0 - 0.07, cz), Tex.surface("linoleum", Color(0.32, 0.27, 0.2), 0.7, 0.0, 1.5, 0.3, 1.0, 51))
	wall(Vector3(X1 - X0, 0.12, Z1 - Z0), Vector3(cx, y0 + H + 0.06, cz), Tex.ceiling(), false)
	## потолочный светильник с лампой дневного света
	var lp := Vector3(cx, y0 + H - 0.08, cz)
	B.box(Vector3(1.3, 0.08, 0.22), Tex.plain("lum", Color(0.75, 0.75, 0.72), 0.5), lp)
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(1.2, 0.03, 0.06); mi.mesh = bm
	var gm := StandardMaterial3D.new(); gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; gm.albedo_color = Color(0.6, 0.65, 0.7)
	mi.material_override = gm; mi.position = lp - Vector3(0, 0.05, 0); gen.add_child(mi)
	lamps.append({"kind": "tube", "pos": lp - Vector3(0, 0.3, 0), "grp": "L", "lvl": 1.0, "on": 1, "fl": 0.0, "delay": 0.0, "mesh": mi, "tint": Color(0.95, 0.95, 0.9), "flicker": true})
	## мнемосхема участка на стене (рисуется в SubViewport, лампа неисправности мигает)
	var vp := SubViewport.new(); vp.size = Vector2i(640, 340); vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS; gen.add_child(vp)
	mimic = _Mimic.new(); mimic.size = Vector2(640, 340); vp.add_child(mimic)
	B.box(Vector3(2.5, 1.4, 0.06), Tex.metal("mimic", Color(0.3, 0.33, 0.32)), Vector3(cx + 0.3, y0 + 1.75, Z0 + 0.03))
	var q := QuadMesh.new(); q.size = Vector2(2.36, 1.25)
	var mq := MeshInstance3D.new(); mq.mesh = q
	var mm := StandardMaterial3D.new(); mm.albedo_texture = vp.get_texture(); mm.emission_enabled = true; mm.emission_texture = vp.get_texture(); mm.emission_energy_multiplier = 0.06; mm.roughness = 0.5
	mq.material_override = mm; mq.position = Vector3(cx + 0.3, y0 + 1.75, Z0 + 0.065); gen.add_child(mq)
	## шкаф, стул, раскладушка
	var grey := Tex.metal("locker", Color(0.38, 0.4, 0.38))
	wall(Vector3(0.5, 1.9, 0.9), Vector3(X1 - 0.35, y0 + 0.95, Z0 + 0.55), grey)
	B.box(Vector3(0.012, 1.8, 0.012), Tex.plain("seam", Color(0.08, 0.08, 0.08), 0.9), Vector3(X1 - 0.6, y0 + 0.95, Z0 + 0.55))
	var chair := Tex.plain("chair", Color(0.25, 0.2, 0.15), 0.7)
	B.box(Vector3(0.45, 0.05, 0.45), chair, Vector3(X0 + 1.4, y0 + 0.47, 0.5))
	B.box(Vector3(0.05, 0.5, 0.45), chair, Vector3(X0 + 1.62, y0 + 0.75, 0.5))
	for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		B.box(Vector3(0.03, 0.47, 0.03), Tex.dark_metal(), Vector3(X0 + 1.4 + c.x * 0.2, y0 + 0.235, 0.5 + c.y * 0.2))
	var cot := Tex.plain("cot", Color(0.3, 0.32, 0.27), 0.95)
	wall(Vector3(1.9, 0.08, 0.75), Vector3(cx + 0.2, y0 + 0.42, Z1 - 0.45), cot)
	B.box(Vector3(1.9, 0.38, 0.03), Tex.dark_metal(), Vector3(cx + 0.2, y0 + 0.2, Z1 - 0.1))
	B.box(Vector3(0.45, 0.1, 0.6), Tex.plain("pillow", Color(0.6, 0.6, 0.56), 0.95), Vector3(cx - 0.55, y0 + 0.51, Z1 - 0.45))
	Geo.paint(gen, "ДИСПЕТЧЕРСКИЙ ПУНКТ ШЛЮЗА 6", 0.1, Color(0.85, 0.83, 0.76), Vector3(cx + 0.3, y0 + 2.6, Z0 + 0.01), Vector3.ZERO, 0.3)

## мнемосхема: схема шлюза и участков, лампа неисправности на 6 этаже мигает
class _Mimic extends Control:
	var t := 0.0
	func _process(dt: float) -> void:
		t += dt; queue_redraw()
	func _draw() -> void:
		var f := ThemeDB.fallback_font
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.42, 0.46, 0.43))
		var line := Color(0.12, 0.14, 0.13)
		draw_string(f, Vector2(20, 34), "МНЕМОСХЕМА · ШЛЮЗ 6 · УЧАСТКИ 6–7", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, line)
		## шлюз: этажи
		for k in 14:
			var y := 310.0 - k * 19.0
			draw_rect(Rect2(40, y - 12, 70, 14), Color(0.5, 0.54, 0.5)); draw_rect(Rect2(40, y - 12, 70, 14), line, false, 1.5)
			draw_string(f, Vector2(116, y), str(k + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, line)
		draw_line(Vector2(75, 300), Vector2(75, 50), line, 3.0)
		## магистраль от 6 этажа
		var y6 := 310.0 - 5 * 19.0 - 5
		draw_line(Vector2(110, y6), Vector2(600, y6), line, 5.0)
		for x in [260.0, 420.0]:
			draw_line(Vector2(x, y6 - 14), Vector2(x, y6 + 14), line, 3.0)
		draw_string(f, Vector2(170, y6 - 20), "УЧ.6  ЩР-6", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, line)
		draw_string(f, Vector2(272, y6 - 20), "ГД-6", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, line)
		draw_string(f, Vector2(330, y6 - 20), "УЧ.7", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, line)
		draw_string(f, Vector2(432, y6 - 20), "КОЛОДЕЦ 7-К", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, line)
		draw_string(f, Vector2(520, y6 + 30), "→ ДАЛЕЕ", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, line)
		## лампы: тёмные, одна мигает красным (неисправность ЩР-6)
		for x in [140.0, 200.0, 300.0, 360.0, 470.0, 560.0]:
			draw_circle(Vector2(x, y6), 7, Color(0.18, 0.12, 0.1))
		var on := int(t * 2.0) % 2 == 0
		draw_circle(Vector2(200, y6), 8, Color(1, 0.2, 0.1) if on else Color(0.3, 0.08, 0.05))
		draw_string(f, Vector2(20, 330), "ИСПРАВНО: —     НЕИСПРАВНОСТЬ: ЩР-6", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, line)
