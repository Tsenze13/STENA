@tool
## Ниша справа в коридоре: стены, пол, потолок, крашеная полоса. Щиток, пульт, записка и плакаты —
## отдельные узлы внутри (их можно двигать).
class_name Niche
extends LevelPart

func _build() -> void:
	piece("Niche")
	var nz0: float = World.NICHE[0]; var nz1: float = World.NICHE[1]; var nx := World.HW + 1.8; var nzc := (nz0 + nz1) / 2
	var NH := World.NICHE_H
	var conc := Tex.concrete()
	wall(Vector3(0.3, NH, 4.3), Vector3(nx + 0.15, NH / 2, nzc), conc)
	wall(Vector3(1.8, NH, 0.3), Vector3(World.HW + 0.9, NH / 2, nz0 + 0.15), conc)
	wall(Vector3(1.8, NH, 0.3), Vector3(World.HW + 0.9, NH / 2, nz1 - 0.15), conc)
	B.box(Vector3(0.02, 1.5, 4.0), Tex.paint_band(), Vector3(nx - 0.01, 0.75, nzc))
	wall(Vector3(1.8, 0.2, 4.3), Vector3(World.HW + 0.9, -0.1, nzc), Tex.floor_concrete())
	wall(Vector3(1.8, 0.2, 4.3), Vector3(World.HW + 0.9, NH + 0.1, nzc), Tex.ceiling(), false)
