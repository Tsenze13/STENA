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
	var pc := Geo.model(g, SKF % "terminal_small", Vector3(0, 0.5, 0), Vector3.ZERO, Vector3(0, 0.8, -0.04))
	## экран — ровно в стекло кинескопа (замерено по модели: центр x 0.04, y 1.165, стекло z ≈ 0.19)
	var sw := 0.29; var sh := 0.22
	var pm := QuadMesh.new(); pm.size = Vector2(sw, sh)
	var smat := StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.albedo_texture = screen_tex
	var screen := MeshInstance3D.new(); screen.mesh = pm; screen.material_override = smat
	screen.position = Vector3(0.042, 1.165, 0.196) if pc else Vector3(0.04, 1.1, 0.2)
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
		## корпус — закрытый электрошкаф (Poly Haven power_box_01, CC0): дверца закрыта, внутрь смотрят крупным планом
		var H := 0.8; var D := 0.16
		var box := Geo.model(node, "res://assets/models/power_box_01/power_box_01_1k.gltf", Vector3(0, H, 0), Vector3.ZERO, Vector3(0, -H / 2, -0.02))
		if box:
			for dn: Node in box.find_children("*door*", "Node3D", true, false): (dn as Node3D).quaternion = Quaternion.IDENTITY
		else:
			Geo.box_node(node, Vector3(0.56, H, D), Tex.metal("panel", Color(0.45, 0.48, 0.44)), Vector3(0, 0, -0.02))
		Geo.paint(node, "ЩР-6", 0.09, Color(0.9, 0.8, 0.2), Vector3(0, H / 2 + 0.1, -0.09), Vector3.ZERO, 0.2)
		## рычажки — только состояние (сами автоматы видно в щитке крупным планом)
		for k in ["qf0", "qf1", "qf2"]:
			levers[k] = Node3D.new(); node.add_child(levers[k])
		## две лампы на дверце: «сеть» и «напряжение на линии»
		lamp_main = Geo.cyl_node(node, 0.016, 0.016, 0.02, Tex.glow("lamp_off", Color(0.25, 0.06, 0.05)), Vector3(-0.06, H / 2 - 0.1, D / 2 - 0.01), Vector3(PI / 2, 0, 0), 12)
		lamp_v = Geo.cyl_node(node, 0.016, 0.016, 0.02, Tex.glow("lamp_off", Color(0.25, 0.06, 0.05)), Vector3(0.06, H / 2 - 0.1, D / 2 - 0.01), Vector3(PI / 2, 0, 0), 12)
		node.add_child(needle)

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
## створка гермодвери без рамы, выпрямленная (вырезана из модели metal_door)
const DOOR_LEAF := "res://assets/sketchfab/metal_door/leaf.gltf"
## калитка из сетки-рабицы (Poly Haven modular_chainlink_fence, CC0)
const MESH_GATE := "res://assets/models/modular_chainlink_fence/modular_chainlink_fence_1k.gltf"

## стальной уголок-рама вокруг проёма
static func _frame(g: Node3D, w: float, h: float, d: float) -> void:
	var m := Tex.dark_metal()
	Geo.box_node(g, Vector3(0.07, h + 0.07, d), m, Vector3(-w / 2 - 0.035, (h + 0.07) / 2, d / 2))
	Geo.box_node(g, Vector3(0.07, h + 0.07, d), m, Vector3(w / 2 + 0.035, (h + 0.07) / 2, d / 2))
	Geo.box_node(g, Vector3(w + 0.14, 0.07, d), m, Vector3(0, h + 0.035, d / 2))

static func door(type: String, label_text: String, lit: bool) -> Node3D:
	var g := Node3D.new()
	var w := 1.1; var h := 2.15
	if type == "hermetic":
		w = 1.3; h = 2.1
		Geo.model(g, DOOR_LEAF, Vector3(w, h, 0.14), Vector3.ZERO, Vector3(0, 0, 0.07))
		_frame(g, w, h, 0.12)
	elif type == "cage":
		Geo.model(g, MESH_GATE, Vector3(w, h, 0.05), Vector3.ZERO, Vector3(0, 0, 0.03), "door_gate")
		_frame(g, w, h, 0.08)
		Geo.box_node(g, Vector3(w, h, 0.02), Tex.plain("void", Color(0, 0, 0), 1.0), Vector3(0, h / 2, -0.12))
	else:
		Geo.model(g, DOOR_LEAF, Vector3(w, h, 0.08), Vector3.ZERO, Vector3(0, 0, 0.04))
		_frame(g, w, h, 0.08)
	## надпись краской — прямо на стене над дверью (начало двери = плоскость стены)
	Geo.paint(g, label_text, 0.17, Color(0.85, 0.83, 0.76), Vector3(0, h + 0.34, 0.012), Vector3.ZERO, 0.35)
	Geo.cyl_node(g, 0.045, 0.045, 0.04, Tex.glow("door_lamp_on", Color(1, 0.16, 0.1), 3.0) if lit else Tex.plain("door_lamp", Color(0.17, 0.05, 0.03), 0.4), Vector3(w / 2 + 0.2, h - 0.05, 0.03), Vector3(PI / 2, 0, 0), 10)
	Geo.act_zone(g, Vector3(w, h, 0.3), Vector3(0, h / 2, 0.05), "locked", label_text)
	return g
