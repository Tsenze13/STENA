@tool
## Пожарный кран в красном шкафу со стеклом.
class_name FireHose
extends LevelPart

@export var label_text := "ПК-6":
	set(v): label_text = v; changed()

func _build() -> void:
	Geo.box_node(gen, Vector3(0.6, 0.8, 0.25), Tex.metal("pk", Color(0.55, 0.08, 0.06)))
	Geo.box_node(gen, Vector3(0.5, 0.62, 0.01), Tex.plain("pk_glass", Color(0.08, 0.1, 0.1), 0.1, 0.3), Vector3(0, -0.02, 0.126))
	## рукав, свёрнутый внутри (видно через стекло)
	for r in [0.17, 0.13, 0.09]:
		Geo.cyl_node(gen, r, r, 0.05, Tex.plain("hose", Color(0.75, 0.72, 0.6), 0.8), Vector3(0, -0.05, 0.05), Vector3(PI / 2, 0, 0), 18)
	Geo.paint(gen, label_text, 0.1, Color(0.92, 0.9, 0.84), Vector3(0, 0.32, 0.127), Vector3.ZERO, 0.2)
	Geo.solid(solids, Vector3(0.6, 0.8, 0.3), Vector3.ZERO)
