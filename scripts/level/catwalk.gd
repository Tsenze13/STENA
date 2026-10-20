@tool
## Мостки слева на высоте 4,2 м: решётчатый настил, перила, подкосы, стремянки.
class_name Catwalk
extends LevelPart

const HW := World.HW
const CW_Y := World.CW_Y

@export var ladders: PackedFloat32Array = PackedFloat32Array([-13.2, -61.2]):
	set(v): ladders = v; changed()

func _build() -> void:
	var cw_x := -HW + 1.15
	var metal := Tex.metal()
	var walk := func(z0: float, z1: float):
		var L: float = abs(z1 - z0); var zc: float = (z0 + z1) / 2
		var gm: StandardMaterial3D = Tex.grate().duplicate()
		gm.uv1_scale = Vector3(1.15 / 0.5, L / 0.5, 1)
		var p := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(1.15, L); p.mesh = pm; p.material_override = gm
		p.position = Vector3(-HW + 0.575, CW_Y, zc); gen.add_child(p)
		B.box(Vector3(0.06, 0.16, L), metal, Vector3(cw_x, CW_Y - 0.06, zc))
		B.box(Vector3(0.04, 0.04, L), Tex.yellow(), Vector3(cw_x, CW_Y + 1.05, zc))
		B.box(Vector3(0.03, 0.03, L), metal, Vector3(cw_x, CW_Y + 0.55, zc))
		var z: float = z0
		while z >= z1:
			B.box(Vector3(0.04, 1.05, 0.04), metal, Vector3(cw_x, CW_Y + 0.52, z)); z -= 1.5
	walk.call(-0.5, World.GATE_Z + 0.4)
	walk.call(World.GATE_Z - 0.4, -World.DET)
	var z := -6.0
	while z > -World.DET:
		B.box(Vector3(0.08, 1.45, 0.08), Tex.dark_metal(), Vector3(-HW + 0.6, CW_Y - 0.55, z), Vector3(0, 0, -0.85)); z -= 6.0
	## стремянки на мостки
	for lz in ladders:
		for ddz in [-0.25, 0.25]:
			B.box(Vector3(0.05, CW_Y + 1.1, 0.05), metal, Vector3(-HW + 0.14, (CW_Y + 1.1) / 2, lz + ddz))
		var y := 0.3
		while y < CW_Y + 1:
			B.box(Vector3(0.04, 0.03, 0.5), metal, Vector3(-HW + 0.14, y, lz)); y += 0.3
