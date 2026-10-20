@tool
## Дальние планы: стены мегаструктуры с огнями ярусов, панельные дома с окнами, россыпи огней.
## Всё без освещения и без тумана (туман сцены прячет всё дальше 50 м), зато со своей дымкой по расстоянию:
## чем дальше — тем глуше, поэтому видно глубину на километры.
class_name Fx
extends RefCounted

static var _wall_shader: Shader
static var _pts_shader: Shader
static var _glow_tex: Texture2D

## Стена мегаструктуры (или дом): тёмные панели, рёбра, плиты ярусов, окна-огни.
## axis: 0 — стена вдоль Z (смотрит по X), 1 — стена вдоль X (смотрит по Z), -1 — по нормали (для домов-коробок).
## cell — шаг окон по горизонтали, level — высота яруса, lit — доля горящих окон.
static func wall_mat(axis: int, cell := 6.0, level := 12.0, lit := 0.3, base := Color(0.016, 0.017, 0.018), warm := Color(1.0, 0.72, 0.4), cold := Color(0.65, 0.8, 1.0), haze := Color(0.012, 0.014, 0.02), haze_k := 0.0012, win_h := 0.22, win_w := 0.38) -> ShaderMaterial:
	if _wall_shader == null:
		_wall_shader = Shader.new()
		_wall_shader.code = """
shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled;
uniform int axis = 0;
uniform float cell = 6.0;
uniform float level = 12.0;
uniform float lit = 0.3;
uniform float win_h = 0.22;
uniform float win_w = 0.38;
uniform vec4 base : source_color;
uniform vec4 warm : source_color;
uniform vec4 cold : source_color;
uniform vec4 haze : source_color;
uniform float haze_k = 0.0012;
uniform float reveal = 1e9;       // огни горят ближе этого расстояния от центра
uniform vec3 center = vec3(0.0);
uniform float power = 1.0;
varying vec3 wp;
varying vec3 wn;
float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	int ax = axis;
	if (ax < 0) ax = abs(wn.x) > 0.5 ? 0 : 1;
	float roof = axis < 0 ? step(0.5, abs(wn.y)) : 0.0;
	vec2 u = ax == 0 ? vec2(wp.z, wp.y) : vec2(wp.x, wp.y);
	vec2 g = u / vec2(cell, level);
	vec2 id = floor(g);
	vec2 f = fract(g);
	vec2 fw = fwidth(g);
	// рёбра и плиты ярусов
	float rib = 1.0 - smoothstep(0.0, 0.04 + fw.x, abs(f.x - 0.5) * 2.0 - 0.92);
	float slab = smoothstep(0.86 - fw.y, 0.9, f.y);
	vec3 c = base.rgb * (1.0 + 1.2 * rib + 2.2 * slab);
	// окна: полоса на ярусе, часть горит
	float r = h(id);
	float on = step(r, lit) * step(distance(wp, center), reveal) * power * (1.0 - roof);
	float wx = smoothstep(0.0, fw.x + 0.02, win_w - abs(f.x - 0.5));
	float wy = smoothstep(0.0, fw.y + 0.01, win_h * 0.5 - abs(f.y - 0.42));
	vec3 lc = mix(warm.rgb, cold.rgb, step(0.6, h(id + 7.3))) * (0.55 + 0.6 * h(id + 3.1));
	float m = wx * wy * on;
	// издалека окна мельче пикселя — заменяем средней яркостью
	float far = smoothstep(0.25, 1.2, max(fw.x, fw.y));
	vec3 col = mix(c + lc * m, c + lc * on * win_w * win_h * 3.0, far);
	float d = length(wp - CAMERA_POSITION_WORLD);
	col = mix(col, haze.rgb, 1.0 - exp(-d * haze_k));
	ALBEDO = col;
}
"""
	var m := ShaderMaterial.new()
	m.shader = _wall_shader
	m.set_shader_parameter("axis", axis)
	m.set_shader_parameter("cell", cell)
	m.set_shader_parameter("level", level)
	m.set_shader_parameter("lit", lit)
	m.set_shader_parameter("win_h", win_h)
	m.set_shader_parameter("win_w", win_w)
	m.set_shader_parameter("base", base)
	m.set_shader_parameter("warm", warm)
	m.set_shader_parameter("cold", cold)
	m.set_shader_parameter("haze", haze)
	m.set_shader_parameter("haze_k", haze_k)
	return m

