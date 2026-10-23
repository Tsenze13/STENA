@tool
## Модели: пульт с терминалом, щиток ЩР-6, двери. Каждая строится лицом к +Z в своём узле;
## узел потом ставят к стене и поворачивают.
class_name Props
extends RefCounted

## ================= ПУЛЬТ С ТЕРМИНАЛОМ =================
## screen_tex — текстура экрана (из SubViewport терминала)
static func console(screen_tex: Texture2D) -> Dictionary:
	var g := Node3D.new()
	## стол (Poly Haven metal_office_desk) и старый компьютер с клавиатурой (Sketchfab, CC BY)
	var desk := Geo.model(g, "res://assets/models/metal_office_desk/metal_office_desk_1k.gltf", Vector3(1.4, 0.8, 0.7), Vector3.ZERO, Vector3(0, 0, 0))
	var pc := Geo.model(g, SKF % "terminal_small", Vector3(0, 0.5, 0), Vector3.ZERO, Vector3(0, 0.8, 0.02))
	## экран: на передней грани монитора (часть модели pack_2)
	var mon := AABB(Vector3(-0.2, 0.8, -0.2), Vector3(0.45, 0.5, 0.6))
	if pc:
		for mi in pc.find_children("*pack_2*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			mon = (g.global_transform.affine_inverse() * m.global_transform) * m.mesh.get_aabb() if m.is_inside_tree() else _aabb_in(g, m)
	var sw := mon.size.x * 0.62; var sh := sw * 0.75
	var pm := QuadMesh.new(); pm.size = Vector2(sw, sh)
	var smat := StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.albedo_texture = screen_tex
	var screen := MeshInstance3D.new(); screen.mesh = pm; screen.material_override = smat
	screen.position = Vector3(mon.get_center().x, mon.end.y - sh * 0.5 - mon.size.y * 0.12, mon.end.z + 0.004)
	g.add_child(screen)
	var led := Geo.cyl_node(g, 0.008, 0.008, 0.01, Tex.glow("led_off", Color(0.2, 0.05, 0.05)), screen.position + Vector3(sw * 0.45, -sh * 0.62, 0.002), Vector3(PI / 2, 0, 0), 8)
	return {"node": g, "screen": screen, "led": led}

## AABB меша в системе узла root (без дерева сцены)
static func _aabb_in(root: Node3D, m: MeshInstance3D) -> AABB:
	var xf := m.transform
	var p := m.get_parent()
	while p and p != root:
		if p is Node3D: xf = (p as Node3D).transform * xf
		p = p.get_parent()
	return xf * m.mesh.get_aabb()

## ================= ЩИТОК ЩР-6 =================
class PanelModel:
	var node := Node3D.new()
	var levers := {}
	var lamp_main: MeshInstance3D
	var lamp_v: MeshInstance3D
	var needle := Node3D.new()
	var ang := -80.0

	func _init() -> void:
		var grey := Tex.metal("panel", Color(0.45, 0.48, 0.44))
		var inside := Tex.plain("panel_in", Color(0.35, 0.37, 0.34), 0.7, 0.2)
		var W := 0.72; var H := 0.95; var D := 0.2
		## корпус — модель (Sketchfab «Electrical Breaker Panel Box», CC BY); внутри наши рабочие автоматы, лампы, амперметр
		if Geo.model(node, SKF % "breaker_panel", Vector3(W, H, D), Vector3.ZERO, Vector3(0, -H / 2, 0)) == null:
			Geo.box_node(node, Vector3(W, H, 0.02), inside, Vector3(0, 0, -D / 2 + 0.01))
			for p in [[Vector3(0.02, H, D), Vector3(-W / 2, 0, 0)], [Vector3(0.02, H, D), Vector3(W / 2, 0, 0)], [Vector3(W, 0.02, D), Vector3(0, H / 2, 0)], [Vector3(W, 0.02, D), Vector3(0, -H / 2, 0)]]:
				Geo.box_node(node, p[0], grey, p[1])
		Geo.label(node, "ЩР-6", 64, Color(0.9, 0.8, 0.2), Vector3(0, H / 2 + 0.06, D / 2), Vector3.ZERO, 0.0025)
		## DIN-рейка и автоматы
		Geo.box_node(node, Vector3(W - 0.1, 0.03, 0.01), Tex.plain("din", Color(0.7, 0.7, 0.7), 0.3, 0.8), Vector3(0, -0.12, -D / 2 + 0.03))
		var bm := Tex.plain("brk", Color(0.88, 0.86, 0.8), 0.5)
		var lever_m := Tex.plain("lever", Color(0.08, 0.08, 0.08), 0.4)
		for b in [["qf0", -0.2, 0.1], ["qf1", 0.0, 0.07], ["qf2", 0.12, 0.07]]:
			Geo.box_node(node, Vector3(b[2], 0.14, 0.09), Tex.plain("brk0", Color(0.94, 0.86, 0.66), 0.5) if b[0] == "qf0" else bm, Vector3(b[1], -0.12, -D / 2 + 0.07))
			levers[b[0]] = Geo.box_node(node, Vector3(b[2] * 0.45, 0.04, 0.03), lever_m, Vector3(b[1], -0.1, -D / 2 + 0.125))
			Geo.label(node, str(b[0]).to_upper(), 40, Color(0.1, 0.1, 0.1), Vector3(b[1], -0.215, -D / 2 + 0.116), Vector3.ZERO, 0.0012)
		Geo.box_node(node, Vector3(0.1, 0.12, 0.1), Tex.plain("km", Color(0.22, 0.23, 0.22)), Vector3(0.26, -0.12, -D / 2 + 0.07))
		lamp_main = Geo.cyl_node(node, 0.018, 0.018, 0.02, Tex.glow("lamp_off", Color(0.25, 0.06, 0.05)), Vector3(-0.2, 0.06, -D / 2 + 0.06), Vector3(PI / 2, 0, 0), 12)
		lamp_v = Geo.cyl_node(node, 0.018, 0.018, 0.02, Tex.glow("lamp_off", Color(0.25, 0.06, 0.05)), Vector3(0.26, 0.0, -D / 2 + 0.06), Vector3(PI / 2, 0, 0), 12)
		## амперметр: циферблат, шкала, стрелка
		Geo.cyl_node(node, 0.08, 0.08, 0.04, Tex.plain("amm_body", Color(0.12, 0.12, 0.12)), Vector3(0.05, 0.22, -D / 2 + 0.04), Vector3(PI / 2, 0, 0), 24)
		Geo.cyl_node(node, 0.07, 0.07, 0.002, Tex.plain("amm_face", Color(0.9, 0.88, 0.8), 0.4), Vector3(0.05, 0.22, -D / 2 + 0.061), Vector3(PI / 2, 0, 0), 24)
		for a in range(0, 31, 5):
			var t := deg_to_rad(-80.0 + 160.0 * a / 30.0)
			var tick := Geo.box_node(node, Vector3(0.002, 0.012, 0.001), Tex.plain("tick_r" if a > 20 else "tick", Color(0.7, 0.1, 0.1) if a > 20 else Color(0.1, 0.1, 0.1)), Vector3(0.05 + sin(t) * 0.052, 0.207 + cos(t) * 0.052, -D / 2 + 0.063))
			tick.rotation.z = -t
		needle.position = Vector3(0.05, 0.207, -D / 2 + 0.064); node.add_child(needle)
		Geo.box_node(needle, Vector3(0.003, 0.06, 0.002), Tex.plain("needle", Color(0.05, 0.05, 0.05)), Vector3(0, 0.03, 0))

	## отразить на модели автоматы, лампы и нагрузку
	func update(s: Dictionary, ld: float, dt: float) -> void:
		for k in ["qf0", "qf1", "qf2"]:
			var ty := -0.09 if s[k] else -0.15
			levers[k].position.y += (ty - levers[k].position.y) * min(1.0, dt * 18.0)
		lamp_main.material_override = Tex.glow("lamp_on", Color(1.0, 0.2, 0.12), 3.0) if s.qf0 else Tex.glow("lamp_off", Color(0.25, 0.06, 0.05))
		lamp_v.material_override = Tex.glow("lamp_on", Color(1.0, 0.2, 0.12), 3.0) if s.v else Tex.glow("lamp_off", Color(0.25, 0.06, 0.05))
		var target := -80.0 + 160.0 * minf(ld, 30.0) / 30.0
		ang += (target - ang) * min(1.0, dt * 5.0)
		needle.rotation.z = -deg_to_rad(ang)

## ================= ДВЕРИ =================
## модели дверей (Sketchfab, CC BY — авторы в docs/CREDITS.md)
const SKF := "res://assets/sketchfab/%s/scene.gltf"

static func door(type: String, label_text: String, lit: bool) -> Node3D:
	var g := Node3D.new()
	var w := 1.1; var h := 2.15
	if type == "hermetic":
		w = 1.3; h = 2.1
		Geo.model(g, SKF % "metal_door", Vector3(w + 0.36, h + 0.3, 0.3))
	elif type == "cage":
		Geo.model(g, SKF % "cell_door", Vector3(w, h, 0.12))
		Geo.box_node(g, Vector3(w, h, 0.02), Tex.plain("void", Color(0, 0, 0), 1.0), Vector3(0, h / 2, -0.12))
	else:
		Geo.model(g, SKF % "metal_door", Vector3(w + 0.16, h + 0.08, 0.14))
	## надпись краской — прямо на стене над дверью (начало двери = плоскость стены)
	Geo.paint(g, label_text, 0.17, Color(0.85, 0.83, 0.76), Vector3(0, h + 0.34, 0.012), Vector3.ZERO, 0.35)
	Geo.cyl_node(g, 0.045, 0.045, 0.04, Tex.glow("door_lamp_on", Color(1, 0.16, 0.1), 3.0) if lit else Tex.plain("door_lamp", Color(0.17, 0.05, 0.03), 0.4), Vector3(w / 2 + 0.2, h - 0.05, 0.03), Vector3(PI / 2, 0, 0), 10)
	Geo.act_zone(g, Vector3(w, h, 0.3), Vector3(0, h / 2, 0.05), "locked", label_text)
	return g
