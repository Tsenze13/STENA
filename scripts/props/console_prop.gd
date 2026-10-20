@tool
## Пульт дежурного с терминалом ЩИТ-80. Экран — живой SubViewport: его рисует terminal.gd.
class_name ConsoleProp
extends LevelPart

var viewport: SubViewport
var data := {}

func _build() -> void:
	viewport = SubViewport.new(); viewport.size = Vector2i(320, 240); viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	gen.add_child(viewport)
	data = Props.console(viewport.get_texture())
	gen.add_child(data.node)
	Geo.act_zone(gen, Vector3(1.3, 0.8, 0.8), Vector3(0, 1.2, 0), "terminal")
	Geo.solid(solids, Vector3(1.5, 1.2, 0.75), Vector3(0, 0.6, -0.01))
