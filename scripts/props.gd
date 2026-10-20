@tool
## Модели: пульт с терминалом, щиток ЩР-6, двери. Каждая строится лицом к +Z в своём узле;
## узел потом ставят к стене и поворачивают.
class_name Props
extends RefCounted

## ================= ПУЛЬТ С ТЕРМИНАЛОМ =================
## screen_tex — текстура экрана (из SubViewport терминала)
static func console(screen_tex: Texture2D) -> Dictionary:
	var g := Node3D.new()
	var steel := Tex.metal("steel", Color(0.25, 0.26, 0.24))
	var beige := Tex.plain("beige", Color(0.75, 0.72, 0.62), 0.6)
	var dark := Tex.plain("dark_plastic", Color(0.12, 0.12, 0.11), 0.5)
	Geo.box_node(g, Vector3(1.3, 0.92, 0.62), steel, Vector3(0, 0.46, -0.04))
	Geo.box_node(g, Vector3(1.36, 0.05, 0.72), Tex.surface("desk", Color(0.36, 0.29, 0.22), 0.7, 0.0, 2.0), Vector3(0, 0.95, 0), Vector3(0.06, 0, 0))
	var cols := [Color(0.7, 0.2, 0.2), Color(0.2, 0.6, 0.2), Color(0.85, 0.8, 0.2), Color(0.85, 0.85, 0.85), Color(0.2, 0.4, 0.8)]
	for i in 5:
		Geo.cyl_node(g, 0.018, 0.018, 0.02, Tex.plain("btn%d" % i, cols[i], 0.4), Vector3(-0.45 + i * 0.07, 0.8, 0.28), Vector3(PI / 2, 0, 0), 10)
	## корпус кинескопа
	var crt := Node3D.new(); crt.position = Vector3(0.05, 1.2, -0.02); g.add_child(crt)
	Geo.box_node(crt, Vector3(0.5, 0.42, 0.3), beige, Vector3(0, 0, 0.02))
	var back := Geo.cyl_node(crt, 0.12, 0.2, 0.28, beige, Vector3(0, 0, -0.25), Vector3(-PI / 2, 0, 0), 4)
	back.rotation.y = PI / 4
	Geo.box_node(crt, Vector3(0.42, 0.33, 0.03), dark, Vector3(0, 0.01, 0.17))
	## выпуклое стекло экрана: плоскость, выгнутая к зрителю
	var pm := PlaneMesh.new(); pm.size = Vector2(0.36, 0.27); pm.subdivide_width = 16; pm.subdivide_depth = 12
	pm.orientation = PlaneMesh.FACE_Z
	var arr := pm.get_mesh_arrays()
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	for i in v.size():
		var x := v[i].x / 0.18
		var y := v[i].y / 0.135
		v[i].z = 0.022 * (1.0 - x * x * 0.6) * (1.0 - y * y * 0.6)
	arr[Mesh.ARRAY_VERTEX] = v
	var sm := ArrayMesh.new(); sm.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var smat := StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.albedo_texture = screen_tex
	var screen := MeshInstance3D.new(); screen.mesh = sm; screen.material_override = smat; screen.position = Vector3(0, 0.012, 0.18); crt.add_child(screen)
	var glass := StandardMaterial3D.new(); glass.albedo_color = Color(0, 0, 0, 0.15); glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; glass.roughness = 0.05; glass.metallic = 0.5
	var gl := MeshInstance3D.new(); gl.mesh = sm; gl.material_override = glass; gl.position = Vector3(0, 0.012, 0.184); crt.add_child(gl)
	var led := Geo.cyl_node(crt, 0.008, 0.008, 0.01, Tex.glow("led_off", Color(0.2, 0.05, 0.05)), Vector3(0.19, -0.18, 0.18), Vector3(PI / 2, 0, 0), 8)
	for i in 2:
		Geo.cyl_node(crt, 0.014, 0.014, 0.02, dark, Vector3(0.13 - i * 0.05, -0.18, 0.18), Vector3(PI / 2, 0, 0), 12)
	## клавиатура с клавишами
	var kb := Node3D.new(); kb.position = Vector3(0.02, 0.99, 0.2); kb.rotation.x = 0.12; g.add_child(kb)
	Geo.box_node(kb, Vector3(0.52, 0.035, 0.18), beige)
	var keym := Tex.plain("key", Color(0.54, 0.51, 0.44), 0.5)
	var keyd := Tex.plain("keyd", Color(0.29, 0.27, 0.24), 0.5)
	for r in 4:
		for c in 13:
			Geo.box_node(kb, Vector3(0.03, 0.014, 0.03), keyd if (c > 10 or r == 0) else keym, Vector3(-0.225 + c * 0.0375 + r * 0.008, 0.024, -0.06 + r * 0.037))
	Geo.box_node(kb, Vector3(0.24, 0.014, 0.03), keym, Vector3(-0.02, 0.024, 0.088))
	## кабель от пульта вверх к кабель-каналу
	var cm := MeshInstance3D.new()
	cm.mesh = Geo.tube(Geo.catenary(Vector3(-0.4, 0.3, -0.33), Vector3(-0.55, 2.6, -0.33), 0.25, 12), 0.018)
	cm.material_override = Tex.cable(); g.add_child(cm)
	return {"node": g, "screen": screen, "led": led}

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
		Geo.box_node(node, Vector3(W, H, 0.02), inside, Vector3(0, 0, -D / 2 + 0.01))
		for p in [[Vector3(0.02, H, D), Vector3(-W / 2, 0, 0)], [Vector3(0.02, H, D), Vector3(W / 2, 0, 0)], [Vector3(W, 0.02, D), Vector3(0, H / 2, 0)], [Vector3(W, 0.02, D), Vector3(0, -H / 2, 0)]]:
			Geo.box_node(node, p[0], grey, p[1])
		## дверца на петлях, открыта
		var hinge := Node3D.new(); hinge.position = Vector3(-W / 2, 0, D / 2); node.add_child(hinge)
		Geo.box_node(hinge, Vector3(W, H, 0.02), grey, Vector3(W / 2, 0, 0))
		Geo.label(hinge, "ЩР-6", 64, Color(0.9, 0.8, 0.2), Vector3(W / 2, 0.36, 0.012), Vector3.ZERO, 0.0025)
		Geo.box_node(hinge, Vector3(0.16, 0.19, 0.004), Tex.plain("warn", Color(0.9, 0.75, 0.1), 0.6), Vector3(W / 2, 0.1, -0.012))
		hinge.rotation.y = -1.9
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
		## провода из щитка вверх
		for i in 4:
			Geo.cyl_node(node, 0.012, 0.012, 1.4, Tex.cable(), Vector3(-0.25 + i * 0.07, H / 2 + 0.7, -0.02), Vector3.ZERO, 6)

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
static func door(type: String, label_text: String, lit: bool) -> Node3D:
	var g := Node3D.new()
	var frame := Tex.dark_metal()
	var w := 1.1; var h := 2.15
	if type == "hermetic":
		w = 1.3; h = 2.1
		Geo.box_node(g, Vector3(w + 0.36, h + 0.36, 0.25), frame, Vector3(0, h / 2 + 0.05, -0.08))
		Geo.box_node(g, Vector3(w, h, 0.16), Tex.metal("herm", Color(0.28, 0.33, 0.3)), Vector3(0, h / 2 + 0.05, 0.04))
		var wheel := MeshInstance3D.new(); var tm := TorusMesh.new(); tm.inner_radius = 0.17; tm.outer_radius = 0.22; wheel.mesh = tm
		wheel.material_override = Tex.plain("wheel", Color(0.45, 0.15, 0.1), 0.4, 0.6); wheel.position = Vector3(0, 1.15, 0.16); wheel.rotation.x = PI / 2; g.add_child(wheel)
		for i in 3:
			Geo.box_node(g, Vector3(0.4, 0.025, 0.025), wheel.material_override, Vector3(0, 1.15, 0.16), Vector3(0, 0, i * PI / 3))
		for i in 12:
			var a := TAU * i / 12
			Geo.cyl_node(g, 0.03, 0.03, 0.04, frame, Vector3(cos(a) * (w / 2 + 0.08), h / 2 + 0.05 + sin(a) * (h / 2 + 0.08) * 0.95, 0.06), Vector3(PI / 2, 0, 0), 8)
		Geo.box_node(g, Vector3(w + 0.3, 0.12, 0.01), Tex.hazard(), Vector3(0, 0.06, 0.06))
	elif type == "cage":
		Geo.box_node(g, Vector3(w + 0.1, 0.06, 0.06), frame, Vector3(0, h, 0))
		for x in [-w / 2, w / 2]:
			Geo.box_node(g, Vector3(0.06, h, 0.06), frame, Vector3(x, h / 2, 0))
		var x := -w / 2 + 0.1
		while x < w / 2:
			Geo.cyl_node(g, 0.012, 0.012, h - 0.1, frame, Vector3(x, h / 2, 0), Vector3.ZERO, 5)
			x += 0.11
		for y in [0.3, 1.1, 1.9]:
			Geo.box_node(g, Vector3(w, 0.03, 0.03), frame, Vector3(0, y, 0))
		Geo.box_node(g, Vector3(w, h, 0.02), Tex.plain("void", Color(0, 0, 0), 1.0), Vector3(0, h / 2, -0.12))
	else:
		Geo.box_node(g, Vector3(w + 0.16, 0.08, 0.14), frame, Vector3(0, h + 0.04, 0))
		for x in [-w / 2 - 0.04, w / 2 + 0.04]:
			Geo.box_node(g, Vector3(0.08, h, 0.14), frame, Vector3(x, h / 2, 0))
		var cols := [Color(0.35, 0.24, 0.17), Color(0.24, 0.29, 0.32), Color(0.36, 0.35, 0.23), Color(0.29, 0.18, 0.18)]
		var ci := hash(label_text) % 4
		Geo.box_node(g, Vector3(w, h, 0.05), Tex.metal("svc%d" % ci, cols[ci]), Vector3(0, h / 2, 0.01))
		Geo.box_node(g, Vector3(0.04, 0.16, 0.05), Tex.plain("handle", Color(0.55, 0.52, 0.48), 0.35, 0.8), Vector3(w / 2 - 0.12, 1.0, 0.06))
	Geo.paint(g, label_text, 0.17, Color(0.85, 0.83, 0.76), Vector3(0, h + 0.34, 0.081), Vector3.ZERO, 0.35)
	Geo.cyl_node(g, 0.045, 0.045, 0.04, Tex.glow("door_lamp_on", Color(1, 0.16, 0.1), 3.0) if lit else Tex.plain("door_lamp", Color(0.17, 0.05, 0.03), 0.4), Vector3(0.45, h + 0.34, 0.09), Vector3(PI / 2, 0, 0), 10)
	Geo.act_zone(g, Vector3(w, h, 0.3), Vector3(0, h / 2, 0.05), "locked", label_text)
	return g
