@tool
## Пожарный кран в красном шкафу (модель Sketchfab).
class_name FireHose
extends LevelPart

@export var label_text := "ПК-6":
	set(v): label_text = v; changed()

func _build() -> void:
	## модель шкафа (Sketchfab «Fire Hose Cabinet», CC BY); в файле смотрит в +X — поворачиваем лицом вперёд
	Geo.model(gen, Props.SKF % "hose_cabinet", Vector3(0.6, 0.8, 0.25), Vector3(0, -90, 0), Vector3(0, -0.4, 0))
	Geo.paint(gen, label_text, 0.1, Color(0.92, 0.9, 0.84), Vector3(0, 0.32, 0.127), Vector3.ZERO, 0.2)
	Geo.solid(solids, Vector3(0.6, 0.8, 0.3), Vector3.ZERO)
