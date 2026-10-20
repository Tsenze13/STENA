@tool
## Надпись краской по трафарету (облезлая). height — высота строки в метрах, wear 0..0.6 — насколько облезла.
## handwriting — от руки (маркер, мел), а не трафарет.
class_name Stencil
extends LevelPart

@export_multiline var text := "6":
	set(v): text = v; changed()
@export var height := 0.3:
	set(v): height = v; changed()
@export var color := Color(0.85, 0.83, 0.76):
	set(v): color = v; changed()
@export_range(0.0, 0.7) var wear := 0.35:
	set(v): wear = v; changed()
@export var handwriting := false:
	set(v): handwriting = v; changed()

func _build() -> void:
	var fonts := PackedStringArray(["Segoe Print", "Comic Sans MS", "DejaVu Serif"]) if handwriting else PackedStringArray()
	Geo.paint(gen, text, height, color, Vector3.ZERO, Vector3.ZERO, wear, not handwriting, fonts)
