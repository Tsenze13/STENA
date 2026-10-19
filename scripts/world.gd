## Сцена главы 0: лестничная площадка 6 этажа, дверь «Электрощитовая», высокий служебный коридор Стены.
## Оси как в браузерной версии: коридор уходит в -Z, пол на y=0, площадка z∈[0,4], дверь на z=0,
## переборка с решёткой ГД-6 на z=GATE_Z. Коридор 4 м шириной и 9 м высотой, слева мостки на 4,2 м.
class_name World
extends Node3D

const CORR_W := 4.0
const CORR_H := 9.0
const HW := 2.0
const LEN := 2000.0
const GATE_Z := -20.0
const NICHE := [-6.0, -10.0]
const NICHE_H := 3.2
const DET := 260.0           # дальше этого мелкие детали не строим: туман всё равно скрывает
const CW_Y := 4.2            # высота мостков

var solids := StaticBody3D.new()
var B := Geo.Batch.new()
var lamps: Array = []        # {kind, pos, grp, lvl, on, fl, delay, dead, inst}
var door := {}               # pivot, open, target, shape
var gate := {}               # node, open, moving, lift, shape
var beacon := {}
var panel: Props.PanelModel
var console := {}
var term_viewport: SubViewport
var sign_label: Label3D
var bulb: MeshInstance3D
var rng := RandomNumberGenerator.new()

func R(a: float, b: float) -> float: return rng.randf_range(a, b)

func build() -> void:
	rng.seed = 1337
	add_child(solids)
	_landing()
	_corridor()
	_catwalk()
	_bulkhead()
	_niche()
	_doors()
	_cables()
	_clutter()
	_lamps()
	B.build(self)

## стена: меш + коллайдер
func wall(size: Vector3, pos: Vector3, mat: Material, collide := true) -> void:
	B.box(size, mat, pos)
	if collide:
		Geo.solid(solids, size, pos)

