## Руки от первого лица: «замораживает» предплечья и кисти модели Sketchfab «Fists (2023)» (1Matzh, CC BY;
## перчатки и рукава, поза из анимации Idle — сжатые кулаки) в цельные модели без костей и собирает сцену scenes/player/fp_arms.tscn:
##   Right/Arm, Right/Flashlight, Right/Tip — правая рука с фонариком (Tip — откуда бьёт луч)
##   Left/Arm, Left/PT1 — левая рука и место прибора ПТ-1
##   Poses/R_rest, R_reach, R_run, R_low, L_rest, L_raised — позы рук (двигай метки в редакторе)
##   godot --headless --path . res://tests/bake_arms.tscn
## Повторный запуск перезапишет сцену рук (ручные правки в ней пропадут).
extends Node

const GLOVE := Color(0.36, 0.25, 0.15)
const CLOTH := Color(0.16, 0.21, 0.3)
const HAND_R := Basis(Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 1, 0))
const HAND_L := Basis(Vector3(-1, 0, 0), Vector3(0, 0, -1), Vector3(0, -1, 0))
const SC := 1.0
const POSE_T := 1.0
## отверстие правого кулака в пространстве камеры модели (между основаниями указательного и мизинца, ближе к ладони)
const FIST_R := Vector3(0.088, -0.07, -0.255)

const SRC := "res://assets/sketchfab/fists/scene.gltf"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/arms")
	DirAccess.make_dir_recursive_absolute("res://scenes/player")
	var man: Node3D = load(SRC).instantiate()
	add_child(man)
	var ap: AnimationPlayer = man.find_children("*", "AnimationPlayer", true, false)[0]
	ap.play("rig|Idle"); ap.seek(POSE_T, true)
	await get_tree().process_frame
	var sk: Skeleton3D = man.find_children("*", "Skeleton3D", true, false)[0]
	var mis: Array = []
	for n in man.find_children("*", "MeshInstance3D", true, false):
		if (n as MeshInstance3D).skin: mis.append(n)
	## правая рука — ровно в повороте из анимации (как её видит камера модели), точка отсчёта — отверстие кулака;
	## левая — в системе кисти (позы L_* под неё)
	var camn: Node3D = man.find_child("Camera", true, false)
	var cam_inv := Transform3D(Basis.looking_at(Vector3(0, 0, 1)), camn.global_position).affine_inverse()
	for s in ["R", "L"]:
		var to_local: Transform3D
		if s == "R": to_local = Transform3D(Basis(), -FIST_R) * cam_inv * sk.global_transform
		else: to_local = sk.get_bone_global_pose(_bone(sk, "DEF-hand.L")).affine_inverse()
		var m := _bake(sk, mis, s, to_local)
		ResourceSaver.save(m, "res://assets/arms/arm_%s.res" % s.to_lower())
	## сцена рук
	var root := Node3D.new(); root.name = "FPArms"
	var right := Node3D.new(); right.name = "Right"; root.add_child(right)
	var left := Node3D.new(); left.name = "Left"; root.add_child(left)
	var ar := MeshInstance3D.new(); ar.name = "Arm"; ar.mesh = load("res://assets/arms/arm_r.res")
	ar.transform = Transform3D.IDENTITY
	right.add_child(ar)
	## фонарик — модель Sketchfab «Flashlight» (gluma, CC BY): металлический цилиндр; в файле стоит головой вверх — кладём вперёд.
	## height — это диаметр (после поворота), длина ≈ 3 диаметра
	var fl := ModelProp.new(); fl.name = "Flashlight"
	fl.model = load("res://assets/sketchfab/torch/scene.gltf")
	fl.model_rotation = Vector3(-90, 0, 0); fl.height = 0.05; fl.on_ground = true; fl.collide = false; fl.viewmodel = true
	fl.position = Vector3(0.0, -0.025, -0.04); right.add_child(fl)
	var tip := Marker3D.new(); tip.name = "Tip"; tip.position = Vector3(0.0, 0.0, -0.125); right.add_child(tip)
	var al := MeshInstance3D.new(); al.name = "Arm"; al.mesh = load("res://assets/arms/arm_l.res")
	al.transform = Transform3D((HAND_L * Basis(Vector3.UP, PI)).scaled(Vector3.ONE * SC), Vector3(0, 0, -0.29))
	left.add_child(al)
	var pt := Marker3D.new(); pt.name = "PT1"; pt.position = Vector3(0, 0.06, -0.17); left.add_child(pt)
	var poses := Node3D.new(); poses.name = "Poses"; root.add_child(poses)
	var raised_b := Basis(Vector3.RIGHT, -0.3) * Basis(Vector3(0, -1, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0))
	for p in [["R_rest", Vector3(0.15, -0.2, -0.38), Basis.from_euler(Vector3(0.0, 0.12, 0.0), EULER_ORDER_YXZ)],
			["R_reach", Vector3(0.1, -0.15, -0.48), Basis.from_euler(Vector3(0.08, 0.08, 0.0), EULER_ORDER_YXZ)],
			["R_run", Vector3(0.19, -0.23, -0.38), Basis.from_euler(Vector3(-0.35, 0.4, -0.45), EULER_ORDER_YXZ)],
			["R_low", Vector3(0.2, -0.55, -0.3), Basis.from_euler(Vector3(-0.6, 0.2, 0), EULER_ORDER_YXZ)],
			["L_rest", Vector3(-0.3, -0.55, -0.2), Basis.from_euler(Vector3(0.1, -0.25, 0.2), EULER_ORDER_YXZ)],
			["L_raised", Vector3(-0.1, -0.13, -0.52), raised_b]]:
		var mk := Marker3D.new(); mk.name = p[0]; mk.transform = Transform3D(p[2], p[1]); poses.add_child(mk)
	right.transform = poses.get_node("R_rest").transform
	left.transform = poses.get_node("L_rest").transform
	var cam := Camera3D.new(); cam.name = "PreviewCamera"; cam.fov = 75; root.add_child(cam)   # вид как в игре
	for n in root.get_children(): _own(n, root)
	var ps := PackedScene.new(); ps.pack(root)
	print("сцена рук: ", error_string(ResourceSaver.save(ps, "res://scenes/player/fp_arms.tscn")))
	get_tree().quit()

