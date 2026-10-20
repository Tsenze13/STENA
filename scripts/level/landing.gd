@tool
## Лестничная площадка 6 этажа: стены (снизу масляная краска, выше побелка), плитка, лестница вниз и вверх
## с промежуточной площадкой, окно (за ним — город и Стена, см. outside.gd), батарея, подоконник с цветами,
## лампочка на проводе, открытая проводка на изоляторах, копоть от спичек на потолке, облезлая краска, надписи.
## Квартирные двери, этажный щиток, объявление — отдельные узлы (props), их можно двигать в редакторе.
class_name Landing
extends LevelPart

const WIN_Z := 2.2          # центр окна
const WIN := Vector2(1.4, 1.3)
const WIN_Y := 1.75

var bulb: MeshInstance3D
var lamp := {}

func _build() -> void:
	var white := Tex.whitewash(); var green := Tex.green_paint()
	var two := func(size_xz: Vector2, pos: Vector3, h0 := 0.0, h1 := 3.0):
		## кусок стены: снизу до 1,5 м зелёная краска, выше побелка
		var lo := clampf(1.5, h0, h1)
		if lo > h0: wall(Vector3(size_xz.x, lo - h0, size_xz.y), Vector3(pos.x, (h0 + lo) / 2, pos.z), green)
		if h1 > lo: wall(Vector3(size_xz.x, h1 - lo, size_xz.y), Vector3(pos.x, (lo + h1) / 2, pos.z), white)
	## задняя и правая стены
	two.call(Vector2(6.4, 0.2), Vector3(0, 0, 4.1))
	two.call(Vector2(0.2, 4), Vector3(3.1, 0, 2))
	## левая стена с проёмом окна
	var z0 := WIN_Z - WIN.x / 2; var z1 := WIN_Z + WIN.x / 2
	var y0 := WIN_Y - WIN.y / 2; var y1 := WIN_Y + WIN.y / 2
	two.call(Vector2(0.2, z0), Vector3(-3.1, 0, z0 / 2))
	two.call(Vector2(0.2, 4.0 - z1), Vector3(-3.1, 0, (z1 + 4.0) / 2))
	two.call(Vector2(0.2, WIN.x), Vector3(-3.1, 0, WIN_Z), 0.0, y0)
	two.call(Vector2(0.2, WIN.x), Vector3(-3.1, 0, WIN_Z), y1, 3.0)
	## лестничная клетка выше: стены до потолка следующего этажа
	wall(Vector3(2.4, 3.1, 0.2), Vector3(2.0, 4.55, 4.1), white, false)
	wall(Vector3(0.2, 3.1, 4.2), Vector3(3.1, 4.55, 2.0), white, false)
	wall(Vector3(2.6, 3.1, 0.2), Vector3(1.9, 4.55, 0.0), white, false)
	## пол — плитка «шахматкой»
	wall(Vector3(3.8, 0.1, 4), Vector3(-1.1, -0.05, 2), Tex.tiles())
	## потолок над площадкой (это плита 7 этажа) и высокий потолок над лестницей
	wall(Vector3(3.9, 0.12, 4.2), Vector3(-1.15, 3.06, 2.0), Tex.ceiling(), false)
	B.box(Vector3(0.12, 0.25, 4.2), Tex.whitewash(), Vector3(0.8, 3.0, 2.0))
	wall(Vector3(2.4, 0.12, 4.2), Vector3(1.95, 6.12, 2.0), Tex.ceiling(), false)
	_stairs()
	_window()
	_bulb_and_wiring()
	_wear()
	_paint_signs()

