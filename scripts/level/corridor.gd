@tool
## Служебный коридор Стены: 4 м шириной, 9 м высотой, 2 км длиной. Бетонные стены с крашеной полосой,
## ниша справа (щиток и пульт), проём на балкон над колодцем (участок 7), пилястры и балки каждые 6 м,
## трубы, вентиляционный короб, кабельные лотки, отметки расстояния краской.
class_name Corridor
extends LevelPart

const HW := World.HW
const CORR_W := World.CORR_W
const CORR_H := World.CORR_H
const LEN := World.LEN
const NICHE := World.NICHE

func _build() -> void:
	piece("DoorWall")
	var conc := Tex.concrete(); var band := Tex.paint_band(); var yel := Tex.yellow()
	var seam := Tex.plain("seam", Color(0.12, 0.12, 0.11), 0.9)
	## стена с дверью со стороны коридора поднимается до потолка
	wall(Vector3(CORR_W + 0.6, CORR_H - 3, 0.2), Vector3(0, 3 + (CORR_H - 3) / 2, -0.1), conc)
	piece("Walls")
	## продольные стены: бетон, снизу крашеная полоса 1,5 м и жёлтая линия
	var side := func(sx: float, z0: float, z1: float, y0: float, y1 := CORR_H):
		var L: float = abs(z1 - z0); var zc: float = (z0 + z1) / 2
		var x: float = sx * (HW + 0.15)
		wall(Vector3(0.3, y1 - y0, L), Vector3(x, y0 + (y1 - y0) / 2, zc), conc, y0 == 0)
		if y0 == 0:
			B.box(Vector3(0.02, 1.5, L), band, Vector3(sx * (HW - 0.01), 0.75, zc))
			B.box(Vector3(0.02, 0.07, L), yel, Vector3(sx * (HW - 0.01), 1.52, zc))
			## швы бетонных панелей через каждые 1,5 м
			for y in [3.0, 4.5, 6.0, 7.5]:
				if y < y1: B.box(Vector3(0.015, 0.03, L), seam, Vector3(sx * (HW - 0.005), y, zc))
	side.call(-1.0, 0.0, -LEN, 0.0)
	side.call(1.0, 0.0, NICHE[0], 0.0)
	side.call(1.0, NICHE[1], World.SHAFT[0], 0.0)
	side.call(1.0, World.SHAFT[1], -LEN, 0.0)
	side.call(1.0, NICHE[0], NICHE[1], World.NICHE_H)
	side.call(1.0, World.SHAFT[0], World.SHAFT[1], World.SHAFT_H)
	## обрамление проёма на балкон: жёлтые полосы
	for z in World.SHAFT:
		B.box(Vector3(0.32, World.SHAFT_H, 0.12), Tex.hazard(), Vector3(HW + 0.15, World.SHAFT_H / 2, z))
	B.box(Vector3(0.32, 0.14, abs(World.SHAFT[1] - World.SHAFT[0])), Tex.hazard(), Vector3(HW + 0.15, World.SHAFT_H + 0.07, (World.SHAFT[0] + World.SHAFT[1]) / 2))
	piece("FloorCeiling")
	## пол и потолок
	wall(Vector3(CORR_W, 0.2, LEN), Vector3(0, -0.1, -LEN / 2), Tex.floor_concrete())
	for sx in [-1.0, 1.0]:
		B.box(Vector3(0.1, 0.004, LEN), yel, Vector3(sx * (HW - 0.4), 0.002, -LEN / 2))
	wall(Vector3(CORR_W + 0.6, 0.3, LEN), Vector3(0, CORR_H + 0.15, -LEN / 2), Tex.ceiling(), false)
	wall(Vector3(CORR_W + 1, CORR_H, 0.3), Vector3(0, CORR_H / 2, -LEN - 0.15), Tex.plain("end", Color(0.05, 0.05, 0.05)))

	piece("Pilasters")
	## пилястры и потолочные балки каждые 6 м (MultiMesh — их сотни)
	var n := int(LEN / 6)
	var pil := BoxMesh.new(); pil.size = Vector3(0.4, CORR_H, 0.3)
	var bm := BoxMesh.new(); bm.size = Vector3(CORR_W, 0.5, 0.3)
	var pmat := Tex.surface("pilaster", Color(0.37, 0.38, 0.35), 0.85, 0.0, 0.5)
	var xfs_l := []; var xfs_r := []; var xfs_b := []
	for i in n:
		var z := -6.0 * (i + 1)
		var gap := (z <= NICHE[0] and z >= NICHE[1]) or (z <= World.SHAFT[0] + 0.3 and z >= World.SHAFT[1] - 0.3)
		xfs_l.append(Transform3D(Basis(), Vector3(-HW + 0.15, CORR_H / 2, z)))
		if not gap:
			xfs_r.append(Transform3D(Basis(), Vector3(HW - 0.15, CORR_H / 2, z)))
		xfs_b.append(Transform3D(Basis(), Vector3(0, CORR_H - 0.25, z)))
		if -z < World.DET:
			Geo.solid(solids, Vector3(0.35, 3, 0.3), Vector3(-HW + 0.175, 1.5, z))
			if not gap:
				Geo.solid(solids, Vector3(0.35, 3, 0.3), Vector3(HW - 0.175, 1.5, z))
	for item in [[pil, xfs_l], [pil, xfs_r], [bm, xfs_b]]:
		_multi(item[0], pmat, item[1])

	piece("Pipes")
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
	while z > -World.DET:
		B.box(Vector3(1.0, 0.8, 0.06), tray, Vector3(HW - 0.6, 6.2, z))
		B.box(Vector3(0.06, 0.5, 0.1), Tex.dark_metal(), Vector3(HW - 0.06, 7.95, z))
		z -= 3.0
	## трафаретные отметки расстояния
	var d := 50
	while d <= 500:
		Geo.paint(gen, ("6-" if d <= -World.GATE_Z else "7-") + "%04d" % d, 0.32, Color(0.85, 0.83, 0.76), Vector3(-HW + 0.01, 2.3, -d - 3), Vector3(0, PI / 2, 0), 0.35)
		d += 50
