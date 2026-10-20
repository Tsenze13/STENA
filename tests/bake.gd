## Запекание уровня: геометрия частей (стены, полы, лестницы, фасад…) сохраняется в сцену chapter0
## обычными объектами — меши в scenes/levels/baked/, материалы в assets/materials/. После этого их можно
## двигать и удалять в редакторе, а части уровня (baked = true) строят только живое: лампы, надписи, экраны.
##   godot --headless --path . res://tests/bake.tscn
## Повторное запекание затрёт ручные правки запечённых кусков — запускать один раз.
extends Node

var mat_paths := {}     # материал → путь
var keys := {}          # материал → ключ из Tex
var n_mat := 0

func _ready() -> void:
	var ps: PackedScene = load("res://scenes/levels/chapter0.tscn")
	var root: Node3D = ps.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	add_child(root)
	await get_tree().process_frame
	await get_tree().process_frame
	for k in Tex._cache: keys[Tex._cache[k]] = k
	var total := 0
	for part in root.get_children():
		if not (part is LevelPart) or part.baked: continue
		if not String(part.get_script().resource_path).begins_with("res://scripts/level/"): continue   # предметы (двери, таблички) не трогаем
		var pcs: Dictionary = part.pieces()
		var made := 0
		for nm in pcs:
			if String(nm).begins_with("Live"): continue
			var src: Node3D = pcs[nm].node
			var dst := Node3D.new(); dst.name = nm
			var j := 0
			for c in src.get_children():
				if c is MeshInstance3D and c.mesh:
					var mi := MeshInstance3D.new(); mi.name = "Mesh%d" % j
					var mp := "res://scenes/levels/baked/%s_%s_%d.res" % [part.name, nm, j]
					ResourceSaver.save(c.mesh, mp)
					mi.mesh = load(mp)
					mi.material_override = _mat(c.material_override, "%s_%s_%d" % [part.name, nm, j])
					mi.cast_shadow = c.cast_shadow
					dst.add_child(mi); j += 1
				elif c is StaticBody3D and c.get_child_count() > 0:
					var sb := StaticBody3D.new(); sb.name = "Collision"
					for cs in c.get_children():
						var n := CollisionShape3D.new(); n.shape = cs.shape.duplicate(); n.transform = cs.transform
						sb.add_child(n)
					dst.add_child(sb)
			if dst.get_child_count() == 0: dst.free(); continue
			part.add_child(dst)
			_own(dst, root)
			made += 1
		## места ящиков (Clutter) → модели
		if "crate_spots" in part:
			var i := 0
			for c in part.crate_spots:
				var mp := ModelProp.new(); mp.name = "Crate%d" % i; i += 1
				var sz: float = c[1]
				var id := "cardboard_box_01" if sz < 0.5 else ("plastic_crate_01" if sz < 0.6 else ("wooden_crate_02" if sz < 0.75 else "wooden_military_crate"))
				mp.model = load("res://assets/models/%s/%s_1k.gltf" % [id, id])
				mp.position = c[0]; mp.rotation.y = c[2]
				part.add_child(mp); mp.owner = root
		part.baked = true
		print("  %s: %d кусков" % [part.name, made]); total += made
	var out := PackedScene.new()
	var err := out.pack(root)
	if err == OK: err = ResourceSaver.save(out, "res://scenes/levels/chapter0.tscn")
	print("ЗАПЕЧЕНО: %d кусков, %d материалов, сохранение: %s" % [total, n_mat, error_string(err)])
	get_tree().quit()

func _own(n: Node, root: Node) -> void:
	n.owner = root
	for c in n.get_children(): _own(c, root)

## материал — в файл (один раз); процедурные текстуры попадают внутрь файла
func _mat(m: Material, fallback: String) -> Material:
	if m == null: return null
	if m.resource_path != "": return m
	if mat_paths.has(m): return load(mat_paths[m])
	var nm: String = keys.get(m, fallback)
	var path := "res://assets/materials/%s.tres" % nm
	if m is BaseMaterial3D:
		var bm := m as BaseMaterial3D
		for t in [bm.albedo_texture, bm.normal_texture, bm.roughness_texture]:
			if t and t.resource_path == "": path = "res://assets/materials/%s.res" % nm   # шум внутри файла
	ResourceSaver.save(m, path)
	mat_paths[m] = path; n_mat += 1
	return load(path)
