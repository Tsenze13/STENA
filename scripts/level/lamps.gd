@tool
## Светильники коридора. Лампы — данные: свет дают несколько настоящих источников, которые каждый кадр
## встают на ближайшие лампы (lights.gd). Светящиеся части — MultiMesh с цветом на экземпляр.
## Группы: A — участок 6 (щиток ЩР-6), S7 — участок 7 (включается после решётки), E — аварийные.
class_name Lamps
extends LevelPart

const HW := World.HW
const CORR_H := World.CORR_H

@export var wall_step := 6.0:
	set(v): wall_step = maxf(v, 1.0); changed()
@export var dome_step := 18.0:
	set(v): dome_step = maxf(v, 2.0); changed()
@export var emergency_step := 12.0:
	set(v): emergency_step = maxf(v, 2.0); changed()

var lamps: Array = []
var lamp_mm := {}

func _build() -> void:
	lamps = []; lamp_mm = {}
	var kinds := {"wall": [], "dome": [], "em": []}
	var i := 0; var z := -3.0
	var in_gap := func(zz: float) -> bool:
		return (zz <= World.NICHE[0] and zz >= World.NICHE[1]) or (zz <= World.SHAFT[0] + 0.5 and zz >= World.SHAFT[1] - 0.5)
	while z > -World.LEN:
		var s := 1.0 if i % 2 else -1.0
		if not (s > 0 and in_gap.call(z - 3)):
			kinds.wall.append([Vector3(s * (HW - 0.35), 3.35, z - 3), s])
		z -= wall_step; i += 1
	kinds.wall.append([Vector3(HW + 1.0, World.NICHE_H - 0.1, -8), 0.0])
	z = -9.0
	while z > -World.LEN:
		kinds.dome.append([Vector3(0.35, 7.0, z), 0.0]); z -= dome_step
	## над балконом у колодца
	kinds.dome.append([Vector3(HW + 1.0, World.SHAFT_H - 0.6, (World.SHAFT[0] + World.SHAFT[1]) / 2), 0.0])
	z = -1.5
	while z > -World.LEN:
		kinds.em.append([Vector3(-HW + 0.06, 2.6, z), 0.0]); z -= emergency_step
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
				if -p.z < World.DET + 40: B.box(Vector3(0.3, 0.14, 0.6), housing, Vector3(p.x - s * 0.05 if s != 0 else p.x, p.y, p.z))
			elif k == "dome":
				mp = p - Vector3(0, 0.16, 0)
				if -p.z < World.DET + 40:
					B.cyl(0.08, 0.44, 0.32, shade, p, Vector3.ZERO, 16)
					var top := CORR_H if p.x < HW else World.SHAFT_H
					B.box(Vector3(0.012, top - p.y - 0.3, 0.012), housing, Vector3(p.x, (top + p.y) / 2, p.z))
			mm.set_instance_transform(j, Transform3D(Basis(), mp))
			mm.set_instance_color(j, Color(0.03, 0.03, 0.03))
			var lp := p
			if k == "wall": lp = Vector3(p.x - s * 0.5 if s != 0 else p.x, p.y - 0.3, p.z)
			elif k == "dome": lp = p - Vector3(0, 0.4, 0)
			elif k == "em": lp = p + Vector3(0.4, 0, 0)
			lamps.append({"kind": k, "pos": lp, "glow": mp, "grp": "E" if k == "em" else ("A" if p.z > World.GATE_Z else "S7"),
				"lvl": 1.0 if k == "em" else 0.0, "on": 1 if k == "em" else 0, "fl": 0.0, "delay": 0.0, "inst": j})
		var mat := StandardMaterial3D.new(); mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; mat.vertex_color_use_as_albedo = true
		mat.set("disable_fog", true)
		var mmi := MultiMeshInstance3D.new(); mmi.multimesh = mm; mmi.material_override = mat; mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		gen.add_child(mmi)
		lamp_mm[k] = mm
