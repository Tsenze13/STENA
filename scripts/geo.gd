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

## ---------- краска по трафарету ----------
## Надпись рисуется один раз в SubViewport (белым по прозрачному), а шейдер на плоскости красит её
## в цвет краски и «обдирает» по шуму — выглядит как старая трафаретная надпись на стене или двери.
static var _paint_shader: Shader
static var _paint_noise: Texture2D
static func _paint_mat(tex: Texture2D, color: Color, wear: float) -> ShaderMaterial:
	if _paint_shader == null:
		_paint_shader = Shader.new()
		_paint_shader.code = """
shader_type spatial;
render_mode cull_back;
uniform sampler2D text_tex : source_color, filter_linear_mipmap;
uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform vec4 paint : source_color = vec4(0.6, 0.1, 0.08, 1.0);
uniform float wear = 0.35;
uniform vec2 noise_scale = vec2(3.0, 1.0);
void fragment() {
	vec4 t = texture(text_tex, UV);
	float n = texture(noise_tex, UV * noise_scale).r;
	float n2 = texture(noise_tex, UV * noise_scale * 5.0 + 0.37).r;
	float a = t.a * step(wear, n * 0.7 + n2 * 0.5);
	ALBEDO = paint.rgb * (0.75 + 0.35 * n2);
	ROUGHNESS = 0.75;
	ALPHA = a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
"""
		var img := Tex.noise_image(256, 77, 0.04, 1.6, 1.0, 4)
		img.generate_mipmaps()
		_paint_noise = ImageTexture.create_from_image(img)
	var m := ShaderMaterial.new()
	m.shader = _paint_shader
	m.set_shader_parameter("text_tex", tex)
	m.set_shader_parameter("noise_tex", _paint_noise)
	m.set_shader_parameter("paint", color)
	m.set_shader_parameter("wear", wear)
	return m

## надпись краской: height — высота строки в метрах; wear 0..0.6 — насколько облезла
static func paint(parent: Node3D, text: String, height: float, color: Color, pos: Vector3, rot := Vector3.ZERO, wear := 0.3, bold := true) -> MeshInstance3D:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Oswald", "Bahnschrift SemiCondensed", "Arial Narrow", "DejaVu Sans Condensed", "Liberation Sans Narrow", "sans-serif"])
	f.font_weight = 700 if bold else 400
	var px := 96
	var lines := text.split("\n")
	var w := 1.0
	for l in lines:
		w = max(w, f.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x)
	var vp := SubViewport.new()
	vp.size = Vector2i(int(w) + 24, px * lines.size() + 24)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var lab := Label.new()
	lab.text = text
	lab.add_theme_font_override("font", f)
	lab.add_theme_font_size_override("font_size", px)
	lab.add_theme_constant_override("line_spacing", -int(px * 0.15))
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.position = Vector2(12, 6)
	lab.size = Vector2(w, px * lines.size())
	vp.add_child(lab)
	parent.add_child(vp)
	var aspect := float(vp.size.x) / float(vp.size.y)
	var h := height * lines.size() * (float(vp.size.y) / (px * lines.size()))
	var q := QuadMesh.new()
	q.size = Vector2(h * aspect, h)
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = _paint_mat(vp.get_texture(), color, wear)
	mi.position = pos
	mi.rotation = rot
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi

## эмалированная табличка: фон, рамка, текст (рисуется один раз в SubViewport)
static func plate(parent: Node3D, lines: Array, size: Vector2, bg: Color, fg: Color, pos: Vector3, rot := Vector3.ZERO, glyph := "") -> Node3D:
	var vp := SubViewport.new()
	var ppm := 1000.0
	vp.size = Vector2i(int(size.x * ppm), int(size.y * ppm))
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var bgr := ColorRect.new(); bgr.color = bg; bgr.size = Vector2(vp.size); vp.add_child(bgr)
	var fr := ReferenceRect.new(); fr.border_color = fg; fr.border_width = 10; fr.editor_only = false
	fr.position = Vector2(10, 10); fr.size = Vector2(vp.size) - Vector2(20, 20); vp.add_child(fr)
	var f := SystemFont.new(); f.font_names = PackedStringArray(["Oswald", "Bahnschrift", "Arial Narrow", "DejaVu Sans Condensed", "sans-serif"]); f.font_weight = 700
	var vb := VBoxContainer.new(); vb.position = Vector2(20, 16); vb.size = Vector2(vp.size) - Vector2(40, 32); vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vp.add_child(vb)
	if glyph != "":
		var g := Label.new(); g.text = glyph; g.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		g.add_theme_font_size_override("font_size", int(vp.size.y * 0.32)); g.add_theme_color_override("font_color", Color(0.05, 0.05, 0.05))
		vb.add_child(g)
	for l in lines:
		var lab := Label.new(); lab.text = l[0]; lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lab.add_theme_font_override("font", f); lab.add_theme_font_size_override("font_size", int(l[1])); lab.add_theme_color_override("font_color", fg)
		vb.add_child(lab)
	parent.add_child(vp)
	var n := Node3D.new(); n.position = pos; n.rotation = rot; parent.add_child(n)
	var m := StandardMaterial3D.new(); m.albedo_texture = vp.get_texture(); m.roughness = 0.25; m.metallic = 0.1
	var q := QuadMesh.new(); q.size = size
	var mi := MeshInstance3D.new(); mi.mesh = q; mi.material_override = m; mi.position.z = 0.004; n.add_child(mi)
	box_node(n, Vector3(size.x + 0.01, size.y + 0.01, 0.006), Tex.plain("plate_back", Color(0.3, 0.3, 0.3), 0.5, 0.5))
	for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		cyl_node(n, 0.006, 0.006, 0.006, Tex.plain("rivet", Color(0.45, 0.43, 0.4), 0.4, 0.7), Vector3(c.x * (size.x / 2 - 0.02), c.y * (size.y / 2 - 0.02), 0.007), Vector3(PI / 2, 0, 0), 8)
	return n
