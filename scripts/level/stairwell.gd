@tool
## Шлюз — техническая лестничная клетка внутри Стены. Жилья нет: только этажи с запертыми служебными
## дверями, двери служебного лифта, лампы в решётчатых плафонах (часть мёртвые, часть мигают).
## Двухмаршевая лестница: с этажа марш вверх к промежуточной площадке, от неё второй марш на следующий этаж.
## По лестнице можно ходить (невидимые наклонные коллайдеры). Открыты этажи 1..open_floors, выше —
## лестница уходит в темноту (проход перекрыт решёткой, см. StairGate в сцене).
## Этаж 6 — на высоте y=0 (там электрощитовая и вход в коридор); этаж k — на высоте (k-6)·FH.
class_name Stairwell
extends LevelPart

const FH := 3.06            # высота этажа
const STEP := 0.17
const RUN := 0.3
## план клетки (вид сверху): площадка x < XL, марш А x XA0..XA1 (вверх к +z), марш Б x XB0..XB1 (вверх к −z)
const XL := 0.85            # край площадки (перила)
const XA0 := 0.9
const XA1 := 2.2
const XB0 := 2.4
const XB1 := 3.7
const XR := 3.9             # правая стена (центр)
const Z_ST := 1.4           # начало маршей: перед ними проход вдоль передней стены 1,3 м
const Z_MID := Z_ST + 9 * RUN   # промежуточная площадка
const BACK := Z_MID + 1.3   # задняя стена (за ней — снаружи, на 1 этаже вход из тамбура)

@export var floors_total := 14:
	set(v): floors_total = clampi(v, 6, 60); changed()
@export var open_floors := 6:
	set(v): open_floors = v; changed()
## название служебной двери на каждом этаже (по порядку с 1-го); 6-й — электрощитовая (отдельная сцена)
@export var door_names: PackedStringArray = PackedStringArray(["ВЕНТКАМЕРА", "НАСОСНАЯ", "КАБЕЛЬНАЯ 3-К", "АККУМУЛЯТОРНАЯ", "ТП-5", "", "ВЕНТКАМЕРА 7", "ЗАКРЫТО", "КАБЕЛЬНАЯ 9-К", "ТП-10", "АРХИВ", "ВЕНТКАМЕРА 12", "НАСОСНАЯ 13", "ТП-14"]):
	set(v): door_names = v; changed()
## лампа на этаже: on — горит, dead — мёртвая, flicker — мигает
@export var lamp_states: PackedStringArray = PackedStringArray(["on", "on", "dead", "on", "dead", "on", "dead", "dead", "dead", "dead", "dead", "dead", "dead", "dead"]):
	set(v): lamp_states = v; changed()

var lamps: Array = []

static func floor_y(k: int) -> float: return (k - 6) * FH

func _build() -> void:
	lamps = []
	for k in range(0, floors_total + 1):
		if k >= 1: _floor(k)
		_flights(k)
	var W := XR + 0.1 + 3.2
	var xc := (XR + 0.1 - 3.2) / 2
	## потолок над последним этажом
	var top := floor_y(floors_total) + FH
	B.box(Vector3(W, 0.2, BACK + 0.2), Tex.ceiling(), Vector3(xc, top + 0.1, BACK / 2))
	## сквозной кабель-канал и трубы в углу через все этажи
	var h := (floors_total + 1) * FH
	var y_mid := floor_y(0) + h / 2
	B.box(Vector3(0.12, h, 0.08), Tex.metal("conduit", Color(0.35, 0.36, 0.34)), Vector3(-2.97, y_mid, 0.25))
	B.cyl(0.05, 0.05, h, Tex.rust(), Vector3(XR - 0.25, y_mid, BACK - 0.15), Vector3.ZERO, 10)
	B.cyl(0.035, 0.035, h, Tex.metal("pipe", Color(0.35, 0.32, 0.28)), Vector3(XR - 0.4, y_mid, BACK - 0.1), Vector3.ZERO, 8)
	## подвал под первым этажом — темнота (с полом: провалиться в бесконечность нельзя)
	B.box(Vector3(W, 0.05, BACK), Tex.plain("pit", Color(0, 0, 0), 1.0), Vector3(xc, floor_y(0) - 0.2, BACK / 2))
	Geo.solid(solids, Vector3(W, 0.5, BACK), Vector3(xc, floor_y(0) - 0.45, BACK / 2))

