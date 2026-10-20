@tool
## Мусор: ящики, кабельный барабан, листы бумаги на полу, лужи (в них отражается свет).
class_name Clutter
extends LevelPart

const HW := World.HW

@export var pattern := 1337:
	set(v): pattern = v; changed()

func _build() -> void:
	rng.seed = pattern
	var cr := Tex.crate()
	var crate := func(x: float, z: float, s: float, ry := 0.0, y := 0.0):
		if x > 0 and z < World.SHAFT[0] + 1 and z > World.SHAFT[1] - 1: return
		B.box(Vector3(s, s * 0.8, s), cr, Vector3(x, y + s * 0.4, z), Vector3(0, ry, 0))
		if y == 0.0:
			Geo.solid(solids, Vector3(s, s * 0.8, s), Vector3(x, s * 0.4, z), Vector3(0, ry, 0))
	crate.call(-HW + 0.75, -4.4, 0.7, 0.1); crate.call(-HW + 0.55, -4.1, 0.45, 0.4, 0.56)
	crate.call(HW - 0.7, -18.5, 0.8, -0.2); crate.call(-HW + 0.7, -22.6, 0.6, 0.3)
	var z := -30.0
	while z > -World.DET:
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
		var pz := R(-1, -19) if i < 12 else R(-20, -World.DET)
		B.box(Vector3(0.21, 0.002, 0.29), pm, Vector3(R(-HW + 0.2, HW - 0.2), 0.003 + i * 0.00002, pz), Vector3(0, R(0, TAU), 0))
	## лужи: глянцевые пятна, в них отражается свет
	var pud := Tex.plain("puddle", Color(0.05, 0.05, 0.055), 0.04, 0.3)
	for i in 26:
		var pz := R(-3, -18) if i < 4 else R(-22, -World.DET)
		var c := CylinderMesh.new(); c.top_radius = 1; c.bottom_radius = 1; c.height = 0.004; c.radial_segments = 20
		B.add(c, pud, Transform3D(Basis().scaled(Vector3(R(0.4, 1.3), 1, R(0.3, 0.9))), Vector3(R(-1.2, 1.2), 0.003, pz)))
