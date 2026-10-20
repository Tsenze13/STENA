@tool
## Вид из окна подъезда: ночной город внизу и Стена — отвесная стена в небо, к которой пристроен дом.
## Её поверхность уходит вдаль вдоль улицы и вверх за облака; огни ярусов, красные авиаогни, ползущие лифты.
## Всё без тумана, со своей дымкой по расстоянию. Видно только с площадки (в коридоре скрывается).
class_name Outside
extends LevelPart

@export var buildings := 170:
	set(v): buildings = v; changed()
@export var ground_y := -17.0:
	set(v): ground_y = v; changed()

func _build() -> void:
	var gy := ground_y
	## Стена: плоскость z=0 от дома до горизонта и до неба
	var wm := Fx.wall_mat(1, 6.0, 12.0, 0.14, Color(0.045, 0.043, 0.042), Color(1.0, 0.75, 0.45) * 0.9, Color(0.7, 0.82, 1.0) * 0.8, Color(0.045, 0.036, 0.03), 0.0011, 0.12, 0.2)
	Fx.plane(gen, wm, Vector3(-1503.3, gy + 1800.0, -0.02), 3000.0, 3600.0, 1)
	## земля
	var gm := StandardMaterial3D.new(); gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; gm.albedo_color = Color(0.012, 0.011, 0.01)
	gm.set("disable_fog", true)
	var g := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(6000, 6000); g.mesh = pm; g.material_override = gm
	g.position = Vector3(-3000, gy, 3000); gen.add_child(g)
	## дома: панельные пятиэтажки, девятиэтажки, редкие высотки
	var hm := Fx.wall_mat(-1, 3.2, 2.8, 0.33, Color(0.05, 0.047, 0.043), Color(1.0, 0.78, 0.48), Color(0.55, 0.7, 1.0), Color(0.035, 0.028, 0.024), 0.0014, 0.42)
	var hb := Geo.Batch.new()
	var placed := 0; var tries := 0
	while placed < buildings and tries < buildings * 6:
		tries += 1
		var x := -R(40.0, 1700.0)
		var z := R(14.0, 1600.0)
		## улицы: сетка 120 м
		if fmod(absf(x), 120.0) < 22.0 or fmod(z, 120.0) < 22.0: continue
		var floors := 5 if rng.randf() < 0.45 else (9 if rng.randf() < 0.8 else 16)
		var h := floors * 2.8 + 1.0
		var along_x := rng.randf() < 0.5
		var l := R(40.0, 90.0)
		var size := Vector3(l, h, 12.0) if along_x else Vector3(12.0, h, l)
		hb.box(size, hm, Vector3(x, gy + h / 2, z))
		placed += 1
	hb.build(gen, false)
	## огни: фонари вдоль улиц, авиаогни на Стене, лифты ползут по Стене, звёзды
	var pts := []
	var sodium := Color(1.0, 0.55, 0.2) * 1.4
	var gx := -60.0
	while gx > -1800.0:
		var zz := 10.0
		while zz < 1700.0:
			pts.append([Vector3(gx + R(-2, 2), gy + 7.0, zz), sodium, 2.2])
			zz += 32.0
		gx -= 120.0
	var gz := 60.0
	while gz < 1700.0:
		var xx := -10.0
		while xx > -1800.0:
			pts.append([Vector3(xx, gy + 7.0, gz + R(-2, 2)), sodium, 2.2])
			xx -= 32.0
		gz += 120.0
	## фонари у подножия Стены — вдоль неё идёт дорога
	var wx := -8.0
	while wx > -2400.0:
		pts.append([Vector3(wx, gy + 8.0, 9.0), sodium, 2.5]); wx -= 25.0
	## авиаогни на Стене: на разной высоте, мигают
	for k in 90:
		pts.append([Vector3(-R(30, 2600), gy + R(40, 2400), 0.6), Color(3.0, 0.15, 0.08), R(4.0, 9.0), 1])
	## лифты: огни, которые медленно едут вверх по Стене
	for k in 8:
		pts.append([Vector3(-R(60, 1400), R(-1400, 1400), 0.8), Color(2.0, 1.8, 1.4), R(3.0, 5.0), 0, R(2.0, 6.0) * (1.0 if k % 3 else -1.0)])
	## звёзды — только над городом (над Стеной неба нет)
	for k in 420:
		var a := R(0.05, PI - 0.05); var e := R(0.08, 1.2)
		var dir := Vector3(-sin(a) * cos(e), sin(e), cos(a) * cos(e))
		if dir.z < 0.05: continue
		var b := R(0.4, 1.3)
		pts.append([dir * 2300.0, Color(b, b, b * 1.1), R(3.0, 7.0)])
	Fx.points(gen, pts, Vector3.ZERO, 0.0004)
