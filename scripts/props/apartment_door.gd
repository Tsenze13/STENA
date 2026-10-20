@tool
## Квартирная дверь: style 0 — обита дерматином (стёжка, гвоздики), 1 — крашеная деревянная,
## 2 — железная «девяностых». Номер, глазок, ручка, звонок, коврик. Не открывается.
class_name ApartmentDoor
extends LevelPart

@export var number := 21:
	set(v): number = v; changed()
@export_enum("Дерматин", "Крашеная", "Железная") var style := 0:
	set(v): style = v; changed()
@export var color := Color(0.33, 0.12, 0.09):
	set(v): color = v; changed()

func _build() -> void:
	var w := 0.86; var h := 2.02
	var jamb := Tex.plain("apt_jamb", Color(0.4, 0.3, 0.2), 0.7)
	B.box(Vector3(0.07, h + 0.07, 0.1), jamb, Vector3(-w / 2 - 0.035, (h + 0.07) / 2, 0.02))
	B.box(Vector3(0.07, h + 0.07, 0.1), jamb, Vector3(w / 2 + 0.035, (h + 0.07) / 2, 0.02))
	B.box(Vector3(w + 0.14, 0.07, 0.1), jamb, Vector3(0, h + 0.035, 0.02))
	var leaf_c := color
	var metal := style == 2
	var body := Tex.metal("apt_steel", Color(0.24, 0.2, 0.17)) if metal else Tex.plain("apt_%d_%s" % [style, color.to_html()], leaf_c, 0.55)
	B.box(Vector3(w, h, 0.05), body, Vector3(0, h / 2, 0.035))
	var front_z := 0.061
	if style == 0:
		## дерматин: стёганая обивка с гвоздиками и окантовкой
		var q := QuadMesh.new(); q.size = Vector2(w - 0.06, h - 0.08)
		var mi := MeshInstance3D.new(); mi.mesh = q; mi.material_override = Tex.dermatin("derm_" + color.to_html(), color)
		mi.position = Vector3(0, h / 2, 0.066); gen.add_child(mi)
		var trim := Tex.plain("trim", Color(0.7, 0.6, 0.35), 0.3, 0.7)
		for p in [[Vector3(w - 0.04, 0.012, 0.01), Vector3(0, 0.05, 0.068)], [Vector3(w - 0.04, 0.012, 0.01), Vector3(0, h - 0.05, 0.068)],
				[Vector3(0.012, h - 0.1, 0.01), Vector3(-w / 2 + 0.03, h / 2, 0.068)], [Vector3(0.012, h - 0.1, 0.01), Vector3(w / 2 - 0.03, h / 2, 0.068)]]:
			B.box(p[0], trim, p[1])
		front_z = 0.075
	elif style == 1:
		## филёнки
		var dark := Tex.plain("apt_panel_%s" % color.to_html(), color.darkened(0.2), 0.6)
		for y in [0.55, 1.45]:
			B.box(Vector3(w - 0.24, 0.7, 0.012), dark, Vector3(0, y, 0.064))
	else:
		B.box(Vector3(0.1, 0.16, 0.02), Tex.plain("lock2", Color(0.6, 0.58, 0.5), 0.3, 0.8), Vector3(w / 2 - 0.12, 1.15, 0.07))
		for k in 2:
			B.box(Vector3(0.03, 0.06, 0.02), Tex.plain("lock2", Color(0.6, 0.58, 0.5), 0.3, 0.8), Vector3(w / 2 - 0.12, 0.95 + k * 0.4, 0.07))
	## номер: латунная табличка
	Geo.box_node(gen, Vector3(0.12, 0.08, 0.006), Tex.plain("brass", Color(0.75, 0.6, 0.3), 0.3, 0.8), Vector3(0, 1.62, front_z))
	Geo.label(gen, str(number), 64, Color(0.12, 0.09, 0.05), Vector3(0, 1.62, front_z + 0.004), Vector3.ZERO, 0.0011)
	## глазок, ручка, замок
	Geo.cyl_node(gen, 0.013, 0.013, 0.02, Tex.plain("brass", Color(0.75, 0.6, 0.3), 0.3, 0.8), Vector3(0, 1.48, front_z), Vector3(PI / 2, 0, 0), 10)
	var hm := Tex.plain("handle", Color(0.55, 0.52, 0.48), 0.35, 0.8)
	Geo.box_node(gen, Vector3(0.13, 0.025, 0.04), hm, Vector3(w / 2 - 0.13, 1.0, front_z + 0.03))
	Geo.cyl_node(gen, 0.02, 0.02, 0.02, hm, Vector3(w / 2 - 0.08, 1.12, front_z), Vector3(PI / 2, 0, 0), 10)
	## звонок рядом с коробкой и провод от него вверх
	var bx := w / 2 + 0.2
	B.box(Vector3(0.06, 0.08, 0.025), Tex.plain("bell", Color(0.85, 0.83, 0.75), 0.4), Vector3(bx, 1.45, 0.012))
	B.cyl(0.012, 0.012, 0.01, Tex.plain("bell_btn", Color(0.15, 0.15, 0.15), 0.4), Vector3(bx, 1.45, 0.028), Vector3(PI / 2, 0, 0), 8)
	B.box(Vector3(0.006, 1.4, 0.006), Tex.plain("wire_old", Color(0.16, 0.12, 0.09), 0.6), Vector3(bx, 2.2, 0.008))
	## коврик
	B.box(Vector3(0.7, 0.012, 0.45), Tex.surface("mat", Color(0.22, 0.17, 0.12), 0.95, 0.0, 6.0, 0.6, 3.0, 41, 0.2), Vector3(R(-0.05, 0.05), 0.006, 0.4), Vector3(0, R(-0.15, 0.15), 0))