## ================= ЛЕСТНИЧНАЯ ПЛОЩАДКА =================
func _landing() -> void:
	var white := Tex.whitewash(); var green := Tex.green_paint()
	## стены: снизу масляная краска 1,5 м, выше побелка
	for w in [[Vector3(6.4, 1, 0.2), Vector3(0, 0, 4.1)], [Vector3(0.2, 1, 4), Vector3(-3.1, 0, 2)], [Vector3(0.2, 1, 4), Vector3(3.1, 0, 2)]]:
		var s: Vector3 = w[0]; var p: Vector3 = w[1]
		wall(Vector3(s.x, 1.5, s.z), p + Vector3(0, 0.75, 0), green)
		wall(Vector3(s.x, 1.5, s.z), p + Vector3(0, 2.25, 0), white)
	## пол — плитка «шахматкой»
	var img := Image.create(256, 256, false, Image.FORMAT_RGB8)
	for y in 256:
		for x in 256:
			var c := Color(0.47, 0.28, 0.23) if ((x / 32 + y / 32) % 2 == 0) else Color(0.59, 0.55, 0.47)
			if x % 32 < 1 or y % 32 < 1: c = Color(0.15, 0.13, 0.12)
			c = c.darkened(randf() * 0.08)
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	var tm := StandardMaterial3D.new(); tm.albedo_texture = ImageTexture.create_from_image(img); tm.roughness = 0.55
	tm.uv1_triplanar = true; tm.uv1_world_triplanar = true; tm.uv1_scale = Vector3.ONE * 0.6
	wall(Vector3(3.8, 0.1, 4), Vector3(-1.1, -0.05, 2), tm)
	wall(Vector3(6, 0.1, 4), Vector3(0, 3.05, 2), Tex.ceiling(), false)
	## лестница вниз (справа) и перила
	var step := Tex.surface("step", Color(0.45, 0.44, 0.41), 0.85, 0.0, 0.8)
	for i in 12:
		B.box(Vector3(2.2, 0.17, 0.3), step, Vector3(1.9, -0.085 - i * 0.17, 0.75 + i * 0.3))
	B.box(Vector3(2.2, 0.1, 0.5), step, Vector3(1.9, -0.05, 0.35))
	var rail := Tex.plain("rail", Color(0.18, 0.16, 0.14), 0.5, 0.4)
	B.box(Vector3(0.05, 0.05, 3.6), Tex.plain("handrail", Color(0.25, 0.15, 0.08), 0.5), Vector3(0.8, 0.95, 2.2))
	var z := 0.5
	while z < 4:
		B.box(Vector3(0.02, 0.9, 0.02), rail, Vector3(0.8, 0.48, z)); z += 0.25
	Geo.solid(solids, Vector3(2.3, 2, 3.6), Vector3(1.9, 1, 2.2))
	B.box(Vector3(2.2, 0.05, 4), Tex.plain("pit", Color(0, 0, 0), 1.0), Vector3(1.9, -2.2, 2.2))
	## окно с ночным городом
	var night := Image.create(128, 128, false, Image.FORMAT_RGB8)
	for y in 128:
		for x in 128:
			night.set_pixel(x, y, Color(0.02, 0.03, 0.05).lerp(Color(0.1, 0.08, 0.06), y / 128.0))
	for i in 60:
		night.set_pixel(randi() % 128, 70 + randi() % 58, Color(1, 0.75, 0.45) if randf() < 0.7 else Color(0.8, 0.85, 1))
	var nm := StandardMaterial3D.new(); nm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; nm.albedo_texture = ImageTexture.create_from_image(night)
	nm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	var win := MeshInstance3D.new(); var q := QuadMesh.new(); q.size = Vector2(1.4, 1.3); win.mesh = q; win.material_override = nm
	win.position = Vector3(-2.99, 1.75, 2.2); win.rotation.y = PI / 2; add_child(win)
	var frame := Tex.plain("winframe", Color(0.36, 0.29, 0.22), 0.7)
	for b in [[Vector3(0.08, 0.08, 1.5), Vector3(-2.96, 2.42, 2.2)], [Vector3(0.08, 0.08, 1.5), Vector3(-2.96, 1.08, 2.2)], [Vector3(0.08, 1.4, 0.08), Vector3(-2.96, 1.75, 1.47)], [Vector3(0.08, 1.4, 0.08), Vector3(-2.96, 1.75, 2.93)], [Vector3(0.06, 1.3, 0.05), Vector3(-2.96, 1.75, 2.2)], [Vector3(0.22, 0.05, 1.6), Vector3(-2.9, 1.05, 2.2)]]:
		B.box(b[0], frame, b[1])
	var rad := Tex.plain("radiator", Color(0.55, 0.53, 0.46), 0.6)
	for i in 9:
		B.box(Vector3(0.08, 0.55, 0.06), rad, Vector3(-2.95, 0.5, 1.7 + i * 0.12))
	Geo.label(self, "6", 360, Color(0.88, 0.86, 0.78, 0.8), Vector3(-1.6, 1.9, 3.99), Vector3(0, PI, 0), 0.0028)
	## лампочка на проводе
	bulb = MeshInstance3D.new(); var sp := SphereMesh.new(); sp.radius = 0.06; sp.height = 0.12; bulb.mesh = sp
	bulb.material_override = Tex.glow("bulb", Color(1, 0.85, 0.6), 4.0); bulb.position = Vector3(-1.1, 2.62, 2); add_child(bulb)
	B.box(Vector3(0.01, 0.32, 0.01), rail, Vector3(-1.1, 2.84, 2))
	lamps.append({"kind": "bulb", "pos": Vector3(-1.1, 2.5, 2), "grp": "L", "lvl": 1.0, "on": 1, "fl": 0.0, "delay": 0.0})

	## ================= СТЕНА С ДВЕРЬЮ (z=0) =================
	wall(Vector3(2.6, 1.5, 0.2), Vector3(-1.9, 0.75, 0), green); wall(Vector3(2.6, 1.5, 0.2), Vector3(-1.9, 2.25, 0), white)
	wall(Vector3(2.6, 1.5, 0.2), Vector3(1.9, 0.75, 0), green); wall(Vector3(2.6, 1.5, 0.2), Vector3(1.9, 2.25, 0), white)
	wall(Vector3(1.2, 0.9, 0.2), Vector3(0, 2.55, 0), white)
	var jamb := Tex.plain("jamb", Color(0.23, 0.17, 0.13), 0.7)
	B.box(Vector3(0.08, 2.15, 0.26), jamb, Vector3(-0.64, 1.07, 0)); B.box(Vector3(0.08, 2.15, 0.26), jamb, Vector3(0.64, 1.07, 0)); B.box(Vector3(1.36, 0.08, 0.26), jamb, Vector3(0, 2.14, 0))
	## дверь на петлях (слева), открывается внутрь
	var pivot := Node3D.new(); pivot.position = Vector3(-0.6, 0, 0); add_child(pivot)
	Geo.box_node(pivot, Vector3(1.2, 2.1, 0.06), Tex.metal("door", Color(0.35, 0.23, 0.17)), Vector3(0.6, 1.05, 0))
	Geo.box_node(pivot, Vector3(0.34, 0.4, 0.005), Tex.plain("warnplate", Color(0.92, 0.76, 0.1), 0.6), Vector3(0.6, 1.45, 0.033))
	Geo.label(pivot, "ОСТОРОЖНО!\nНАПРЯЖЕНИЕ", 32, Color(0.05, 0.05, 0.05), Vector3(0.6, 1.36, 0.037), Vector3.ZERO, 0.0013)
	Geo.label(pivot, "⚡", 120, Color(0.05, 0.05, 0.05), Vector3(0.6, 1.53, 0.037), Vector3.ZERO, 0.0015)
	Geo.box_node(pivot, Vector3(0.12, 0.03, 0.05), Tex.plain("handle", Color(0.55, 0.52, 0.48), 0.35, 0.8), Vector3(1.05, 1.0, 0.06))
	var dz := Geo.act_zone(pivot, Vector3(1.2, 2.1, 0.2), Vector3(0.6, 1.05, 0), "door")
	door = {"pivot": pivot, "open": 0.0, "target": 0.0, "shape": Geo.solid(solids, Vector3(1.2, 2.1, 0.1), Vector3(0, 1.05, 0)), "zone": dz}
	## табличка «Электрощитовая»
	B.box(Vector3(1.3, 0.33, 0.08), Tex.plain("signbox", Color(0.08, 0.08, 0.08), 0.6), Vector3(0, 2.55, 0.15))
	sign_label = Geo.label(self, "ЭЛЕКТРОЩИТОВАЯ", 64, Color(4, 0.5, 0.35), Vector3(0, 2.55, 0.195), Vector3.ZERO, 0.0032, false)
	Geo.act_zone(self, Vector3(1.3, 0.33, 0.1), Vector3(0, 2.55, 0.16), "sign")