## ---------- лестница: вниз и вверх, промежуточная площадка, мусоропровод ----------
func _stairs() -> void:
	var step := Tex.surface("step", Color(0.45, 0.44, 0.41), 0.85, 0.0, 0.8)
	var rail := Tex.plain("rail", Color(0.18, 0.16, 0.14), 0.5, 0.4)
	var hand := Tex.plain("handrail", Color(0.25, 0.15, 0.08), 0.5)
	## полоса пола перед маршами
	B.box(Vector3(2.2, 0.1, 0.5), step, Vector3(1.9, -0.05, 0.35))
	## вверх (ближний марш) — до промежуточной площадки
	for i in 9:
		var h := 0.17 * (i + 1)
		B.box(Vector3(1.0, h, 0.3), step, Vector3(1.35, h / 2, 0.9 + 0.3 * i))
	B.box(Vector3(2.2, 0.15, 0.6), step, Vector3(1.95, 1.455, 3.75))
	## второй марш вверх, над маршем вниз — к 7 этажу
	for j in 9:
		var top := 1.53 + 0.17 * (j + 1)
		B.box(Vector3(1.05, 0.4, 0.3), step, Vector3(2.48, top - 0.2, 3.3 - 0.3 * j))
	## вниз — к промежуточной площадке ниже
	for i in 9:
		B.box(Vector3(1.05, 0.17, 0.3), step, Vector3(2.48, -0.085 - i * 0.17, 0.75 + i * 0.3))
	B.box(Vector3(2.2, 0.15, 0.9), step, Vector3(1.95, -1.6, 3.6))
	B.box(Vector3(2.2, 0.05, 4), Tex.plain("pit", Color(0, 0, 0), 1.0), Vector3(1.9, -3.2, 2.2))
	## перила: вдоль площадки и между маршами (наклонные поручни)
	B.box(Vector3(0.05, 0.05, 3.6), hand, Vector3(0.8, 0.95, 2.2))
	var z := 0.5
	while z < 4:
		B.box(Vector3(0.02, 0.9, 0.02), rail, Vector3(0.8, 0.48, z)); z += 0.25
	var ang := atan2(0.17, 0.3)
	var L := 2.7 / cos(ang)
	B.box(Vector3(0.05, 0.05, L), hand, Vector3(1.9, 0.95 + 0.765, 2.1), Vector3(-ang, 0, 0))
	B.box(Vector3(0.05, 0.05, L), hand, Vector3(1.95, 0.95 - 0.765, 2.1), Vector3(ang, 0, 0))
	B.box(Vector3(0.05, 0.05, L), hand, Vector3(1.95, 0.95 + 1.53 + 0.765, 2.1), Vector3(ang, 0, 0))
	for k in 10:
		var zz := 0.75 + k * 0.3
		B.box(Vector3(0.02, 0.9, 0.02), rail, Vector3(1.9, 0.17 * k + 0.45, zz))
		B.box(Vector3(0.02, 0.9, 0.02), rail, Vector3(1.95, -0.17 * k + 0.45, zz))
		B.box(Vector3(0.02, 0.9, 0.02), rail, Vector3(1.95, 3.06 - 0.17 * k + 0.45, zz))
	## на лестницу не пройти
	Geo.solid(solids, Vector3(2.3, 2, 3.6), Vector3(1.9, 1, 2.2))
	## мусоропровод в углу промежуточной площадки
	var chute := Tex.surface("chute", Color(0.3, 0.31, 0.3), 0.6, 0.4, 1.0)
	B.cyl(0.22, 0.22, 8.0, chute, Vector3(2.75, 2.0, 3.8), Vector3.ZERO, 16)
	B.box(Vector3(0.5, 0.35, 0.3), chute, Vector3(2.75, 2.3, 3.55), Vector3(0.25, 0, 0))
	B.box(Vector3(0.3, 0.05, 0.05), Tex.plain("handle", Color(0.55, 0.52, 0.48), 0.35, 0.8), Vector3(2.75, 2.45, 3.38))

