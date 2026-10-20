@tool
## Колодец Стены за проёмом в правой стене участка 7. Балкон с ограждением, а за ним — пустота на километры:
## стены колодца — технические галереи ярусов, стояки труб, гермоворота, сигнальные огни — уходят вверх и вниз в дымку, мосты, колонна с авиаогнями, толстые кабели,
## ползущие лифты. Тут видно, насколько Стена огромна. Огни включаются волной, когда игрок впервые
## подходит к проёму (switch_on), и гаснут волной в финале (switch_off).
class_name Shaft
extends LevelPart

const ZC := (World.SHAFT[0] + World.SHAFT[1]) / 2.0
const LZ := absf(World.SHAFT[1] - World.SHAFT[0])
const X0 := World.HW + 0.3       # наружная грань стены коридора

@export var width := 90.0:          # от стены коридора до противоположной стены
	set(v): width = v; changed()
@export var depth := 300.0:         # длина колодца вдоль коридора
	set(v): depth = v; changed()
@export_range(0.0, 1.0) var lit := 0.55:
	set(v): lit = v; changed()

var mats: Array[ShaderMaterial] = []
var reveal := 1e9
var target := 1e9
var speed := 400.0
var on := false

func _build() -> void:
	mats.clear()
	_balcony()
	var center := Vector3(X0, 3.0, ZC)
	## стены колодца
	var base := Color(0.05, 0.052, 0.056); var haze := Color(0.05, 0.056, 0.066)
	## внутренность Стены: галереи, трубы, гермоворота — никаких окон
	var lampc := Color(1.0, 0.6, 0.28)
	var near := Fx.infra_mat(0, 12.0, lit, base, lampc, haze, 0.0035)
	var far := Fx.infra_mat(0, 12.0, lit, base, lampc, haze, 0.0035)
	var sides := Fx.infra_mat(1, 12.0, lit * 0.8, base, lampc, haze, 0.0035)
	for m in [near, far, sides]:
		m.set_shader_parameter("center", center); mats.append(m)
	## колодец не выходит за фасад Стены (z < −1), иначе его стены торчали бы наружу в снег
	var za := ZC - depth / 2; var zb := minf(ZC + depth / 2, -1.0)
	var zc := (za + zb) / 2; var dz := zb - za
	Fx.plane(gen, near, Vector3(X0 + 0.01, World.CORR_H + 1500.0, zc), dz, 3000.0, 0)
	Fx.plane(gen, near, Vector3(X0 + 0.01, -0.35 - 1500.0, zc), dz, 3000.0, 0)
	Fx.plane(gen, far, Vector3(X0 + width, 0.0, zc), dz, 3200.0, 0)
	Fx.plane(gen, sides, Vector3(X0 + width / 2, 0.0, za), width, 3200.0, 1)
	Fx.plane(gen, sides, Vector3(X0 + width / 2, 0.0, zb), width, 3200.0, 1)
	## силуэты: колонна, мосты, кабели (обычный материал — в дымке они чёрные на фоне огней)
	var dark := Tex.dark_metal()
	var cx := X0 + width * 0.35; var cz := ZC - 22.0
	B.cyl(2.8, 2.8, 3000.0, dark, Vector3(cx, 0, cz), Vector3.ZERO, 20)
	B.cyl(1.4, 1.4, 3000.0, dark, Vector3(cx + 5.0, 0, cz + 3.0), Vector3.ZERO, 14)
	var pts := []
	var sodium := Color(1.0, 0.6, 0.25) * 1.6
	for br in [[-26.0, ZC - 25.0, true], [38.0, ZC + 21.0, true], [-130.0, ZC - 60.0, false], [210.0, ZC - 10.0, false], [-420.0, ZC + 40.0, false], [520.0, ZC + 70.0, false]]:
		var by: float = br[0]; var bz: float = br[1]
		if br[2]:
			B.box(Vector3(width, 0.6, 3.2), dark, Vector3(X0 + width / 2, by, bz))
			for s in [-1.0, 1.0]:
				B.box(Vector3(width, 0.12, 0.12), dark, Vector3(X0 + width / 2, by + 1.2, bz + s * 1.5))
				var x := X0 + 2.0
				while x < X0 + width:
					B.box(Vector3(0.12, 1.2, 0.12), dark, Vector3(x, by + 0.6, bz + s * 1.5)); x += 3.0
		var x2 := X0 + 3.0
		while x2 < X0 + width:
			pts.append([Vector3(x2, by + 1.6, bz), sodium, 1.4]); x2 += 6.0
	## толстые кабели через колодец
	for i in 4:
		var a := Vector3(X0 + 0.2, 13.0 + i * 1.6, ZC - 3.0 + i * 2.2)
		var b := Vector3(X0 + width - 0.2, 4.0 + i * 3.0, ZC - 14.0 + i * 7.0)
		B.add(Geo.tube(Geo.catenary(a, b, R(22.0, 34.0), 28), R(0.25, 0.5), 8, 2), Tex.cable(), Transform3D())
	## авиаогни на колонне, лифты, дежурные огни на стенах
	var y := -1500.0
	while y < 1500.0:
		pts.append([Vector3(cx - 3.0, y, cz), Color(3.0, 0.15, 0.08), 1.6, 1]); y += 45.0
	for k in 5:
		pts.append([Vector3(X0 + width - 0.6, R(-1400, 1400), minf(ZC + R(-depth / 2.5, depth / 2.5), -3.0)), Color(2.0, 1.8, 1.5), 3.0, 0, R(3.0, 7.0) * (1.0 if k % 2 else -1.0)])
	## сигнальные огни на галереях: красные мигающие и редкие белые прожекторы (не окна — дежурный свет объекта)
	for k in 260:
		var wall_k := rng.randi() % 3
		var yy := roundf(R(-1500, 1500) / 12.0) * 12.0 + 3.8
		var p := Vector3(X0 + width - 0.4, yy, R(za, zb)) if wall_k == 0 else (Vector3(X0 + 0.4, yy, R(za, zb)) if wall_k == 1 else Vector3(X0 + R(0, width), yy, (za + 0.5) if rng.randf() < 0.5 else (zb - 0.5)))
		if p.x < X0 + 1.0 and absf(p.z - ZC) < 8.0 and absf(p.y) < 12.0: continue
		if rng.randf() < 0.75:
			pts.append([p, Color(2.4, 0.12, 0.06), R(1.2, 2.0), 1])
		else:
			pts.append([p, Color(1.6, 1.5, 1.3), R(1.8, 3.0)])
	var pm := Fx.points(gen, pts, center, 0.003)
	mats.append(pm.material_override as ShaderMaterial)

