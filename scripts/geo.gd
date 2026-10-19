## Помощники геометрии: склейка множества деталей в один меш на материал (мало вызовов отрисовки),
## провисающие кабели, коллайдеры.
class_name Geo
extends RefCounted

## ---------- пакет деталей ----------
class Batch:
	var groups := {}   # материал → SurfaceTool
	var counts := {}

	func add(mesh: Mesh, mat: Material, xf: Transform3D) -> void:
		if not groups.has(mat):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			groups[mat] = st
			counts[mat] = 0
		for s in mesh.get_surface_count():
			groups[mat].append_from(mesh, s, xf)
		counts[mat] += 1

	func box(size: Vector3, mat: Material, pos: Vector3, rot := Vector3.ZERO) -> void:
		var b := BoxMesh.new()
		b.size = size
		add(b, mat, Transform3D(Basis.from_euler(rot), pos))

	func cyl(r_top: float, r_bot: float, h: float, mat: Material, pos: Vector3, rot := Vector3.ZERO, seg := 12) -> void:
		var c := CylinderMesh.new()
		c.top_radius = r_top
		c.bottom_radius = r_bot
		c.height = h
		c.radial_segments = seg
		c.rings = 1
		add(c, mat, Transform3D(Basis.from_euler(rot), pos))

	func build(parent: Node3D, cast_shadow := true) -> void:
		for mat in groups:
			var mi := MeshInstance3D.new()
			mi.mesh = groups[mat].commit()
			mi.material_override = mat
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			parent.add_child(mi)
		groups.clear()

## провис кабеля: парабола вниз на sag метров, с уводом в сторону side
static func catenary(a: Vector3, b: Vector3, sag: float, n := 14, side := Vector3.ZERO) -> PackedVector3Array:
	var pts := PackedVector3Array()
	for i in n + 1:
		var t := float(i) / n
		var k := 4.0 * t * (1.0 - t)
		var v := a.lerp(b, t)
		v.y -= sag * k
		v += side * k
		pts.append(v)
	return pts

## трубка вдоль точек (кабель): сглаживание Catmull-Rom, кольца по radial
static func tube(pts: PackedVector3Array, r: float, radial := 5, sub := 2) -> ArrayMesh:
	var smooth := PackedVector3Array()
	for i in pts.size() - 1:
		var p0 := pts[maxi(i - 1, 0)]
		var p1 := pts[i]
		var p2 := pts[i + 1]
		var p3 := pts[mini(i + 2, pts.size() - 1)]
		for s in sub:
			var t := float(s) / sub
			smooth.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t * t * t))
	smooth.append(pts[pts.size() - 1])
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := smooth.size()
	var up := Vector3.UP
	for i in n:
		var t: Vector3 = (smooth[min(i + 1, n - 1)] - smooth[max(i - 1, 0)]).normalized()
		if abs(t.dot(up)) > 0.95:
			up = Vector3.RIGHT
		var nx := t.cross(up).normalized()
		var ny := nx.cross(t).normalized()
		for j in radial:
			var a := TAU * j / radial
			var nor := nx * cos(a) + ny * sin(a)
			st.set_normal(nor)
			st.set_uv(Vector2(float(j) / radial, float(i) / n))
			st.add_vertex(smooth[i] + nor * r)
	for i in n - 1:
		for j in radial:
			var a := i * radial + j
			var b := i * radial + (j + 1) % radial
			var c := (i + 1) * radial + j
			var d := (i + 1) * radial + (j + 1) % radial
			st.add_index(a); st.add_index(c); st.add_index(b)
			st.add_index(b); st.add_index(c); st.add_index(d)
	return st.commit()

## ---------- коллайдеры ----------
## прямоугольник-стена: размеры и центр; возвращает CollisionShape3D (его можно выключать)
static func solid(body: StaticBody3D, size: Vector3, pos: Vector3, rot := Vector3.ZERO) -> CollisionShape3D:
	var cs := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = size
	cs.shape = b
	cs.position = pos
	cs.rotation = rot
	body.add_child(cs)
	return cs

## простой меш-коробка отдельным узлом (для подвижных частей)
static func box_node(parent: Node3D, size: Vector3, mat: Material, pos := Vector3.ZERO, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi

static func cyl_node(parent: Node3D, r_top: float, r_bot: float, h: float, mat: Material, pos := Vector3.ZERO, rot := Vector3.ZERO, seg := 16) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = r_top
	c.bottom_radius = r_bot
	c.height = h
	c.radial_segments = seg
	mi.mesh = c
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi

## надпись в мире (трафарет, таблички)
static func label(parent: Node3D, text: String, size_px: int, color: Color, pos: Vector3, rot := Vector3.ZERO, pixel := 0.004, shaded := true) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size_px
	l.pixel_size = pixel
	l.modulate = color
	l.outline_size = 0
	l.shaded = shaded
	l.double_sided = false
	l.position = pos
	l.rotation = rot
	l.alpha_cut = Label3D.ALPHA_CUT_DISABLED
	parent.add_child(l)
	return l

## зона взаимодействия: невидимая коробка в слое 2 с меткой act
static func act_zone(parent: Node3D, size: Vector3, pos: Vector3, act: String, label_text := "") -> StaticBody3D:
	var b := StaticBody3D.new()
	b.collision_layer = 2
	b.collision_mask = 0
	b.position = pos
	b.set_meta("act", act)
	b.set_meta("label", label_text)
	var cs := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = size
	cs.shape = s
	b.add_child(cs)
	parent.add_child(b)
	return b