## ---------- этаж: стены, пол, лампа, двери, номер ----------
func _floor(k: int) -> void:
	var y0 := floor_y(k)
	var band := Tex.paint_band(); var conc := Tex.concrete()
	var two := func(size_xz: Vector2, pos: Vector3, h0 := 0.0, h1 := FH):
		## стена: снизу крашеная полоса до 1,5 м, выше бетон
		var lo := clampf(1.5, h0, h1)
		if lo > h0: wall(Vector3(size_xz.x, lo - h0, size_xz.y), Vector3(pos.x, y0 + (h0 + lo) / 2, pos.z), band)
		if h1 > lo: wall(Vector3(size_xz.x, h1 - lo, size_xz.y), Vector3(pos.x, y0 + (lo + h1) / 2, pos.z), conc)
	var x1 := XR + 0.1                       # наружная грань правой стены
	## задняя стена; на 1 этаже — проём в тамбур (x −2.2..−1.0)
	if k == 1:
		two.call(Vector2(1.0, 0.2), Vector3(-2.7, 0, BACK + 0.1))
		two.call(Vector2(x1 + 1.0, 0.2), Vector3((x1 - 1.0) / 2, 0, BACK + 0.1))
		two.call(Vector2(1.2, 0.2), Vector3(-1.6, 0, BACK + 0.1), 2.1, FH)
	else:
		two.call(Vector2(x1 + 3.2, 0.2), Vector3((x1 - 3.2) / 2, 0, BACK + 0.1))
	## правая стена
	two.call(Vector2(0.2, BACK), Vector3(XR, 0, BACK / 2))
	## левая стена; на 1 этаже — проём в диспетчерскую (z 0.35..1.45)
	if k == 1:
		two.call(Vector2(0.2, 0.35), Vector3(-3.1, 0, 0.175))
		two.call(Vector2(0.2, BACK - 1.45), Vector3(-3.1, 0, (1.45 + BACK) / 2))
		two.call(Vector2(0.2, 1.1), Vector3(-3.1, 0, 0.9), 2.1, FH)
	else:
		two.call(Vector2(0.2, BACK), Vector3(-3.1, 0, BACK / 2))
	## передняя стена со служебной дверью (на 6 этаже середину строит дверь электрощитовой)
	if k != 6:
		two.call(Vector2(x1 + 3.2, 0.2), Vector3((x1 - 3.2) / 2, 0, 0))
		var nm: String = door_names[k - 1] if k - 1 < door_names.size() else ""
		if nm != "":
			var kinds := ["service", "hermetic", "cage"]
			var d := Props.door(kinds[(k * 7) % 3], nm, false)
			d.position = Vector3(-0.4, y0, 0.1); gen.add_child(d)
	else:
		two.call(Vector2(x1 - 3.2, 0.2), Vector3((x1 + 3.2) / 2, 0, 0))
	## пол площадки и прохода перед маршами (одна плита)
	wall(Vector3(XL + 3.0, 0.14, BACK), Vector3((XL - 3.0) / 2, y0 - 0.07, BACK / 2), Tex.floor_concrete())
	wall(Vector3(XR - 0.1 - XL, 0.14, Z_ST - 0.1), Vector3((XR - 0.1 + XL) / 2, y0 - 0.07, (Z_ST + 0.1) / 2), Tex.floor_concrete())
	## перила вдоль края площадки: вдоль марша А (наклонные) и вдоль промежуточной площадки этажом ниже
	var rail := Tex.plain("rail", Color(0.18, 0.16, 0.14), 0.5, 0.4)
	var hand := Tex.plain("handrail", Color(0.25, 0.15, 0.08), 0.5)
	B.box(Vector3(0.05, 0.05, BACK - Z_ST), hand, Vector3(XL, y0 + 0.95, (Z_ST + BACK) / 2))
	var z := Z_ST + 0.05
	while z < BACK:
		B.box(Vector3(0.02, 0.9, 0.02), rail, Vector3(XL, y0 + 0.48, z)); z += 0.25
	## коллайдер перил = там же, где видны перила (в высоту — до перил промежуточной площадки)
	Geo.solid(solids, Vector3(0.08, 2.7, BACK - Z_ST - 0.05), Vector3(XL - 0.02, y0 + 1.35, (Z_ST + 0.05 + BACK) / 2))
	## лифт на левой стене
	_lift(k, y0)
	## номер этажа краской
	Geo.paint(gen, str(k), 0.75, Color(0.82, 0.8, 0.72), Vector3(-0.3, y0 + 1.95, BACK - 0.01), Vector3(0, PI, 0), 0.38)
	Geo.paint(gen, "ЭТАЖ", 0.14, Color(0.82, 0.8, 0.72), Vector3(-0.3, y0 + 1.42, BACK - 0.01), Vector3(0, PI, 0), 0.4)
	## лампа в решётчатом плафоне
	var st: String = lamp_states[k - 1] if k - 1 < lamp_states.size() else "dead"
	var lp := Vector3(-1.1, y0 + FH - 0.3, BACK / 2)
	var cage := Tex.dark_metal()
	B.cyl(0.13, 0.13, 0.04, cage, lp + Vector3(0, 0.2, 0), Vector3.ZERO, 12)
	for a in 6:
		var t := TAU * a / 6.0
		B.box(Vector3(0.012, 0.22, 0.012), cage, lp + Vector3(cos(t) * 0.11, 0.08, sin(t) * 0.11))
	B.cyl(0.11, 0.11, 0.012, cage, lp + Vector3(0, -0.03, 0), Vector3.ZERO, 12)
	var mi := MeshInstance3D.new(); var sp := SphereMesh.new(); sp.radius = 0.05; sp.height = 0.1; mi.mesh = sp
	var gm := StandardMaterial3D.new(); gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; gm.albedo_color = Color(0.1, 0.08, 0.06)
	mi.material_override = gm; mi.position = lp + Vector3(0, 0.07, 0); gen.add_child(mi)
	lamps.append({"kind": "bulb", "pos": lp + Vector3(0, -0.15, 0), "grp": "L", "lvl": 1.0 if st != "dead" else 0.0, "on": 1, "fl": 0.0, "delay": 0.0,
		"mesh": mi, "dead": st == "dead", "flicker": st == "flicker", "floor": k})