## ================= КОРИДОР =================
func _corridor() -> void:
	var conc := Tex.concrete(); var band := Tex.paint_band(); var yel := Tex.yellow()
	## стена с дверью со стороны коридора поднимается до потолка
	wall(Vector3(CORR_W + 0.6, CORR_H - 3, 0.2), Vector3(0, 3 + (CORR_H - 3) / 2, -0.1), conc)
	## продольные стены: бетон, снизу крашеная полоса 1,5 м и жёлтая линия
	var side := func(sx: float, z0: float, z1: float, y0: float):
		var L: float = abs(z1 - z0); var zc: float = (z0 + z1) / 2
		var x: float = sx * (HW + 0.15)
		wall(Vector3(0.3, CORR_H - y0, L), Vector3(x, y0 + (CORR_H - y0) / 2, zc), conc, y0 == 0)
		if y0 == 0:
			B.box(Vector3(0.02, 1.5, L), band, Vector3(sx * (HW - 0.01), 0.75, zc))
			B.box(Vector3(0.02, 0.07, L), yel, Vector3(sx * (HW - 0.01), 1.52, zc))
			## швы бетонных панелей через каждые 1,5 м
			for y in [3.0, 4.5, 6.0, 7.5]:
				B.box(Vector3(0.015, 0.03, L), Tex.plain("seam", Color(0.12, 0.12, 0.11), 0.9), Vector3(sx * (HW - 0.005), y, zc))
	side.call(-1.0, 0.0, -LEN, 0.0)
	side.call(1.0, 0.0, NICHE[0], 0.0)
	side.call(1.0, NICHE[1], -LEN, 0.0)
	side.call(1.0, NICHE[0], NICHE[1], NICHE_H)
	## пол и потолок
	wall(Vector3(CORR_W, 0.2, LEN), Vector3(0, -0.1, -LEN / 2), Tex.floor_concrete())
	for sx in [-1.0, 1.0]:
		B.box(Vector3(0.1, 0.004, LEN), yel, Vector3(sx * (HW - 0.4), 0.002, -LEN / 2))
	wall(Vector3(CORR_W + 0.6, 0.3, LEN), Vector3(0, CORR_H + 0.15, -LEN / 2), Tex.ceiling(), false)
	wall(Vector3(CORR_W + 1, CORR_H, 0.3), Vector3(0, CORR_H / 2, -LEN - 0.15), Tex.plain("end", Color(0.05, 0.05, 0.05)))

	## пилястры и потолочные балки каждые 6 м (MultiMesh — их сотни)
	var n := int(LEN / 6)
	var pil := BoxMesh.new(); pil.size = Vector3(0.4, CORR_H, 0.3)
	var bm := BoxMesh.new(); bm.size = Vector3(CORR_W, 0.5, 0.3)
	var pmat := Tex.surface("pilaster", Color(0.37, 0.38, 0.35), 0.85, 0.0, 0.5)
	var xfs_l := []; var xfs_r := []; var xfs_b := []
	for i in n:
		var z := -6.0 * (i + 1)
		xfs_l.append(Transform3D(Basis(), Vector3(-HW + 0.15, CORR_H / 2, z)))
		if not (z <= NICHE[0] and z >= NICHE[1]):
			xfs_r.append(Transform3D(Basis(), Vector3(HW - 0.15, CORR_H / 2, z)))
		xfs_b.append(Transform3D(Basis(), Vector3(0, CORR_H - 0.25, z)))
		if -z < DET:
			Geo.solid(solids, Vector3(0.35, 3, 0.3), Vector3(-HW + 0.175, 1.5, z))
			if not (z <= NICHE[0] and z >= NICHE[1]):
				Geo.solid(solids, Vector3(0.35, 3, 0.3), Vector3(HW - 0.175, 1.5, z))
	for item in [[pil, xfs_l], [pil, xfs_r], [bm, xfs_b]]:
		_multi(item[0], pmat, item[1])

	## трубы, короба и кабель-каналы вдоль всего коридора
	var pipe := Tex.metal("pipe", Color(0.35, 0.32, 0.28))
	for p in [[0.13, HW - 0.25, 7.7, pipe], [0.08, HW - 0.55, 8.05, pipe], [0.08, HW - 0.25, 8.3, Tex.rust()], [0.11, -HW + 0.3, 7.3, pipe], [0.05, -HW + 0.55, 7.55, Tex.rust()]]:
		B.cyl(p[0], p[0], LEN, p[3], Vector3(p[1], p[2], -LEN / 2), Vector3(PI / 2, 0, 0), 12)
	B.box(Vector3(0.9, 0.7, LEN), Tex.metal("duct", Color(0.42, 0.44, 0.42)), Vector3(HW - 0.6, 6.2, -LEN / 2))
	var tray := Tex.metal()
	for t in [[-HW + 0.2, 5.9], [-HW + 0.2, 6.6], [HW - 0.2, 3.9], [HW - 0.2, 4.6]]:
		B.box(Vector3(0.36, 0.05, LEN), tray, Vector3(t[0], t[1], -LEN / 2))
	for c in [[-HW + 0.12, 5.95], [-HW + 0.2, 5.96], [-HW + 0.28, 5.95], [HW - 0.15, 3.95], [HW - 0.25, 3.96]]:
		B.cyl(0.025, 0.025, LEN, Tex.cable(), Vector3(c[0], c[1], -LEN / 2), Vector3(PI / 2, 0, 0), 6)
	var z := -1.5
	while z > -DET:
		B.box(Vector3(1.0, 0.8, 0.06), tray, Vector3(HW - 0.6, 6.2, z))
		B.box(Vector3(0.06, 0.5, 0.1), Tex.dark_metal(), Vector3(HW - 0.06, 7.95, z))
		z -= 3.0
	## трафаретные отметки расстояния
	var d := 50
	while d <= 500:
		Geo.label(self, ("6-" if d <= -GATE_Z else "7-") + "%04d" % d, 110, Color(0.88, 0.86, 0.78, 0.6), Vector3(-HW + 0.01, 2.3, -d - 3), Vector3(0, PI / 2, 0), 0.006)
		d += 50
	Geo.label(self, "6", 600, Color(0.88, 0.86, 0.78, 0.5), Vector3(-HW + 0.01, 6.8, -3), Vector3(0, PI / 2, 0), 0.004)