func _balcony() -> void:
	var metal := Tex.metal(); var yel := Tex.yellow()
	var x0 := World.HW; var x1 := X0 + 1.6
	var gm: StandardMaterial3D = Tex.grate().duplicate()
	gm.uv1_scale = Vector3((x1 - x0) / 0.5, LZ / 0.5, 1)
	var p := MeshInstance3D.new(); var pl := PlaneMesh.new(); pl.size = Vector2(x1 - x0, LZ); p.mesh = pl; p.material_override = gm
	p.position = Vector3((x0 + x1) / 2, 0.0, ZC); gen.add_child(p)
	Geo.solid(solids, Vector3(x1 - x0, 0.2, LZ), Vector3((x0 + x1) / 2, -0.1, ZC))
	## рама настила и кронштейны под ним
	for z in [World.SHAFT[0] + 0.05, World.SHAFT[1] - 0.05, ZC]:
		B.box(Vector3(x1 - x0, 0.14, 0.08), metal, Vector3((x0 + x1) / 2, -0.08, z))
		B.box(Vector3(0.1, 2.2, 0.1), Tex.dark_metal(), Vector3(X0 + 0.75, -0.95, z), Vector3(0, 0, 0.62))
	B.box(Vector3(0.08, 0.14, LZ), metal, Vector3(x1, -0.08, ZC))
	## ограждение
	var n := 9
	for i in n:
		var z := World.SHAFT[0] - 0.1 - (LZ - 0.2) * i / (n - 1)
		B.box(Vector3(0.05, 1.1, 0.05), metal, Vector3(x1, 0.55, z))
	B.box(Vector3(0.06, 0.06, LZ), yel, Vector3(x1, 1.1, ZC))
	B.box(Vector3(0.04, 0.04, LZ), metal, Vector3(x1, 0.55, ZC))
	B.box(Vector3(0.02, 0.14, LZ), Tex.hazard(), Vector3(x1, 0.07, ZC))
	for z in [World.SHAFT[0] - 0.05, World.SHAFT[1] + 0.05]:
		B.box(Vector3(x1 - X0, 0.06, 0.06), yel, Vector3((X0 + x1) / 2, 1.1, z))
		B.box(Vector3(x1 - X0, 0.04, 0.04), metal, Vector3((X0 + x1) / 2, 0.55, z))
		Geo.solid(solids, Vector3(x1 - X0 + 0.1, 3.0, 0.1), Vector3((X0 + x1) / 2, 1.5, z))
	Geo.solid(solids, Vector3(0.1, 3.0, LZ), Vector3(x1 + 0.05, 1.5, ZC))
	Geo.plate(gen, [["ВНИМАНИЕ!", 30], ["НА ОГРАЖДЕНИЕ", 20], ["НЕ ОБЛОКАЧИВАТЬСЯ", 20]], Vector2(0.36, 0.2), Color(0.93, 0.92, 0.86), Color(0.72, 0.1, 0.08), Vector3(x1 - 0.04, 0.8, ZC + 1.2), Vector3(0, -PI / 2, 0))
	Geo.paint(gen, "КОЛОДЕЦ 7-К", 0.28, Color(0.85, 0.83, 0.76), Vector3(World.HW - 0.01, World.SHAFT_H + 0.55, ZC), Vector3(0, -PI / 2, 0), 0.35)

func _after_build() -> void:
	if not Engine.is_editor_hint():
		reveal = 0.0 if not on else reveal; target = reveal
	_apply()

func _apply() -> void:
	for m in mats:
		m.set_shader_parameter("reveal", reveal)

## огни включаются волной от балкона вглубь
func switch_on() -> void:
	if on: return
	on = true; reveal = 0.0; target = 3500.0; speed = 420.0

## гаснут волной издалека к балкону
func switch_off(sec := 6.0) -> void:
	target = 0.0; speed = maxf(reveal, 1.0) / maxf(sec, 0.1)

func _process(dt: float) -> void:
	if Engine.is_editor_hint() or reveal == target: return
	reveal = move_toward(reveal, target, speed * dt * (1.0 + reveal / 600.0))
	_apply()