## плоскость (стена) размером sx×sy; axis как у wall_mat
static func plane(parent: Node3D, mat: Material, center: Vector3, sx: float, sy: float, axis: int) -> MeshInstance3D:
	var q := QuadMesh.new(); q.size = Vector2(sx, sy)
	var mi := MeshInstance3D.new(); mi.mesh = q; mi.material_override = mat
	mi.position = center
	if axis == 0: mi.rotation.y = PI / 2
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 16384
	parent.add_child(mi)
	return mi

static func glow_tex() -> Texture2D:
	if _glow_tex == null:
		var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		for y in 64:
			for x in 64:
				var r := Vector2(x - 31.5, y - 31.5).length() / 32.0
				img.set_pixel(x, y, Color(1, 1, 1, pow(maxf(1.0 - r, 0.0), 2.0)))
		img.generate_mipmaps()
		_glow_tex = ImageTexture.create_from_image(img)
	return _glow_tex

## Россыпь огней-точек. pts: массив [позиция, цвет, размер в метрах, мигание 0/1, скорость по вертикали].
## Мигающие — авиационные красные; со скоростью — лифты, которые ползут вверх/вниз.
static func points(parent: Node3D, pts: Array, center := Vector3.ZERO, haze_k := 0.0008) -> MultiMeshInstance3D:
	if _pts_shader == null:
		_pts_shader = Shader.new()
		_pts_shader.code = """
shader_type spatial;
render_mode unshaded, fog_disabled, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform sampler2D tex : source_color, filter_linear_mipmap;
uniform float reveal = 1e9;
uniform vec3 center = vec3(0.0);
uniform float power = 1.0;
uniform float haze_k = 0.0008;
varying vec3 col;
void vertex() {
	vec3 p = MODEL_MATRIX[3].xyz;
	if (INSTANCE_CUSTOM.w != 0.0) p.y = mod(p.y + TIME * INSTANCE_CUSTOM.w + 1500.0, 3000.0) - 1500.0;
	float s = length(MODEL_MATRIX[0].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * s, INV_VIEW_MATRIX[1] * s, INV_VIEW_MATRIX[2] * s, vec4(p, 1.0));
	float blink = INSTANCE_CUSTOM.y > 0.5 ? step(0.55, fract(TIME * 0.7 + INSTANCE_CUSTOM.x)) : 1.0;
	float on = step(distance(p, center), reveal) * power;
	float d = length(p - CAMERA_POSITION_WORLD);
	col = COLOR.rgb * blink * on * exp(-d * haze_k);
}
void fragment() {
	float a = texture(tex, UV).a;
	ALBEDO = col * a;
	ALPHA = a;
}
"""
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	var q := QuadMesh.new(); q.size = Vector2.ONE
	mm.mesh = q
	mm.instance_count = pts.size()
	for i in pts.size():
		var p: Array = pts[i]
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * float(p[2])), p[0]))
		mm.set_instance_color(i, p[1])
		mm.set_instance_custom_data(i, Color(randf(), float(p[3]) if p.size() > 3 else 0.0, 0.0, float(p[4]) if p.size() > 4 else 0.0))
	var m := ShaderMaterial.new(); m.shader = _pts_shader
	m.set_shader_parameter("tex", glow_tex())
	m.set_shader_parameter("center", center)
	m.set_shader_parameter("haze_k", haze_k)
	var mmi := MultiMeshInstance3D.new(); mmi.multimesh = mm; mmi.material_override = m
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.extra_cull_margin = 16384
	parent.add_child(mmi)
	return mmi
