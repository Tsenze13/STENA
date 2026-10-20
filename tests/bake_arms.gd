## Руки от первого лица: «замораживает» предплечья и кисти манекена Quaternius в позе (правая — кулак,
## левая — расслабленная) в цельные модели без костей и собирает сцену scenes/player/fp_arms.tscn:
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
const SC := 1.15

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/arms")
	DirAccess.make_dir_recursive_absolute("res://scenes/player")
	var man: Node3D = load(Mannequin.PATH).instantiate()
	add_child(man)
	await get_tree().process_frame
	var sk: Skeleton3D = man.find_child("Skeleton3D", true, false)
	var mi: MeshInstance3D = man.find_child("Mannequin", true, false)
	Mannequin.curl(sk, "R", 1.0, 0.6)
	Mannequin.curl(sk, "L", 0.35, 0.2)
	await get_tree().process_frame
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true; mat.vertex_color_is_srgb = true; mat.roughness = 0.9
	mat.use_z_clip_scale = true; mat.z_clip_scale = 0.12
	ResourceSaver.save(mat, "res://assets/arms/arms_mat.tres")
	mat = load("res://assets/arms/arms_mat.tres")
	for s in ["R", "L"]:
		var m := _bake(sk, mi, s)
		m.surface_set_material(0, mat)
		ResourceSaver.save(m, "res://assets/arms/arm_%s.res" % s.to_lower())
	## сцена рук
	var root := Node3D.new(); root.name = "FPArms"
	var right := Node3D.new(); right.name = "Right"; root.add_child(right)
	var left := Node3D.new(); left.name = "Left"; root.add_child(left)
	var ar := MeshInstance3D.new(); ar.name = "Arm"; ar.mesh = load("res://assets/arms/arm_r.res")
	ar.transform = Transform3D((HAND_R * Basis(Vector3.UP, PI)).scaled(Vector3.ONE * SC), Vector3(-0.02, 0, 0.085))
	right.add_child(ar)
	var fl = load("res://assets/models/vintage_flashlight/vintage_flashlight_1k.gltf").instantiate()
	fl.name = "Flashlight"; fl.position = Vector3(-0.005, -0.03, -0.05); right.add_child(fl)
	var tip := Marker3D.new(); tip.name = "Tip"; tip.position = Vector3(-0.005, 0.0, -0.22); right.add_child(tip)
	var al := MeshInstance3D.new(); al.name = "Arm"; al.mesh = load("res://assets/arms/arm_l.res")
	al.transform = Transform3D((HAND_L * Basis(Vector3.UP, PI)).scaled(Vector3.ONE * SC), Vector3(0, 0, -0.29))
	left.add_child(al)
	var pt := Marker3D.new(); pt.name = "PT1"; pt.position = Vector3(0, 0.06, -0.17); left.add_child(pt)
	var poses := Node3D.new(); poses.name = "Poses"; root.add_child(poses)
	var raised_b := Basis(Vector3.RIGHT, -0.3) * Basis(Vector3(0, -1, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0))
	for p in [["R_rest", Vector3(0.15, -0.19, -0.42), Basis.from_euler(Vector3(0.04, 0.07, -0.05), EULER_ORDER_YXZ)],
			["R_reach", Vector3(0.09, -0.14, -0.55), Basis.from_euler(Vector3(0.1, 0.04, -0.15), EULER_ORDER_YXZ)],
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

## предплечье и кисть стороны s: вершины по позе скелета, в системе координат кисти; цвет — перчатка/рукав
func _bake(sk: Skeleton3D, mi: MeshInstance3D, s: String) -> ArrayMesh:
	var skin := mi.skin
	var bind_xf := []; var bind_grp := []
	for i in skin.get_bind_count():
		var bn := skin.get_bind_name(i)
		var b := sk.find_bone(bn) if bn != "" else skin.get_bind_bone(i)
		if bn == "": bn = sk.get_bone_name(b)
		bind_xf.append(sk.get_bone_global_pose(b) * skin.get_bind_pose(i))
		var g := 0
		if bn.ends_with("." + s):
			if bn.begins_with("DEF-forearm"): g = 1
			elif bn.begins_with("DEF-hand") or bn.begins_with("DEF-f_") or bn.begins_with("DEF-thumb"): g = 2
		bind_grp.append(g)
	var hand_inv := sk.get_bone_global_pose(sk.find_bone("DEF-hand." + s)).affine_inverse()
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for si in mi.mesh.get_surface_count():
		var a := mi.mesh.surface_get_arrays(si)
		var V: PackedVector3Array = a[Mesh.ARRAY_VERTEX]; var N: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
		var BI: PackedInt32Array = a[Mesh.ARRAY_BONES]; var BW: PackedFloat32Array = a[Mesh.ARRAY_WEIGHTS]
		var stride := BI.size() / V.size()
		var IDX: PackedInt32Array = a[Mesh.ARRAY_INDEX] if a[Mesh.ARRAY_INDEX] != null else PackedInt32Array(range(V.size()))
		var pv := PackedVector3Array(); pv.resize(V.size())
		var pn := PackedVector3Array(); pn.resize(V.size())
		var grp := PackedInt32Array(); grp.resize(V.size())
		for v in V.size():
			var p := Vector3.ZERO; var n := Vector3.ZERO; var best := -1.0; var bg := 0
			for k in stride:
				var w := BW[v * stride + k]
				if w <= 0.0: continue
				var bi := BI[v * stride + k]
				var xf: Transform3D = bind_xf[bi]
				p += (xf * V[v]) * w; n += (xf.basis * N[v]) * w
				if w > best: best = w; bg = bind_grp[bi]
			pv[v] = hand_inv * p; pn[v] = (hand_inv.basis * n).normalized(); grp[v] = bg
		var i := 0
		while i < IDX.size():
			var ok := true
			for j in 3: if grp[IDX[i + j]] == 0: ok = false
			if ok:
				for j in 3:
					var vi := IDX[i + j]
					st.set_color(GLOVE if grp[vi] == 2 else CLOTH); st.set_normal(pn[vi]); st.add_vertex(pv[vi])
			i += 3
	return st.commit()