## ---------- марши: с этажа k вверх к площадке и дальше на k+1 ----------
func _flights(k: int) -> void:
	var y0 := floor_y(k)
	var step := Tex.surface("step", Color(0.45, 0.44, 0.41), 0.85, 0.0, 0.8)
	var rail := Tex.plain("rail", Color(0.18, 0.16, 0.14), 0.5, 0.4)
	var hand := Tex.plain("handrail", Color(0.25, 0.15, 0.08), 0.5)
	var wa := XA1 - XA0; var xa := (XA0 + XA1) / 2
	var wb := XB1 - XB0; var xb := (XB0 + XB1) / 2
	var ang := atan2(STEP, RUN)
	## марш А: ступени-блоки до пола (без наложений — каждая ступень своя высота)
	for i in 9:
		var h := STEP * (i + 1)
		B.box(Vector3(wa, h, RUN), step, Vector3(xa, y0 + h / 2, Z_ST + RUN * (i + 0.5)))
	## промежуточная площадка — начинается ровно за последней ступенью
	var ym := y0 + 9 * STEP
	B.box(Vector3(XB1 - XA0, 0.2, BACK - Z_MID), step, Vector3((XA0 + XB1) / 2, ym - 0.1, (Z_MID + BACK) / 2))
	## марш Б: ступени и наклонная плита под ними
	for j in 9:
		var top := ym + STEP * (j + 1)
		B.box(Vector3(wb, 0.3, RUN), step, Vector3(xb, top - 0.15, Z_MID - RUN * (j + 0.5)))
	var L := 9 * RUN / cos(ang)
	B.box(Vector3(wb, 0.12, L), step, Vector3(xb, ym + 9 * STEP / 2 - 0.36, (Z_ST + Z_MID) / 2), Vector3(ang, 0, 0))
	## перила в зазоре между маршами: у марша А и у марша Б
	var xg := (XA1 + XB0) / 2
	B.box(Vector3(0.05, 0.05, L), hand, Vector3(xg - 0.04, y0 + 0.95 + 9 * STEP / 2, (Z_ST + Z_MID) / 2), Vector3(-ang, 0, 0))
	B.box(Vector3(0.05, 0.05, L), hand, Vector3(xg + 0.04, ym + 0.95 + 9 * STEP / 2, (Z_ST + Z_MID) / 2), Vector3(ang, 0, 0))
	for i in 10:
		var zz := Z_ST + i * RUN
		B.box(Vector3(0.02, 0.9, 0.02), rail, Vector3(xg - 0.04, y0 + STEP * i + 0.45, zz))
		B.box(Vector3(0.02, 0.9, 0.02), rail, Vector3(xg + 0.04, ym + 9 * STEP - STEP * i + 0.45, zz))
	## коллайдеры: наклонные «пандусы» по рёбрам ступеней и площадка (между маршами стен нет)
	if k >= 1 and k <= open_floors:
		var rl := 9 * RUN / cos(ang) + 0.3
		var na := Vector3(0, cos(ang), -sin(ang))
		## пандусы чуть шире маршей: щель между маршами закрыта, провалиться в неё нельзя
		var xgap := (XA1 + XB0) / 2
		Geo.solid(solids, Vector3(xgap - XA0, 0.1, rl), Vector3((XA0 + xgap) / 2, y0 + 9 * STEP / 2, (Z_ST + Z_MID) / 2) - na * 0.05, Vector3(-ang, 0, 0))
		Geo.solid(solids, Vector3(XB1 - XA0, 0.2, BACK - Z_MID), Vector3((XA0 + XB1) / 2, ym - 0.1, (Z_MID + BACK) / 2))
		var nb := Vector3(0, cos(ang), sin(ang))
		Geo.solid(solids, Vector3(XB1 - xgap, 0.1, rl), Vector3((xgap + XB1) / 2, ym + 9 * STEP / 2, (Z_ST + Z_MID) / 2) - nb * 0.05, Vector3(ang, 0, 0))

