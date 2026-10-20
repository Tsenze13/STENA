@tool
## Табличка или плакат: эмаль с рамкой и заклёпками, либо бумажное объявление на скотче (paper).
## Первая строка — заголовок (title_size), остальные — текст (body_size). Пустая строка — отступ.
class_name SignPlate
extends LevelPart

@export_multiline var text := "НЕ ВЛЕЗАЙ!\nУБЬЁТ!":
	set(v): text = v; changed()
@export var size := Vector2(0.3, 0.2):
	set(v): size = v; changed()
@export var background := Color(0.93, 0.92, 0.86):
	set(v): background = v; changed()
@export var ink := Color(0.72, 0.1, 0.08):
	set(v): ink = v; changed()
@export var title_size := 34:
	set(v): title_size = v; changed()
@export var body_size := 24:
	set(v): body_size = v; changed()
@export var paper := false:
	set(v): paper = v; changed()

func _build() -> void:
	var lines := []
	var parts := text.split("\n")
	for i in parts.size():
		lines.append([parts[i], 10 if parts[i] == "" else (title_size if i == 0 else body_size)])
	Geo.plate(gen, lines, size, background, ink, Vector3.ZERO, Vector3.ZERO, "", paper)