func _multi(mesh: Mesh, mat: Material, xfs: Array) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	add_child(mmi)
	return mmi

## ================= МОСТКИ на 4,2 м слева =================
func _catwalk() -> void:
	var cw_x := -HW + 1.15
	var metal := Tex.metal()
	var walk := func(z0: float, z1: float):
		var L: float = abs(z1 - z0); var zc: float = (z0 + z1) / 2
		var gm: StandardMaterial3D = Tex.grate().duplicate()
		gm.uv1_scale = Vector3(1.15 / 0.5, L / 0.5, 1)
		var p := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(1.15, L); p.mesh = pm; p.material_override = gm
		p.position = Vector3(-HW + 0.575, CW_Y, zc); add_child(p)
		B.box(Vector3(0.06, 0.16, L), metal, Vector3(cw_x, CW_Y - 0.06, zc))
		B.box(Vector3(0.04, 0.04, L), Tex.yellow(), Vector3(cw_x, CW_Y + 1.05, zc))
		B.box(Vector3(0.03, 0.03, L), metal, Vector3(cw_x, CW_Y + 0.55, zc))
		var z: float = z0
		while z >= z1:
			B.box(Vector3(0.04, 1.05, 0.04), metal, Vector3(cw_x, CW_Y + 0.52, z)); z -= 1.5
	walk.call(-0.5, GATE_Z + 0.4)
	walk.call(GATE_Z - 0.4, -DET)
	var z := -6.0
	while z > -DET:
		B.box(Vector3(0.08, 1.45, 0.08), Tex.dark_metal(), Vector3(-HW + 0.6, CW_Y - 0.55, z), Vector3(0, 0, -0.85)); z -= 6.0
	## стремянки на мостки
	for lz in [-13.2, -61.2]:
		for ddz in [-0.25, 0.25]:
			B.box(Vector3(0.05, CW_Y + 1.1, 0.05), metal, Vector3(-HW + 0.14, (CW_Y + 1.1) / 2, lz + ddz))
		var y := 0.3
		while y < CW_Y + 1:
			B.box(Vector3(0.04, 0.03, 0.5), metal, Vector3(-HW + 0.14, y, lz)); y += 0.3