## ---------- окно: рама, стекло, подоконник, батарея, цветы ----------
func _window() -> void:
	var frame := Tex.plain("winframe", Color(0.36, 0.29, 0.22), 0.7)
	var fx := -3.03
	for b in [[Vector3(0.08, 0.08, WIN.x + 0.1), Vector3(fx, WIN_Y + WIN.y / 2, WIN_Z)], [Vector3(0.08, 0.08, WIN.x + 0.1), Vector3(fx, WIN_Y - WIN.y / 2, WIN_Z)],
			[Vector3(0.08, WIN.y, 0.08), Vector3(fx, WIN_Y, WIN_Z - WIN.x / 2)], [Vector3(0.08, WIN.y, 0.08), Vector3(fx, WIN_Y, WIN_Z + WIN.x / 2)],
			[Vector3(0.06, WIN.y, 0.05), Vector3(fx, WIN_Y, WIN_Z)], [Vector3(0.06, 0.05, WIN.x), Vector3(fx, WIN_Y + 0.25, WIN_Z)],
			[Vector3(0.08, 0.08, WIN.x + 0.1), Vector3(-3.17, WIN_Y + WIN.y / 2, WIN_Z)], [Vector3(0.08, 0.08, WIN.x + 0.1), Vector3(-3.17, WIN_Y - WIN.y / 2, WIN_Z)],
			[Vector3(0.06, WIN.y, 0.05), Vector3(-3.17, WIN_Y, WIN_Z)]]:
		B.box(b[0], frame, b[1])
	## два стекла (двойная рама), грязные
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.5, 0.55, 0.55, 0.12); glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.08; glass.metallic = 0.3; glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	for gx in [fx, -3.17]:
		var g := MeshInstance3D.new(); var q := QuadMesh.new(); q.size = WIN; g.mesh = q; g.material_override = glass
		g.position = Vector3(gx, WIN_Y, WIN_Z); g.rotation.y = PI / 2; g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; gen.add_child(g)
	Geo.decal(gen, Vector2(WIN.x, 0.35), Color(0.25, 0.22, 0.16, 0.35), Vector3(fx + 0.01, WIN_Y - WIN.y / 2 + 0.17, WIN_Z), Vector3(0, PI / 2, 0), 5, 0.8)
	## подоконник, батарея
	B.box(Vector3(0.3, 0.05, WIN.x + 0.2), Tex.plain("sill", Color(0.78, 0.76, 0.7), 0.6), Vector3(-2.9, y_sill(), WIN_Z))
	var rad := Tex.plain("radiator", Color(0.55, 0.53, 0.46), 0.6)
	for i in 9:
		B.box(Vector3(0.08, 0.55, 0.06), rad, Vector3(-2.95, 0.5, WIN_Z - 0.5 + i * 0.12))
	B.cyl(0.02, 0.02, 1.2, rad, Vector3(-2.97, 0.86, WIN_Z), Vector3(PI / 2, 0, 0), 8)
	B.cyl(0.015, 0.015, 3.0, rad, Vector3(-2.97, 1.5, WIN_Z - 0.62), Vector3.ZERO, 8)
	## цветы в горшках и консервная банка-пепельница
	var pot := Tex.plain("pot", Color(0.55, 0.27, 0.15), 0.8)
	var leaf := Tex.plain("leaf", Color(0.14, 0.26, 0.1), 0.7)
	for pz in [WIN_Z - 0.45, WIN_Z + 0.42]:
		B.cyl(0.075, 0.055, 0.13, pot, Vector3(-2.92, y_sill() + 0.09, pz), Vector3.ZERO, 12)
		for k in 7:
			var a: float = TAU * k / 7.0 + pz
			B.box(Vector3(0.03, 0.16, 0.012), leaf, Vector3(-2.92 + cos(a) * 0.04, y_sill() + 0.24, pz + sin(a) * 0.04), Vector3(sin(a) * 0.5, a, cos(a) * 0.5))
	var tin := Tex.plain("tin", Color(0.6, 0.6, 0.58), 0.35, 0.8)
	B.cyl(0.04, 0.04, 0.09, tin, Vector3(-2.88, y_sill() + 0.07, WIN_Z), Vector3.ZERO, 12)
	var butt := Tex.plain("butt", Color(0.85, 0.75, 0.55), 0.8)
	for k in 6:
		B.cyl(0.004, 0.004, 0.04, butt, Vector3(-2.88 + R(-0.02, 0.02), y_sill() + 0.12, WIN_Z + R(-0.02, 0.02)), Vector3(R(0, 1), 0, R(-1, 1)), 5)
	## окурки на полу у окна
	for k in 9:
		B.cyl(0.004, 0.004, 0.035, butt, Vector3(R(-2.9, -2.2), 0.005, R(1.4, 3.1)), Vector3(PI / 2, R(0, TAU), 0), 5)

func y_sill() -> float: return WIN_Y - WIN.y / 2 - 0.03

## ---------- лампочка, проводка на изоляторах, выключатель ----------
func _bulb_and_wiring() -> void:
	var rail := Tex.plain("rail", Color(0.18, 0.16, 0.14), 0.5, 0.4)
	bulb = MeshInstance3D.new(); var sp := SphereMesh.new(); sp.radius = 0.06; sp.height = 0.12; bulb.mesh = sp
	bulb.material_override = Tex.glow("bulb", Color(1, 0.85, 0.6), 4.0); bulb.position = Vector3(-1.1, 2.62, 2); gen.add_child(bulb)
	B.box(Vector3(0.01, 0.32, 0.01), rail, Vector3(-1.1, 2.84, 2))
	B.cyl(0.035, 0.03, 0.06, Tex.plain("socket", Color(0.12, 0.1, 0.08), 0.5), Vector3(-1.1, 2.7, 2), Vector3.ZERO, 10)
	lamp = {"kind": "bulb", "pos": Vector3(-1.1, 2.5, 2), "grp": "L", "lvl": 1.0, "on": 1, "fl": 0.0, "delay": 0.0}
	## провод: от этажного щитка вверх, по потолку к лампе, ответвление к выключателю
	var w := Tex.plain("wire_old", Color(0.16, 0.12, 0.09), 0.6)
	var por := Tex.plain("porcelain", Color(0.88, 0.86, 0.8), 0.25)
	var run := func(pts: Array):
		for i in pts.size() - 1:
			var a: Vector3 = pts[i]; var b: Vector3 = pts[i + 1]
			var d := b - a
			B.add(Geo.tube(PackedVector3Array([a, a + d * 0.5, b]), 0.006, 5, 1), w, Transform3D())
			var n := int(d.length() / 0.45)
			for k in n:
				B.cyl(0.012, 0.012, 0.025, por, a + d * (float(k) + 0.5) / maxf(n, 1), Vector3.ZERO, 6)
	run.call([Vector3(-2.97, 2.25, 0.75), Vector3(-2.97, 2.96, 0.75), Vector3(-1.1, 2.96, 0.75), Vector3(-1.1, 2.96, 2.0)])
	run.call([Vector3(-1.1, 2.96, 0.75), Vector3(-0.82, 2.96, 0.13), Vector3(-0.82, 1.2, 0.13)])
	## выключатель (старый, круглый)
	B.cyl(0.04, 0.04, 0.03, por, Vector3(-0.82, 1.15, 0.11), Vector3(PI / 2, 0, 0), 14)
	B.box(Vector3(0.012, 0.03, 0.02), Tex.plain("knob", Color(0.1, 0.08, 0.06), 0.5), Vector3(-0.82, 1.15, 0.135))

