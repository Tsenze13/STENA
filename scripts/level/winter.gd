@tool
## Снаружи: ядерная зима у подножия Стены. Снег, сугробы, мёртвые фонари и брошенная машина у тропы,
## провода, уходящие в Стену. Сама Стена — серый обледенелый фасад: рёбра-пилястры, карниз, огромная
## надпись «ШЛЮЗ 6»; выше всё тонет в метели, только авиаогни мигают в небе. Метель, ветер и серый туман
## включает main.gd, когда игрок снаружи. Невидимые стены не дают уйти в метель слишком далеко.
class_name Winter
extends LevelPart

const FACE := Stairwell.BACK + 0.2    # фасад Стены (z)

@export var area := Vector2(14.0, 50.0):    # куда можно уйти: ±x, до z
	set(v): area = v; changed()

var lamps: Array = []

func _build() -> void:
	lamps = []
	var y0 := Stairwell.floor_y(1)
	var snow := Tex.snow()
	## земля
	var g := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(600, 300); g.mesh = pm; g.material_override = snow
	g.position = Vector3(0, y0, FACE + 150); gen.add_child(g)
	Geo.solid(solids, Vector3(600, 1, 300), Vector3(0, y0 - 0.5, FACE + 150))
	## фасад Стены рядом (с отверстием под тамбур x −2.8..−0.4, высота 3)
	var face := Tex.surface("wall_frost", Color(0.42, 0.45, 0.49), 0.9, 0.0, 0.12, 0.5, 2.5, 63, 0.03)
	var T := 0.3; var zf := FACE + T / 2; var HH := 55.0
	wall(Vector3(57.2, HH, T), Vector3(-31.4, y0 + HH / 2, zf), face)
	wall(Vector3(60.4, HH, T), Vector3(29.8, y0 + HH / 2, zf), face)
	wall(Vector3(2.4, HH - 3.0, T), Vector3(-1.6, y0 + 3.0 + (HH - 3.0) / 2, zf), face, false)
	## швы панелей
	var seam := Tex.plain("face_seam", Color(0.18, 0.19, 0.21), 0.9)
	var x := -60.0
	while x <= 60.0:
		if absf(x + 1.6) > 2.0: B.box(Vector3(0.12, HH, 0.05), seam, Vector3(x, y0 + HH / 2, FACE + T + 0.01))
		x += 6.0
	var y := 3.0
	while y < HH:
		B.box(Vector3(120, 0.1, 0.05), seam, Vector3(0, y0 + y, FACE + T + 0.01)); y += 3.0
	## рёбра-пилястры и карниз
	for px in [-36.0, -14.0, 12.0, 34.0]:
		wall(Vector3(3.0, 300.0, 2.5), Vector3(px, y0 + 150.0, FACE + T + 1.25), face)
	B.box(Vector3(120, 1.6, 3.5), face, Vector3(0, y0 + 22.0, FACE + T + 1.75))
	B.box(Vector3(120, 0.25, 3.7), snow, Vector3(0, y0 + 22.9, FACE + T + 1.75))
	## потёки льда
	for k in 18:
		var dx := R(-40, 40)
		if absf(dx + 1.6) < 3.0: continue
		Geo.decal(gen, Vector2(R(0.6, 2.0), R(4.0, 14.0)), Color(0.82, 0.88, 0.95, 0.55), Vector3(dx, y0 + R(4, 20), FACE + T + 0.02), Vector3.ZERO, k, 0.7)
	Geo.paint(gen, "ШЛЮЗ 6", 1.4, Color(0.78, 0.76, 0.7), Vector3(-1.6, y0 + 6.2, FACE + T + 0.02), Vector3.ZERO, 0.45)
	## дальше фасад — без тумана, со своей дымкой (метель)
	var wm := Fx.wall_mat(1, 8.0, 14.0, 0.012, Color(0.1, 0.105, 0.115), Color(1.0, 0.7, 0.4) * 0.6, Color(0.6, 0.7, 0.9) * 0.5, Color(0.23, 0.245, 0.27), 0.028, 0.12, 0.2)
	Fx.plane(gen, wm, Vector3(-780.0, y0 + 1500.0, FACE + 0.05), 1440.0, 3000.0, 1)
	Fx.plane(gen, wm, Vector3(780.0, y0 + 1500.0, FACE + 0.05), 1440.0, 3000.0, 1)
	Fx.plane(gen, wm, Vector3(0.0, y0 + 1500.0 + HH / 2, FACE + 0.05), 120.0, 3000.0 - HH, 1)
	## сугробы
	var drift := func(p: Vector3, s: Vector3, collide := false):
		var sm := SphereMesh.new(); sm.radius = 1.0; sm.height = 2.0; sm.radial_segments = 16; sm.rings = 8
		B.add(sm, snow, Transform3D(Basis().scaled(s), p))
		if collide: Geo.solid(solids, Vector3(s.x * 1.4, s.y, s.z * 1.4), p)
	var dx2 := -50.0
	while dx2 < 50.0:
		if absf(dx2 + 1.6) > 3.5:
			drift.call(Vector3(dx2, y0 - 0.3, FACE + T + R(0.5, 1.5)), Vector3(R(2.5, 5.0), R(1.0, 2.2), R(1.2, 2.5)))
		dx2 += R(3.0, 6.0)
	for k in 26:
		var p := Vector3(R(-area.x - 20, area.x + 20), y0 - 0.25, R(FACE + 6, area.y + 30))
		if absf(p.x - 1.0) < 3.0 and p.z < area.y: continue
		drift.call(p, Vector3(R(1.0, 3.5), R(0.4, 1.2), R(1.0, 3.0)))
	## мёртвые фонари вдоль тропы и провода от них в Стену
	var pole := Tex.metal("pole", Color(0.3, 0.3, 0.3))
	var prev := Vector3.ZERO
	for i in 4:
		var pz := 14.0 + i * 10.0
		var bp := Vector3(2.4, y0, pz)
		B.cyl(0.09, 0.12, 6.0, pole, bp + Vector3(0, 3.0, 0), Vector3.ZERO, 8)
		B.box(Vector3(1.2, 0.08, 0.08), pole, bp + Vector3(-0.6, 5.9, 0))
		B.box(Vector3(0.4, 0.12, 0.2), Tex.dark_metal(), bp + Vector3(-1.15, 5.85, 0))
		B.box(Vector3(0.36, 0.06, 0.16), snow, bp + Vector3(-1.15, 5.95, 0))
		drift.call(bp + Vector3(0, -0.2, 0), Vector3(0.8, 0.6, 0.8))
		Geo.solid(solids, Vector3(0.3, 6, 0.3), bp + Vector3(0, 3, 0))
		var top := bp + Vector3(0, 5.7, 0)
		var to: Vector3 = prev if i > 0 else Vector3(3.5, y0 + 12.0, FACE + T)
		B.add(Geo.tube(Geo.catenary(top, to, 1.2 if i > 0 else 2.0, 14), 0.015), Tex.cable(), Transform3D())
		prev = top
	## брошенная машина (будка на шасси), занесённая снегом
	var tr := Node3D.new(); tr.position = Vector3(7.5, y0, 22.0); tr.rotation.y = 0.35; gen.add_child(tr)
	var tb := Geo.Batch.new()
	var green := Tex.surface("truck", Color(0.22, 0.27, 0.2), 0.75, 0.2, 0.8, 0.5, 2.0, 64)
	tb.box(Vector3(2.2, 1.6, 1.7), green, Vector3(0, 1.3, -2.4))
	tb.box(Vector3(2.4, 2.2, 3.6), green, Vector3(0, 1.6, 0.4))
	tb.box(Vector3(1.9, 0.5, 0.05), Tex.plain("truck_glass", Color(0.05, 0.06, 0.07), 0.1, 0.4), Vector3(0, 1.7, -3.26))
	for wz in [-2.4, 0.0, 1.4]:
		for s in [-1.0, 1.0]:
			tb.cyl(0.5, 0.5, 0.35, Tex.plain("tyre", Color(0.06, 0.06, 0.06), 0.9), Vector3(s * 1.05, 0.35, wz), Vector3(0, 0, PI / 2), 14)
	tb.box(Vector3(2.5, 0.3, 3.7), snow, Vector3(0, 2.8, 0.4))
	tb.box(Vector3(2.3, 0.25, 1.8), snow, Vector3(0, 2.2, -2.4))
	tb.build(tr)
	Geo.solid(solids, Vector3(2.6, 3.0, 6.0), Vector3(7.5, y0 + 1.5, 21.0), Vector3(0, 0.35, 0))
	drift.call(Vector3(6.2, y0 - 0.2, 20.0), Vector3(2.0, 1.0, 3.0))
	## авиаогни высоко на Стене — мигают в метели
	var pts := []
	for k in 60:
		pts.append([Vector3(R(-400, 400), y0 + R(60, 900), FACE + 0.3), Color(3.0, 0.12, 0.06), R(3.0, 7.0), 1])
	Fx.points(gen, pts, Vector3.ZERO, 0.006)
	## границы: в метель дальше не уйти
	Geo.solid(solids, Vector3(1, 20, area.y), Vector3(-area.x, y0 + 10, FACE + area.y / 2))
	Geo.solid(solids, Vector3(1, 20, area.y), Vector3(area.x, y0 + 10, FACE + area.y / 2))
	Geo.solid(solids, Vector3(area.x * 2, 20, 1), Vector3(0, y0 + 10, FACE + area.y))