## ================= ПЕРЕБОРКА ГД-6 =================
func _bulkhead() -> void:
	var GO := 4.2; var GH := 1.6
	var bulk := Tex.surface("bulk", Color(0.52, 0.52, 0.49), 0.9, 0.0, 0.4)
	wall(Vector3(HW - GH, CORR_H, 0.7), Vector3(-(HW + GH) / 2, CORR_H / 2, GATE_Z), bulk)
	wall(Vector3(HW - GH, CORR_H, 0.7), Vector3((HW + GH) / 2, CORR_H / 2, GATE_Z), bulk)
	wall(Vector3(GH * 2, CORR_H - GO, 0.7), Vector3(0, GO + (CORR_H - GO) / 2, GATE_Z), bulk)
	for s in [1.0, -1.0]:
		B.box(Vector3(0.16, GO, 0.01), Tex.hazard(), Vector3(s * (GH + 0.08), GO / 2, GATE_Z + 0.355))
	B.box(Vector3(GH * 2 + 0.32, 0.16, 0.01), Tex.hazard(), Vector3(0, GO + 0.08, GATE_Z + 0.355))
	var g := Node3D.new(); g.position = Vector3(0, 0, GATE_Z); add_child(g)
	var gm := Tex.plain("gate", Color(0.22, 0.22, 0.2), 0.45, 0.6)
	var x := -GH + 0.1
	while x < GH - 0.05:
		Geo.cyl_node(g, 0.024, 0.024, GO - 0.05, gm, Vector3(x, GO / 2, 0), Vector3.ZERO, 6); x += 0.15
	for y in [0.08, 1.4, 2.8, GO - 0.1]:
		Geo.box_node(g, Vector3(GH * 2 - 0.04, 0.08, 0.08), gm, Vector3(0, y, 0))
	Geo.act_zone(g, Vector3(GH * 2, GO, 0.2), Vector3(0, GO / 2, 0), "gate")
	gate = {"node": g, "open": 0.0, "moving": false, "lift": GO + 0.1, "shape": Geo.solid(solids, Vector3(GH * 2, GO, 0.2), Vector3(0, GO / 2, GATE_Z))}
	Geo.label(self, "ГД-6", 120, Color(0.79, 0.64, 0.15), Vector3(0, GO + 0.5, GATE_Z + 0.36), Vector3.ZERO, 0.004)
	## проблесковый маячок: крутится, пока решётка движется
	var bc := Node3D.new(); bc.position = Vector3(GH - 0.3, GO + 0.55, GATE_Z + 0.45); add_child(bc)
	Geo.box_node(bc, Vector3(0.16, 0.06, 0.16), Tex.dark_metal(), Vector3(0, -0.08, 0))
	var lamp := Geo.cyl_node(bc, 0.07, 0.08, 0.14, Tex.plain("beacon_off", Color(0.23, 0.13, 0.02), 0.3), Vector3.ZERO, Vector3.ZERO, 12)
	var sl := SpotLight3D.new(); sl.light_color = Color(1, 0.6, 0.12); sl.spot_range = 14; sl.spot_angle = 30; sl.light_energy = 0
	sl.rotation = Vector3(-0.35, PI / 2, 0); bc.add_child(sl)
	beacon = {"node": bc, "lamp": lamp, "light": sl}
	## табличка участка
	var plq := Node3D.new(); plq.position = Vector3(HW - 0.01, 1.6, GATE_Z + 2.2); plq.rotation.y = -PI / 2; add_child(plq)
	Geo.box_node(plq, Vector3(0.6, 0.42, 0.02), Tex.plain("bronze", Color(0.55, 0.45, 0.28), 0.4, 0.6))
	Geo.label(plq, "УЧАСТОК 6\nВВЕДЁН В ЭКСПЛУАТАЦИЮ\n1987", 48, Color(0.12, 0.09, 0.05), Vector3(0, 0, 0.012), Vector3.ZERO, 0.0017)
	Geo.act_zone(plq, Vector3(0.6, 0.42, 0.1), Vector3.ZERO, "plaque")
	Geo.label(self, "7", 600, Color(0.88, 0.86, 0.78, 0.5), Vector3(0, 6.6, GATE_Z - 0.36), Vector3(0, PI, 0), 0.004)
	## служебная дверь в переборке на уровне мостков
	var d := Props.door("service", "6-К1", false); d.position = Vector3(-HW + 0.6, CW_Y, GATE_Z + 0.36); add_child(d)

