@tool
## Пульт диспетчерской: металлическая тумба, встроенный янтарный монитор, клавиатура, телефон.
## Экран — SubViewport, его рисует терминал диспетчерской (dispatch_terminal.gd). Другая система, чем ЩИТ-80.
class_name DispatchConsole
extends LevelPart

var viewport: SubViewport
var screen: MeshInstance3D

func _build() -> void:
	viewport = SubViewport.new(); viewport.size = Vector2i(320, 240); viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	gen.add_child(viewport)
	var steel := Tex.metal("disp_steel", Color(0.32, 0.35, 0.33))
	var dark := Tex.plain("disp_dark", Color(0.1, 0.1, 0.1), 0.5)
	## стол-тумба и наклонная панель с монитором
	B.box(Vector3(1.6, 0.75, 0.8), steel, Vector3(0, 0.375, 0))
	B.box(Vector3(1.7, 0.05, 0.85), Tex.plain("disp_top", Color(0.25, 0.27, 0.25), 0.6), Vector3(0, 0.77, 0.02))
	B.box(Vector3(1.2, 0.7, 0.4), steel, Vector3(0, 1.15, -0.22), Vector3(-0.2, 0, 0))
	B.box(Vector3(0.62, 0.48, 0.02), dark, Vector3(0, 1.19, -0.005), Vector3(-0.2, 0, 0))
	var q := QuadMesh.new(); q.size = Vector2(0.52, 0.39)
	screen = MeshInstance3D.new(); screen.mesh = q
	var sm := StandardMaterial3D.new(); sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; sm.albedo_texture = viewport.get_texture()
	screen.material_override = sm; screen.position = Vector3(0, 1.19, 0.008); screen.rotation.x = -0.2; gen.add_child(screen)
	## ряд ламп-индикаторов и тумблеры
	for i in 8:
		B.cyl(0.012, 0.012, 0.01, Tex.plain("ind%d" % (i % 3), [Color(0.4, 0.1, 0.05), Color(0.35, 0.3, 0.05), Color(0.1, 0.3, 0.1)][i % 3], 0.4), Vector3(-0.5 + i * 0.05, 1.5, -0.12), Vector3(PI / 2 - 0.2, 0, 0), 8)
	for i in 6:
		B.box(Vector3(0.012, 0.04, 0.012), Tex.plain("toggle", Color(0.7, 0.7, 0.68), 0.3, 0.8), Vector3(0.3 + i * 0.05, 0.86, 0.25))
	## клавиатура
	B.box(Vector3(0.56, 0.03, 0.2), Tex.plain("disp_kb", Color(0.2, 0.21, 0.2), 0.6), Vector3(-0.15, 0.81, 0.18))
	for r in 3:
		for c in 12:
			B.box(Vector3(0.032, 0.012, 0.032), Tex.plain("disp_key", Color(0.55, 0.52, 0.45), 0.5), Vector3(-0.15 - 0.2 + c * 0.037, 0.832, 0.12 + r * 0.04))
	## дисковый телефон
	B.box(Vector3(0.2, 0.08, 0.16), Tex.plain("phone", Color(0.12, 0.12, 0.12), 0.35), Vector3(0.55, 0.83, 0.1))
	B.box(Vector3(0.22, 0.04, 0.05), Tex.plain("phone", Color(0.12, 0.12, 0.12), 0.35), Vector3(0.55, 0.89, 0.1))
	Geo.paint(gen, "АСУ «ДИСПЕТЧЕР-2»", 0.04, Color(0.85, 0.83, 0.76), Vector3(0, 1.5, -0.08), Vector3(-0.2, 0, 0), 0.15)
	Geo.solid(solids, Vector3(1.7, 1.5, 0.9), Vector3(0, 0.75, -0.05))
	Geo.act_zone(gen, Vector3(1.2, 0.8, 0.6), Vector3(0, 1.15, 0.0), "dispatch")