## ---------- двери служебного лифта на левой стене ----------
func _lift(k: int, y0: float) -> void:
	var zc := BACK - 1.1
	var frame := Tex.dark_metal()
	var leaf := Tex.metal("lift_leaf", Color(0.36, 0.38, 0.37))
	B.box(Vector3(0.12, 2.3, 0.12), frame, Vector3(-2.96, y0 + 1.15, zc - 0.62))
	B.box(Vector3(0.12, 2.3, 0.12), frame, Vector3(-2.96, y0 + 1.15, zc + 0.62))
	B.box(Vector3(0.12, 0.14, 1.36), frame, Vector3(-2.96, y0 + 2.3, zc))
	for s in [-1.0, 1.0]:
		B.box(Vector3(0.04, 2.2, 0.55), leaf, Vector3(-2.97, y0 + 1.1, zc + s * 0.28))
	B.box(Vector3(0.05, 2.2, 0.012), Tex.plain("seam", Color(0.08, 0.08, 0.08), 0.9), Vector3(-2.95, y0 + 1.1, zc))
	B.box(Vector3(0.02, 0.12, 1.2), Tex.hazard(), Vector3(-2.99, y0 + 0.06, zc))
	## пульт вызова (мёртвый) и надпись
	B.box(Vector3(0.04, 0.22, 0.12), Tex.metal("lift_btn", Color(0.3, 0.3, 0.29)), Vector3(-2.98, y0 + 1.25, zc + 0.85))
	B.cyl(0.02, 0.02, 0.02, Tex.plain("btn_dead", Color(0.25, 0.1, 0.08), 0.4), Vector3(-2.955, y0 + 1.28, zc + 0.85), Vector3(0, 0, PI / 2), 10)
	Geo.paint(gen, "ЛИФТ СЛУЖЕБНЫЙ Л-2", 0.09, Color(0.82, 0.8, 0.72), Vector3(-2.99, y0 + 2.55, zc), Vector3(0, PI / 2, 0), 0.35)
	Geo.act_zone(gen, Vector3(0.3, 2.2, 1.3), Vector3(-2.9, y0 + 1.1, zc), "lift", "Л-2")