## ================= НИША: щиток, пульт, записка =================
func _niche() -> void:
	var nz0: float = NICHE[0]; var nz1: float = NICHE[1]; var nx := HW + 1.8; var nzc := (nz0 + nz1) / 2
	var conc := Tex.concrete(); var band := Tex.paint_band()
	wall(Vector3(0.3, NICHE_H, 4.3), Vector3(nx + 0.15, NICHE_H / 2, nzc), conc)
	wall(Vector3(1.8, NICHE_H, 0.3), Vector3(HW + 0.9, NICHE_H / 2, nz0 + 0.15), conc)
	wall(Vector3(1.8, NICHE_H, 0.3), Vector3(HW + 0.9, NICHE_H / 2, nz1 - 0.15), conc)
	B.box(Vector3(0.02, 1.5, 4.0), band, Vector3(nx - 0.01, 0.75, nzc))
	wall(Vector3(1.8, 0.2, 4.3), Vector3(HW + 0.9, -0.1, nzc), Tex.floor_concrete())
	wall(Vector3(1.8, 0.2, 4.3), Vector3(HW + 0.9, NICHE_H + 0.1, nzc), Tex.ceiling(), false)
	## щиток
	panel = Props.PanelModel.new()
	panel.node.position = Vector3(nx - 0.1, 1.45, -7.1); panel.node.rotation.y = -PI / 2; add_child(panel.node)
	Geo.act_zone(panel.node, Vector3(0.8, 1.0, 0.5), Vector3(0, 0, 0.1), "panel")
	## пульт с терминалом: экран — живой SubViewport
	term_viewport = SubViewport.new(); term_viewport.size = Vector2i(320, 240); term_viewport.transparent_bg = false
	term_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(term_viewport)
	console = Props.console(term_viewport.get_texture())
	var cn: Node3D = console.node
	cn.position = Vector3(nx - 0.36, 0, -8.85); cn.rotation.y = -PI / 2; add_child(cn)
	Geo.act_zone(cn, Vector3(1.3, 0.8, 0.8), Vector3(0, 1.2, 0), "terminal")
	Geo.solid(solids, Vector3(0.75, 1.2, 1.5), Vector3(nx - 0.37, 0.6, -8.85))
	## записка
	var note := Node3D.new(); note.position = Vector3(nx - 1.15, 1.5, nz1 + 0.005); add_child(note)
	Geo.box_node(note, Vector3(0.21, 0.27, 0.004), Tex.plain("paper", Color(0.85, 0.82, 0.72), 0.95))
	Geo.label(note, "Смена 3\n— решётка —\n1987?..", 30, Color(0.15, 0.15, 0.3), Vector3(0, 0.02, 0.004), Vector3.ZERO, 0.0018)
	Geo.box_node(note, Vector3(0.02, 0.02, 0.01), Tex.plain("pin", Color(0.7, 0.13, 0.13)), Vector3(0, 0.12, 0.005))
	Geo.act_zone(note, Vector3(0.3, 0.35, 0.1), Vector3.ZERO, "note")

## ================= ДВЕРИ =================
func _doors() -> void:
	var list := [
		[-1, -9, "service", 0], [1, -15, "hermetic", 0], [-1, -15, "service", 1],
		[-1, -27, "hermetic", 0], [1, -27, "cage", 0], [-1, -33, "service", 1], [1, -39, "service", 0], [-1, -45, "cage", 0],
		[1, -51, "hermetic", 0], [-1, -57, "service", 0], [-1, -69, "service", 1], [1, -63, "service", 0], [-1, -75, "hermetic", 0],
		[1, -81, "cage", 0], [-1, -93, "service", 0], [1, -99, "hermetic", 0], [-1, -105, "service", 1], [1, -117, "service", 0],
		[-1, -129, "cage", 0], [1, -141, "hermetic", 0], [-1, -153, "service", 0], [1, -171, "service", 0], [-1, -189, "hermetic", 0],
		[1, -207, "cage", 0], [-1, -225, "service", 0], [1, -243, "service", 0]]
	for e in list:
		var s: int = e[0]; var z: float = e[1]; var tier: int = e[3]
		var sect := 6 if z > GATE_Z else 7
		var num := "%d-%s%03d" % [sect, "В" if tier else "", int(abs(z if z > GATE_Z else z - GATE_Z))]
		var d := Props.door(e[2], num, rng.randf() < 0.2)
		d.position = Vector3(s * (HW - 0.005), CW_Y if tier else 0.0, z)
		d.rotation.y = PI / 2 if s < 0 else -PI / 2
		add_child(d)

