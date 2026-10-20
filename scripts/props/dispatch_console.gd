@tool
## Пульт диспетчерской: стол и старый компьютер (модели), янтарный экран.
## Экран — SubViewport, его рисует терминал диспетчерской (dispatch_terminal.gd). Другая система, чем ЩИТ-80.
class_name DispatchConsole
extends LevelPart

var viewport: SubViewport
var screen: MeshInstance3D

func _build() -> void:
	viewport = SubViewport.new(); viewport.size = Vector2i(320, 240); viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	gen.add_child(viewport)
	## стол и старый компьютер — модели (как у пульта ЩИТ-80), экран — живой SubViewport
	var d := Props.console(viewport.get_texture())
	gen.add_child(d.node); screen = d.screen
	Geo.paint(gen, "АСУ «ДИСПЕТЧЕР-2»", 0.04, Color(0.85, 0.83, 0.76), Vector3(0, 0.79, 0.36), Vector3.ZERO, 0.15)
	Geo.solid(solids, Vector3(1.7, 1.5, 0.9), Vector3(0, 0.75, -0.05))
	Geo.act_zone(gen, Vector3(1.2, 0.8, 0.6), Vector3(0, 1.15, 0.0), "dispatch")
