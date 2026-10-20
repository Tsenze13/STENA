@tool
## Литая бронзовая табличка участка. Текст сам уменьшается, чтобы не вылезать за край.
## act — что покажет подсказка при взгляде (см. _prompt_for в main.gd).
class_name PlaqueProp
extends LevelPart

@export var title := "УЧАСТОК 6":
	set(v): title = v; changed()
@export var subtitle := "ВВЕДЁН В ЭКСПЛУАТАЦИЮ":
	set(v): subtitle = v; changed()
@export var year := "2047":
	set(v): year = v; changed()
@export var size := Vector2(0.6, 0.42):
	set(v): size = v; changed()

func _build() -> void:
	var bronze := Color(0.55, 0.43, 0.25)
	Geo.box_node(gen, Vector3(size.x + 0.02, size.y + 0.02, 0.02), Tex.plain("bronze_dark", Color(0.3, 0.22, 0.12), 0.5, 0.7))
	Geo.plate(gen, [[title, 90], ["", 14], [subtitle, 44], [year, 110]], size, bronze, Color(0.13, 0.09, 0.05), Vector3(0, 0, 0.011))
	Geo.act_zone(gen, Vector3(size.x, size.y, 0.1), Vector3.ZERO, "plaque")
