@tool
## Этажный щиток в подъезде: серый металлический ящик со счётчиками за окошком, трафарет, замок,
## провода из него к потолку.
class_name MeterBox
extends LevelPart

@export var label_text := "ЩЭ-6":
	set(v): label_text = v; changed()

func _build() -> void:
	var grey := Tex.metal("meterbox", Color(0.45, 0.47, 0.44))
	B.box(Vector3(0.62, 0.8, 0.16), grey, Vector3(0, 0, 0.08))
	B.box(Vector3(0.58, 0.76, 0.02), Tex.metal("meterbox_door", Color(0.5, 0.52, 0.48)), Vector3(0, 0, 0.17))
	## окошко со счётчиками
	B.box(Vector3(0.36, 0.16, 0.005), Tex.plain("meter_glass", Color(0.06, 0.07, 0.07), 0.1, 0.4), Vector3(0, 0.18, 0.182))
	for k in 3:
		B.box(Vector3(0.09, 0.05, 0.004), Tex.plain("meter_face", Color(0.78, 0.76, 0.68), 0.5), Vector3(-0.12 + k * 0.12, 0.19, 0.185))
	B.box(Vector3(0.05, 0.07, 0.02), Tex.plain("lock", Color(0.3, 0.28, 0.25), 0.4, 0.7), Vector3(0.24, -0.05, 0.19))
	Geo.paint(gen, label_text, 0.07, Color(0.82, 0.1, 0.07), Vector3(0, -0.18, 0.181), Vector3.ZERO, 0.3)
	Geo.plate(gen, [["⚡", 60]], Vector2(0.09, 0.08), Color(0.95, 0.8, 0.1), Color(0.05, 0.05, 0.05), Vector3(0, 0.0, 0.181))
	for i in 3:
		B.cyl(0.008, 0.008, 1.0, Tex.cable(), Vector3(-0.15 + i * 0.05, 0.9, 0.05), Vector3.ZERO, 6)
