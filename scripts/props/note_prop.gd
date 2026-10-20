@tool
## Записка на кнопке. Текст в мире — короткий (что видно издалека); полный текст — в hud.gd (NOTE).
class_name NoteProp
extends LevelPart

@export_multiline var text := "Смена 3\n— решётка —\n1987?..":
	set(v): text = v; changed()

func _build() -> void:
	Geo.box_node(gen, Vector3(0.21, 0.27, 0.004), Tex.plain("paper", Color(0.85, 0.82, 0.72), 0.95))
	Geo.label(gen, text, 30, Color(0.15, 0.15, 0.3), Vector3(0, 0.02, 0.004), Vector3.ZERO, 0.0018, true, 0.18)
	Geo.box_node(gen, Vector3(0.02, 0.02, 0.01), Tex.plain("pin", Color(0.7, 0.13, 0.13)), Vector3(0, 0.12, 0.005))
	Geo.act_zone(gen, Vector3(0.3, 0.35, 0.1), Vector3.ZERO, "note")
