@tool
## Дверь в коридоре Стены: служебная, гермодверь или решётчатая. Номер краской, лампа над дверью.
## Все заперты (подсказка «Дверь 6-009 · заперта»). Копируй узел (Ctrl+D), чтобы добавить дверь.
class_name CorridorDoor
extends LevelPart

@export_enum("service", "hermetic", "cage") var kind := "service":
	set(v): kind = v; changed()
@export var number := "6-009":
	set(v): number = v; changed()
@export var lamp_on := false:
	set(v): lamp_on = v; changed()

func _build() -> void:
	gen.add_child(Props.door(kind, number, lamp_on))