func _own(n: Node, r: Node) -> void:
	if n.scene_file_path == "" or n == r:
		pass
	n.owner = r
	if n.scene_file_path != "": return      # вложенная модель (фонарик) — её детали не наши
	for c in n.get_children(): _own(c, r)

func _bone(sk: Skeleton3D, prefix: String) -> int:
	for i in sk.get_bone_count():
		if sk.get_bone_name(i).begins_with(prefix + "_") or sk.get_bone_name(i) == prefix: return i
	return -1

## предплечье и кисть стороны s: вершины по позе скелета, в системе координат кисти; материалы модели (+ z-clip)
func _bake(sk: Skeleton3D, mis: Array, s: String, hand_inv: Transform3D) -> ArrayMesh:
	var out := ArrayMesh.new()
	for mi: MeshInstance3D in mis:
		var skin := mi.skin
		var bind_xf := []; var bind_grp := []
		for i in skin.get_bind_count():
			var bn := skin.get_bind_name(i)
			var b := sk.find_bone(bn) if bn != "" else skin.get_bind_bone(i)
			bn = sk.get_bone_name(b)
			bind_xf.append(sk.get_bone_global_pose(b) * skin.get_bind_pose(i))
			var g := 0
			if bn.contains("." + s + "_") or bn.ends_with("." + s) or bn.contains("." + s + "."):
				if bn.begins_with("DEF-forearm"): g = 1
				elif bn.begins_with("DEF-hand") or bn.begins_with("DEF-f_") or bn.begins_with("DEF-thumb") or bn.begins_with("DEF-palm"): g = 2
			bind_grp.append(g)
		for si in mi.mesh.get_surface_count():
			var a := mi.mesh.surface_get_arrays(si)
			var V: PackedVector3Array = a[Mesh.ARRAY_VERTEX]; var N: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
			var T = a[Mesh.ARRAY_TANGENT]; var UV = a[Mesh.ARRAY_TEX_UV]
			var BI: PackedInt32Array = a[Mesh.ARRAY_BONES]; var BW: PackedFloat32Array = a[Mesh.ARRAY_WEIGHTS]
			var stride := BI.size() / V.size()
			var IDX: PackedInt32Array = a[Mesh.ARRAY_INDEX] if a[Mesh.ARRAY_INDEX] != null else PackedInt32Array(range(V.size()))
			var pv := PackedVector3Array(); pv.resize(V.size())
			var pn := PackedVector3Array(); pn.resize(V.size())
			var pt := PackedFloat32Array(); if T != null: pt.resize(V.size() * 4)
			var grp := PackedInt32Array(); grp.resize(V.size())
			for v in V.size():
				var p := Vector3.ZERO; var n := Vector3.ZERO; var tg := Vector3.ZERO; var best := -1.0; var bg := 0
				var tv := Vector3(T[v * 4], T[v * 4 + 1], T[v * 4 + 2]) if T != null else Vector3.ZERO
				for k in stride:
					var w := BW[v * stride + k]
					if w <= 0.0: continue
					var bi := BI[v * stride + k]
					var xf: Transform3D = bind_xf[bi]
					p += (xf * V[v]) * w; n += (xf.basis * N[v]) * w; tg += (xf.basis * tv) * w
					if w > best: best = w; bg = bind_grp[bi]
				pv[v] = hand_inv * p; pn[v] = (hand_inv.basis * n).normalized(); grp[v] = bg
				if T != null:
					var t2 := (hand_inv.basis * tg).normalized()
					pt[v * 4] = t2.x; pt[v * 4 + 1] = t2.y; pt[v * 4 + 2] = t2.z; pt[v * 4 + 3] = T[v * 4 + 3]
			## треугольники, все вершины которых — предплечье/кисть этой стороны
			var keep := PackedInt32Array()
			var i := 0
			while i < IDX.size():
				if grp[IDX[i]] != 0 and grp[IDX[i + 1]] != 0 and grp[IDX[i + 2]] != 0:
					keep.append(IDX[i]); keep.append(IDX[i + 1]); keep.append(IDX[i + 2])
				i += 3
			if keep.is_empty(): continue
			var arr := []; arr.resize(Mesh.ARRAY_MAX)
			arr[Mesh.ARRAY_VERTEX] = pv; arr[Mesh.ARRAY_NORMAL] = pn; arr[Mesh.ARRAY_INDEX] = keep
			if T != null: arr[Mesh.ARRAY_TANGENT] = pt
			if UV != null: arr[Mesh.ARRAY_TEX_UV] = UV
			out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
			var mat = mi.get_active_material(si)
			if mat is BaseMaterial3D:
				var c: BaseMaterial3D = mat.duplicate(); c.use_z_clip_scale = true; c.z_clip_scale = 0.12
				c.emission_enabled = false
				out.surface_set_material(out.get_surface_count() - 1, c)
	return out
