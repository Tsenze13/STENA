@tool
## Дверь «Электрощитовая» на площадке: коробка, полотно на петлях (открывается внутрь), трафарет,
## эмалированные таблички, ручка. Номер щитовой краской над дверью. Состояние двери — в state (game.gd).
class_name EntryDoor
extends LevelPart

@export var title := "ЭЛЕКТРОЩИТОВАЯ":
	set(v): title = v; changed()
@export var number := "ЩР-6":
	set(v): number = v; changed()

var state := {}

func _build() -> void:
	var green := Tex.green_paint(); var white := Tex.whitewash()
	## стена вокруг двери (со стороны площадки)
	for sx in [-1.0, 1.0]:
		wall(Vector3(2.6, 1.5, 0.2), Vector3(sx * 1.9, 0.75, 0), green); wall(Vector3(2.6, 1.5, 0.2), Vector3(sx * 1.9, 2.25, 0), white)
	wall(Vector3(1.2, 0.9, 0.2), Vector3(0, 2.55, 0), white)
	var jamb := Tex.plain("jamb", Color(0.23, 0.17, 0.13), 0.7)
	B.box(Vector3(0.08, 2.15, 0.26), jamb, Vector3(-0.64, 1.07, 0)); B.box(Vector3(0.08, 2.15, 0.26), jamb, Vector3(0.64, 1.07, 0)); B.box(Vector3(1.36, 0.08, 0.26), jamb, Vector3(0, 2.14, 0))
	## полотно на петлях (слева)
	var pivot := Node3D.new(); pivot.position = Vector3(-0.6, 0, 0); gen.add_child(pivot)
	Geo.box_node(pivot, Vector3(1.2, 2.1, 0.06), Tex.metal("door", Color(0.35, 0.23, 0.17)), Vector3(0.6, 1.05, 0))
	Geo.paint(pivot, title, 0.085, Color(0.62, 0.1, 0.07), Vector3(0.6, 1.86, 0.032), Vector3.ZERO, 0.32)
	Geo.plate(pivot, [["НЕ ВЛЕЗАЙ!", 36], ["УБЬЁТ!", 36]], Vector2(0.28, 0.22), Color(0.93, 0.92, 0.86), Color(0.72, 0.1, 0.08), Vector3(0.6, 1.5, 0.034), Vector3.ZERO, "⚡")
	Geo.plate(pivot, [["ПОСТОРОННИМ", 24], ["ВХОД ВОСПРЕЩЁН", 24]], Vector2(0.26, 0.08), Color(0.9, 0.88, 0.8), Color(0.08, 0.08, 0.08), Vector3(0.6, 1.24, 0.034))
	Geo.box_node(pivot, Vector3(0.12, 0.03, 0.05), Tex.plain("handle", Color(0.55, 0.52, 0.48), 0.35, 0.8), Vector3(1.05, 1.0, 0.06))
	Geo.box_node(pivot, Vector3(0.05, 0.08, 0.02), Tex.plain("lock", Color(0.3, 0.28, 0.25), 0.4, 0.7), Vector3(1.05, 0.88, 0.04))
	var dz := Geo.act_zone(pivot, Vector3(1.2, 2.1, 0.2), Vector3(0.6, 1.05, 0), "door")
	state = {"pivot": pivot, "open": 0.0, "target": 0.0, "shape": Geo.solid(solids, Vector3(1.2, 2.1, 0.1), Vector3(0, 1.05, 0)), "zone": dz}
	Geo.paint(gen, number, 0.12, Color(0.85, 0.83, 0.76), Vector3(0, 2.42, 0.105), Vector3.ZERO, 0.4)
