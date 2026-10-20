@tool
## Провода: петли, свисающие из кабельных лотков, пролёты через коридор, оборванные концы с балок.
## pattern — другой узор проводов, density — сколько их.
class_name Cables
extends LevelPart

const HW := World.HW
const CORR_H := World.CORR_H

@export var pattern := 1337:
	set(v): pattern = v; changed()
@export_range(0.0, 1.0) var density := 0.5:
	set(v): density = v; changed()

func _build() -> void:
	rng.seed = pattern
	var cm := Tex.cable()
	var GZ := World.GATE_Z
	var near_gate := func(z0: float, z1: float) -> bool: return max(z0, z1) > GZ - 0.6 and min(z0, z1) < GZ + 0.6
	## петли, свисающие из кабель-каналов
	for t in [[-HW + 0.36, 5.9, 1], [-HW + 0.36, 6.6, 1], [HW - 0.36, 3.9, -1], [HW - 0.36, 4.6, -1]]:
		var x: float = t[0]; var y: float = t[1]; var sx: int = t[2]
		var z := -1.0
		while z > -World.DET:
			var L := R(1.8, 5.5)
			var in_niche: bool = sx < 0 and y < 4.7 and z > World.NICHE[1] - 1 and z - L < World.NICHE[0] + 1
			if rng.randf() < density and not near_gate.call(z, z - L) and not in_niche:
				var pts := Geo.catenary(Vector3(x, y, z), Vector3(x, y, z - L), R(0.3, 0.6 if y < 4.7 else 1.5), 12, Vector3(sx * R(0.05, 0.25), 0, 0))
				B.add(Geo.tube(pts, R(0.012, 0.03)), cm, Transform3D())
			z -= L * R(0.5, 1.2)
	## пролёты через коридор
	var z := -2.5
	while z > -World.DET:
		if not near_gate.call(z - 1, z + 1):
			for i in 1 + rng.randi() % 3:
				var zz := z + R(-0.8, 0.8)
				B.add(Geo.tube(Geo.catenary(Vector3(-HW + 0.3, R(6.3, 8.4), zz), Vector3(HW - 0.3, R(6.3, 8.4), zz + R(-1.5, 1.5)), R(0.6, 2.4), 16), R(0.018, 0.05)), cm, Transform3D())
		z -= R(3.5, 8) / maxf(density * 2.0, 0.2)
	## оборванные концы с балок
	z = -6.0
	while z > -World.DET:
		if rng.randf() > 1.05 - density and abs(z - GZ) > 2:
			var x := R(-0.6, 1.2); var y1 := R(4.6, 6.8); var bend := R(-0.4, 0.4)
			B.add(Geo.tube(PackedVector3Array([Vector3(x, CORR_H - 0.5, z), Vector3(x + bend * 0.3, (CORR_H + y1) / 2, z + 0.1), Vector3(x + bend, y1, z + R(-0.3, 0.3))]), R(0.015, 0.03)), cm, Transform3D())
		z -= 6.0