## ---------- копоть, облезлая краска, грязь ----------
func _wear() -> void:
	## копоть от спичек на побелке потолка вокруг лампы
	for k in 14:
		Geo.decal(gen, Vector2.ONE * R(0.06, 0.18), Color(0.05, 0.04, 0.035, R(0.5, 0.85)), Vector3(-1.1 + R(-0.9, 0.9), 2.995, 2.0 + R(-1.1, 1.1)), Vector3(PI / 2, 0, 0), k, 0.6)
	## облупленная краска на стенах: светлая штукатурка из-под зелёной
	var plaster := Color(0.66, 0.63, 0.55)
	for p in [[Vector3(-3.0 + 0.001, 0.9, 3.5), Vector3(0, PI / 2, 0)], [Vector3(-2.99, 0.4, 0.3), Vector3(0, PI / 2, 0)], [Vector3(-0.2, 1.1, 4.0 - 0.001), Vector3(0, PI, 0)],
			[Vector3(-1.3, 0.6, 0.101), Vector3.ZERO], [Vector3(2.99, 1.0, 1.2), Vector3(0, -PI / 2, 0)]]:
		Geo.decal(gen, Vector2(R(0.25, 0.6), R(0.2, 0.45)), Color(plaster, 1.0), p[0], p[1], int(p[0].z * 10), 0.25)
	## потёки и грязь на побелке
	for p in [[Vector3(-2.995, 2.6, 3.2), Vector3(0, PI / 2, 0)], [Vector3(-1.9, 2.7, 3.995), Vector3(0, PI, 0)], [Vector3(-2.2, 2.4, 0.101), Vector3.ZERO]]:
		Geo.decal(gen, Vector2(R(0.4, 0.8), R(0.3, 0.6)), Color(0.42, 0.38, 0.3, 0.45), p[0], p[1], 3, 0.9)

## ---------- краска: номер этажа, надписи жильцов ----------
func _paint_signs() -> void:
	Geo.paint(gen, "6", 0.75, Color(0.82, 0.8, 0.72), Vector3(-1.37, 1.95, 3.99), Vector3(0, PI, 0), 0.38)
	Geo.paint(gen, "ЭТАЖ", 0.14, Color(0.82, 0.8, 0.72), Vector3(-1.37, 1.42, 3.99), Vector3(0, PI, 0), 0.4)
	var hand := PackedStringArray(["Segoe Print", "Comic Sans MS", "DejaVu Serif"])
	Geo.paint(gen, "ЦОЙ ЖИВ", 0.13, Color(0.08, 0.08, 0.1), Vector3(-2.99, 1.15, 3.45), Vector3(0, PI / 2, -0.08), 0.15, false, hand)
	Geo.paint(gen, "Лена + Витя", 0.07, Color(0.55, 0.12, 0.1), Vector3(-2.99, 0.85, 3.5), Vector3(0, PI / 2, 0.05), 0.1, false, hand)
	Geo.paint(gen, "кв. 23 — верните\nдрель!!", 0.06, Color(0.15, 0.17, 0.4), Vector3(0.45, 1.25, 3.99), Vector3(0, PI, 0.03), 0.05, false, hand)
	Geo.paint(gen, "→ 7", 0.12, Color(0.82, 0.8, 0.72), Vector3(2.99, 2.4, 1.0), Vector3(0, -PI / 2, 0), 0.4)