## ================= ПРОВОДА =================
func _cables() -> void:
	var cm := Tex.cable()
	var near_gate := func(z0: float, z1: float) -> bool: return max(z0, z1) > GATE_Z - 0.6 and min(z0, z1) < GATE_Z + 0.6
	## петли, свисающие из кабель-каналов
	for t in [[-HW + 0.36, 5.9, 1], [-HW + 0.36, 6.6, 1], [HW - 0.36, 3.9, -1], [HW - 0.36, 4.6, -1]]:
		var x: float = t[0]; var y: float = t[1]; var sx: int = t[2]
		var z := -1.0
		while z > -DET:
			var L := R(1.8, 5.5)
			var in_niche: bool = sx < 0 and y < 4.7 and z > NICHE[1] - 1 and z - L < NICHE[0] + 1
			if rng.randf() < 0.5 and not near_gate.call(z, z - L) and not in_niche:
				var pts := Geo.catenary(Vector3(x, y, z), Vector3(x, y, z - L), R(0.3, 0.6 if y < 4.7 else 1.5), 12, Vector3(sx * R(0.05, 0.25), 0, 0))
				B.add(Geo.tube(pts, R(0.012, 0.03)), cm, Transform3D())
			z -= L * R(0.5, 1.2)
	## пролёты через коридор
	var z := -2.5
	while z > -DET:
		if not near_gate.call(z - 1, z + 1):
			for i in 1 + rng.randi() % 3:
				var zz := z + R(-0.8, 0.8)
				B.add(Geo.tube(Geo.catenary(Vector3(-HW + 0.3, R(6.3, 8.4), zz), Vector3(HW - 0.3, R(6.3, 8.4), zz + R(-1.5, 1.5)), R(0.6, 2.4), 16), R(0.018, 0.05)), cm, Transform3D())
		z -= R(3.5, 8)
	## оборванные концы с балок
	z = -6.0
	while z > -DET:
		if rng.randf() > 0.55 and abs(z - GATE_Z) > 2:
			var x := R(-0.6, 1.2); var y1 := R(4.6, 6.8); var bend := R(-0.4, 0.4)
			B.add(Geo.tube(PackedVector3Array([Vector3(x, CORR_H - 0.5, z), Vector3(x + bend * 0.3, (CORR_H + y1) / 2, z + 0.1), Vector3(x + bend, y1, z + R(-0.3, 0.3))]), R(0.015, 0.03)), cm, Transform3D())
		z -= 6.0

## ================= МУСОР, ЯЩИКИ, ЛУЖИ =================
func _clutter() -> void:
	var cr := Tex.crate()
	var crate := func(x: float, z: float, s: float, ry := 0.0, y := 0.0):
		B.box(Vector3(s, s * 0.8, s), cr, Vector3(x, y + s * 0.4, z), Vector3(0, ry, 0))
		if y == 0.0:
			Geo.solid(solids, Vector3(s, s * 0.8, s), Vector3(x, s * 0.4, z), Vector3(0, ry, 0))
	crate.call(-HW + 0.75, -4.4, 0.7, 0.1); crate.call(-HW + 0.55, -4.1, 0.45, 0.4, 0.56)
	crate.call(HW - 0.7, -18.5, 0.8, -0.2); crate.call(-HW + 0.7, -22.6, 0.6, 0.3)
	var z := -30.0
	while z > -DET:
		crate.call((-1.0 if rng.randf() < 0.5 else 1.0) * (HW - R(0.6, 0.8)), z + R(1, 2.5), R(0.45, 0.9), R(-0.5, 0.5))
		z -= R(8, 22)
	## кабельный барабан
	for ddz in [-0.25, 0.25]:
		B.cyl(0.5, 0.5, 0.08, Tex.crate(), Vector3(-HW + 0.7, 0.5, -16.5 + ddz), Vector3(PI / 2, 0, 0), 20)
	B.cyl(0.32, 0.32, 0.5, Tex.cable(), Vector3(-HW + 0.7, 0.5, -16.5), Vector3(PI / 2, 0, 0), 16)
	Geo.solid(solids, Vector3(1.0, 1.0, 0.8), Vector3(-HW + 0.7, 0.5, -16.5))
	## листы бумаги на полу
	var pm := Tex.plain("paper", Color(0.85, 0.82, 0.72), 0.95)
	for i in 70:
		var pz := R(-1, -19) if i < 12 else R(-20, -DET)
		B.box(Vector3(0.21, 0.002, 0.29), pm, Vector3(R(-HW + 0.2, HW - 0.2), 0.003 + i * 0.00002, pz), Vector3(0, R(0, TAU), 0))
	## лужи: глянцевые пятна, в них отражается свет
	var pud := StandardMaterial3D.new(); pud.albedo_color = Color(0.05, 0.05, 0.055); pud.roughness = 0.04; pud.metallic = 0.3
	for i in 26:
		var pz := R(-3, -18) if i < 4 else R(-22, -DET)
		var c := CylinderMesh.new(); c.top_radius = 1; c.bottom_radius = 1; c.height = 0.004; c.radial_segments = 20
		B.add(c, pud, Transform3D(Basis().scaled(Vector3(R(0.4, 1.3), 1, R(0.3, 0.9))), Vector3(R(-1.2, 1.2), 0.003, pz)))

