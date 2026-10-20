@tool
## Огнетушитель ОУ-5 на полу у стены.
class_name Extinguisher
extends LevelPart

func _build() -> void:
	Geo.cyl_node(gen, 0.08, 0.08, 0.5, Tex.plain("ext", Color(0.62, 0.07, 0.05), 0.35, 0.3), Vector3(0, 0.3, 0), Vector3.ZERO, 16)
	Geo.cyl_node(gen, 0.03, 0.05, 0.08, Tex.plain("ext_top", Color(0.15, 0.15, 0.15), 0.4, 0.6), Vector3(0, 0.59, 0), Vector3.ZERO, 10)
	Geo.box_node(gen, Vector3(0.12, 0.02, 0.03), Tex.plain("ext_top", Color(0.15, 0.15, 0.15), 0.4, 0.6), Vector3(0.04, 0.64, 0))
	Geo.cyl_node(gen, 0.012, 0.012, 0.35, Tex.plain("hose_b", Color(0.08, 0.08, 0.08), 0.6), Vector3(-0.09, 0.42, 0), Vector3(0, 0, 0.2), 6)
	Geo.paint(gen, "ОУ-5", 0.04, Color(0.92, 0.9, 0.84), Vector3(0.0, 0.35, 0.081), Vector3.ZERO, 0.25)
