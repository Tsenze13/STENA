@tool
## Тамбур на входе в шлюз (1 этаж): маленький бетонный короб на фасаде Стены, наружная гермодверь
## и внутренняя дверь — отдельные сцены SwingDoor. Здесь — стены, пол, крыша, лампа, табличка.
class_name Entrance
extends LevelPart

var lamps: Array = []

func _build() -> void:
	lamps = []
	var y0 := Stairwell.floor_y(1)
	var Z0 := Stairwell.BACK + 0.2; var Z1 := 7.4
	var conc := Tex.surface("conc_cold", Color(0.5, 0.52, 0.55), 0.92, 0.0, 0.45, 0.45, 2.0, 62, 0.04)
	var H := 2.8
	wall(Vector3(0.2, H, Z1 - Z0 + 0.2), Vector3(-2.7, y0 + H / 2, (Z0 + Z1) / 2), conc)
	wall(Vector3(0.2, H, Z1 - Z0 + 0.2), Vector3(-0.5, y0 + H / 2, (Z0 + Z1) / 2), conc)
	wall(Vector3(0.6, H, 0.2), Vector3(-2.5, y0 + H / 2, Z1), conc)
	wall(Vector3(0.6, H, 0.2), Vector3(-0.7, y0 + H / 2, Z1), conc)
	wall(Vector3(1.2, H - 2.1, 0.2), Vector3(-1.6, y0 + 2.1 + (H - 2.1) / 2, Z1), conc)
	wall(Vector3(2.4, 0.14, Z1 - Z0), Vector3(-1.6, y0 - 0.07, (Z0 + Z1) / 2), Tex.floor_concrete())
	wall(Vector3(2.6, 0.25, Z1 - Z0 + 0.3), Vector3(-1.6, y0 + H + 0.12, (Z0 + Z1) / 2), conc, false)
	## снег на крыше
	B.box(Vector3(2.7, 0.18, Z1 - Z0 + 0.4), Tex.snow(), Vector3(-1.6, y0 + H + 0.33, (Z0 + Z1) / 2))
	## нанесённый снег у входа
	B.box(Vector3(1.6, 0.04, 0.7), Tex.snow(), Vector3(-1.6, y0 + 0.02, Z1 - 0.4))
	## лампа внутри
	var lp := Vector3(-1.6, y0 + H - 0.12, (Z0 + Z1) / 2)
	B.cyl(0.1, 0.1, 0.06, Tex.dark_metal(), lp + Vector3(0, 0.05, 0), Vector3.ZERO, 10)
	var mi := MeshInstance3D.new(); var sp := SphereMesh.new(); sp.radius = 0.05; sp.height = 0.1; mi.mesh = sp
	var gm := StandardMaterial3D.new(); gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; mi.material_override = gm
	mi.position = lp; gen.add_child(mi)
	lamps.append({"kind": "bulb", "pos": lp - Vector3(0, 0.2, 0), "grp": "L", "lvl": 0.8, "on": 1, "fl": 0.0, "delay": 0.0, "mesh": mi})
	## фонарь над наружной дверью (натриевый, на кронштейне)
	var sp2 := Vector3(-1.6, y0 + H + 0.05, Z1 + 0.45)
	B.box(Vector3(0.06, 0.06, 0.5), Tex.dark_metal(), sp2 + Vector3(0, 0.1, -0.25))
	B.box(Vector3(0.3, 0.1, 0.22), Tex.dark_metal(), sp2 + Vector3(0, 0.06, 0))
	var mi2 := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(0.24, 0.03, 0.16); mi2.mesh = bm
	var gm2 := StandardMaterial3D.new(); gm2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; mi2.material_override = gm2
	mi2.position = sp2 - Vector3(0, 0.0, 0); gen.add_child(mi2)
	lamps.append({"kind": "sodium", "pos": sp2 - Vector3(0, 0.4, -0.3), "grp": "L", "lvl": 1.0, "on": 1, "fl": 0.0, "delay": 0.0, "mesh": mi2, "tint": Color(1.0, 0.62, 0.3)})
	Geo.plate(gen, [["ВХОД ДЛЯ", 26], ["ОБСЛУЖИВАЮЩЕГО", 26], ["ПЕРСОНАЛА", 26]], Vector2(0.4, 0.22), Color(0.9, 0.9, 0.86), Color(0.1, 0.1, 0.12), Vector3(-0.7, y0 + 1.5, Z1 + 0.105))