## ================= СВЕТИЛЬНИКИ =================
## Лампы — данные. Свет дают несколько настоящих источников, которые каждый кадр встают на ближайшие лампы
## (lights.gd). Светящиеся части ламп — MultiMesh с цветом на экземпляр; дальние — «звёздочки» постоянного размера.
var lamp_mm := {}     # kind → MultiMesh светящихся частей
var star_mm: MultiMesh
func _lamps() -> void:
	var kinds := {"wall": [], "dome": [], "em": []}
	var i := 0; var z := -3.0
	while z > -LEN:
		var s := 1.0 if i % 2 else -1.0
		if not (s > 0 and z - 3 <= NICHE[0] and z - 3 >= NICHE[1]):
			kinds.wall.append([Vector3(s * (HW - 0.35), 3.35, z - 3), s])
		z -= 6.0; i += 1
	kinds.wall.append([Vector3(HW + 1.0, NICHE_H - 0.1, -8), 0.0])
	z = -9.0
	while z > -LEN:
		kinds.dome.append([Vector3(0.35, 7.0, z), 0.0]); z -= 18.0
	z = -1.5
	while z > -LEN:
		kinds.em.append([Vector3(-HW + 0.06, 2.6, z), 0.0]); z -= 12.0
	var meshes := {"wall": BoxMesh.new(), "dome": CylinderMesh.new(), "em": BoxMesh.new()}
	meshes.wall.size = Vector3(0.08, 0.06, 0.5)
	meshes.dome.top_radius = 0.32; meshes.dome.bottom_radius = 0.32; meshes.dome.height = 0.02
	meshes.em.size = Vector3(0.06, 0.1, 0.18)
	var housing := Tex.dark_metal()
	var shade := Tex.plain("shade", Color(0.22, 0.28, 0.22), 0.5, 0.4)
	for k in kinds:
		var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D; mm.use_colors = true; mm.mesh = meshes[k]
		mm.instance_count = kinds[k].size()
		for j in kinds[k].size():
			var p: Vector3 = kinds[k][j][0]; var s: float = kinds[k][j][1]
			var mp := p
			if k == "wall":
				mp = Vector3(p.x + s * 0.02 if s != 0 else p.x, p.y - 0.08, p.z)
				if -p.z < DET + 40: B.box(Vector3(0.3, 0.14, 0.6), housing, Vector3(p.x - s * 0.05 if s != 0 else p.x, p.y, p.z))
			elif k == "dome":
				mp = p - Vector3(0, 0.16, 0)
				if -p.z < DET + 40:
					B.cyl(0.08, 0.44, 0.32, shade, p, Vector3.ZERO, 16)
					B.box(Vector3(0.012, CORR_H - p.y - 0.3, 0.012), housing, Vector3(p.x, (CORR_H + p.y) / 2, p.z))
			mm.set_instance_transform(j, Transform3D(Basis(), mp))
			mm.set_instance_color(j, Color(0.03, 0.03, 0.03))
			var lp := p
			if k == "wall": lp = Vector3(p.x - s * 0.5 if s != 0 else p.x, p.y - 0.3, p.z)
			elif k == "dome": lp = p - Vector3(0, 0.4, 0)
			elif k == "em": lp = p + Vector3(0.4, 0, 0)
			lamps.append({"kind": k, "pos": lp, "glow": mp, "grp": "E" if k == "em" else ("A" if p.z > GATE_Z else "S7"),
				"lvl": 1.0 if k == "em" else 0.0, "on": 1 if k == "em" else 0, "fl": 0.0, "delay": 0.0, "inst": j})
		var mat := StandardMaterial3D.new(); mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; mat.vertex_color_use_as_albedo = true
		mat.set("disable_fog", true)
		var mmi := MultiMeshInstance3D.new(); mmi.multimesh = mm; mmi.material_override = mat; mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)
		lamp_mm[k] = mm
	## «звёздочки»: свечение ламп постоянного экранного размера — видно до горизонта
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var r := Vector2(x - 31.5, y - 31.5).length() / 32.0
			var a := pow(maxf(1.0 - r, 0.0), 2.2)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; sm.vertex_color_use_as_albedo = true
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; sm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	sm.albedo_texture = ImageTexture.create_from_image(img); sm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	sm.fixed_size = true; sm.no_depth_test = false; sm.set("disable_fog", true)
	var q := QuadMesh.new(); q.size = Vector2(0.035, 0.035)
	star_mm = MultiMesh.new(); star_mm.transform_format = MultiMesh.TRANSFORM_3D; star_mm.use_colors = true; star_mm.mesh = q
	star_mm.instance_count = lamps.size()
	for j in lamps.size():
		var L: Dictionary = lamps[j]
		var gp: Vector3 = L.get("glow", L.pos)
		var sz: float = {"wall": 1.0, "dome": 1.6, "em": 0.35, "bulb": 0.6}[L.kind]
		star_mm.set_instance_transform(j, Transform3D(Basis().scaled(Vector3.ONE * sz), gp))
		star_mm.set_instance_color(j, Color(0, 0, 0, 0))
		L["star"] = j
	var smi := MultiMeshInstance3D.new(); smi.multimesh = star_mm; smi.material_override = sm; smi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	smi.extra_cull_margin = 16384
	add_child(smi)
