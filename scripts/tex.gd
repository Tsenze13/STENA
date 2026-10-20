@tool
## Материалы: настоящие текстуры Poly Haven (CC0) из assets/textures, где они есть (таблица REAL), остальное — процедурный шум.
class_name Tex
extends RefCounted

static var _cache := {}

## шум → картинка: oct — подробность, contrast — насколько пятнистая
static func noise_image(size: int, seed_v: int, freq: float, contrast: float, bright: float, oct := 5, kind := FastNoiseLite.TYPE_SIMPLEX_SMOOTH) -> Image:
	var n := FastNoiseLite.new()
	n.seed = seed_v
	n.noise_type = kind
	n.frequency = freq
	n.fractal_octaves = oct
	var img := n.get_seamless_image(size, size, false, false, 0.1, true)
	img.convert(Image.FORMAT_RGB8)
	img.adjust_bcs(bright, contrast, 1.0)
	return img

## Настоящие текстуры (Poly Haven, CC0) в assets/textures/<имя>/. Материал по ключу берёт картинку отсюда;
## если файла нет — остаётся процедурный шум. [текстура, вариант (diff или gray), размер плитки в метрах]
const REAL := {
	"concrete": ["concrete_wall_006", "diff", 2.5], "pilaster": ["concrete_wall_006", "diff", 2.5],
	"conc_cold": ["concrete_wall_006", "diff", 2.5], "band": ["peeling_painted_wall", "gray", 2.0],
	"green": ["peeling_painted_wall", "gray", 2.0], "floor": ["concrete_floor_worn_001", "diff", 2.5],
	"step": ["concrete_floor_worn_001", "diff", 1.6], "ceil": ["rough_concrete", "diff", 2.5],
	"white": ["white_plaster_rough_01", "diff", 2.0], "rust": ["rust_coarse_01", "diff", 1.2],
	"snow": ["snow_02", "diff", 3.0], "wall_frost": ["concrete_panels", "diff", 10.0],
	"yellow": ["rusty_metal_02", "diff", 1.2], "truck": ["rusty_painted_metal", "gray", 1.5],
	"_metal": ["metal_plate_02", "gray", 1.0],
}
## средний цвет картинок: делим на него, чтобы материал сохранил подобранный цвет, а картинка дала только детали
const MEAN := {
	"concrete_floor_worn_001_diff": Color(0.337, 0.339, 0.33), "concrete_panels_diff": Color(0.592, 0.515, 0.433),
	"concrete_wall_006_diff": Color(0.359, 0.316, 0.271), "metal_plate_02_gray": Color(0.588, 0.588, 0.588),
	"peeling_painted_wall_gray": Color(0.586, 0.586, 0.586), "rough_concrete_diff": Color(0.723, 0.71, 0.613),
	"rust_coarse_01_diff": Color(0.386, 0.225, 0.124), "rusty_metal_02_diff": Color(0.673, 0.563, 0.354),
	"rusty_painted_metal_gray": Color(0.586, 0.586, 0.586), "snow_02_diff": Color(0.648, 0.647, 0.655),
	"white_plaster_rough_01_diff": Color(0.488, 0.444, 0.342),
}

static func _real(spec: Array, color: Color, rough: float, metal: float) -> StandardMaterial3D:
	var id: String = spec[0]; var kind: String = spec[1]
	var base := "res://assets/textures/%s/%s_" % [id, id]
	if not ResourceLoader.exists(base + kind + "_1k.jpg"): return null
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(base + kind + "_1k.jpg")
	var mean: Color = MEAN.get(id + "_" + kind, Color(0.5, 0.5, 0.5))
	m.albedo_color = Color(minf(color.r / mean.r, 3.0), minf(color.g / mean.g, 3.0), minf(color.b / mean.b, 3.0))
	if ResourceLoader.exists(base + "nor_gl_1k.jpg"):
		m.normal_enabled = true; m.normal_texture = load(base + "nor_gl_1k.jpg"); m.normal_scale = 0.8
	if ResourceLoader.exists(base + "rough_1k.jpg"):
		m.roughness_texture = load(base + "rough_1k.jpg"); m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
		m.roughness = clampf(rough + 0.15, 0.3, 1.0)
	else:
		m.roughness = rough
	m.metallic = metal
	m.uv1_triplanar = true; m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / float(spec[2])
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m

## материал «поверхность»: настоящая текстура (если есть в REAL) или цвет × шум; триплан — не нужны развёртки
static func surface(key: String, color: Color, rough := 0.9, metal := 0.0, scale := 0.5, contrast := 0.35, bump := 3.0, seed_v := 1, freq := 0.05, real := "") -> StandardMaterial3D:
	if _cache.has(key):
		return _cache[key]
	var rk := real if real != "" else key
	if REAL.has(rk):
		var rm := _real(REAL[rk], color, rough, metal)
		if rm:
			_cache[key] = rm
			return rm
	var m := StandardMaterial3D.new()
	var img := noise_image(256, seed_v, freq, contrast * 0.6, 1.05)
	img.generate_mipmaps()    # без мипмапов мелкий шум мерцает при движении
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	var nimg := noise_image(256, seed_v + 7, freq * 3.0, 1.0, 1.0, 4)
	nimg.bump_map_to_normal_map(bump)
	nimg.generate_mipmaps()
	m.normal_enabled = true
	m.normal_texture = ImageTexture.create_from_image(nimg)
	m.normal_scale = 0.3
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE * scale
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_cache[key] = m
	return m

static func plain(key: String, color: Color, rough := 0.8, metal := 0.0) -> StandardMaterial3D:
	if _cache.has(key):
		return _cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	_cache[key] = m
	return m

## светящийся (без освещения) — для ламп, экранов, индикаторов
static func glow(key: String, color: Color, energy := 1.0) -> StandardMaterial3D:
	if _cache.has(key):
		return _cache[key]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color * energy
	_cache[key] = m
	return m

## готовые материалы сцены
static func concrete() -> StandardMaterial3D: return surface("concrete", Color(0.47, 0.46, 0.43), 0.92, 0.0, 0.45, 0.45, 2.0, 11, 0.04)
static func paint_band() -> StandardMaterial3D: return surface("band", Color(0.2, 0.25, 0.3), 0.62, 0.0, 0.6, 0.3, 1.5, 12)
static func floor_concrete() -> StandardMaterial3D: return surface("floor", Color(0.33, 0.32, 0.3), 0.85, 0.0, 0.5, 0.5, 3.0, 13, 0.05)
static func ceiling() -> StandardMaterial3D: return surface("ceil", Color(0.25, 0.25, 0.24), 0.95, 0.0, 0.4, 0.4, 3.0, 14)
static func whitewash() -> StandardMaterial3D: return surface("white", Color(0.78, 0.76, 0.68), 0.95, 0.0, 0.5, 0.4, 2.0, 15)
static func green_paint() -> StandardMaterial3D: return surface("green", Color(0.2, 0.32, 0.26), 0.55, 0.0, 0.6, 0.3, 1.5, 16)
static func metal(key := "metal", color := Color(0.32, 0.33, 0.31)) -> StandardMaterial3D: return surface(key, color, 0.5, 0.6, 1.0, 0.35, 2.0, 17, 0.08, "_metal")
static func rust() -> StandardMaterial3D: return surface("rust", Color(0.42, 0.24, 0.13), 0.85, 0.3, 1.2, 0.7, 3.0, 18, 0.04)
static func dark_metal() -> StandardMaterial3D: return surface("dmetal", Color(0.16, 0.16, 0.15), 0.55, 0.5, 1.0, 0.4, 2.0, 19, 0.03, "_metal")
static func yellow() -> StandardMaterial3D: return surface("yellow", Color(0.79, 0.62, 0.14), 0.6, 0.0, 1.0, 0.25, 1.0, 20)
static func cable() -> StandardMaterial3D: return plain("cable", Color(0.06, 0.06, 0.06), 0.55)

## решётчатый настил: картинка с прозрачными ячейками
static func grate() -> StandardMaterial3D:
	if _cache.has("grate"):
		return _cache["grate"]
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in 128:
		for x in 128:
			var a := (x + y) % 16 < 3 or (x - y + 256) % 16 < 3 or x < 4 or y < 4
			if a:
				img.set_pixel(x, y, Color(0.3, 0.3, 0.28, 1))
	img.generate_mipmaps()
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.5
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.metallic = 0.6
	m.roughness = 0.5
	m.uv1_scale = Vector3(1, 1, 1)
	_cache["grate"] = m
	return m

## жёлто-чёрные полосы
static func hazard() -> StandardMaterial3D:
	if _cache.has("hazard"):
		return _cache["hazard"]
	var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
	for y in 64:
		for x in 64:
			var s := ((x + y) / 16) % 2 == 0
			img.set_pixel(x, y, Color(0.84, 0.66, 0.12) if s else Color(0.07, 0.07, 0.07))
	img.generate_mipmaps()
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE * 2.5
	m.roughness = 0.6
	_cache["hazard"] = m
	return m

## плитка пола в подъезде «шахматкой»
static func tiles() -> StandardMaterial3D:
	if _cache.has("tiles"):
		return _cache["tiles"]
	var img := Image.create(256, 256, false, Image.FORMAT_RGB8)
	var r := RandomNumberGenerator.new(); r.seed = 3
	for y in 256:
		for x in 256:
			var c := Color(0.47, 0.28, 0.23) if ((x / 32 + y / 32) % 2 == 0) else Color(0.59, 0.55, 0.47)
			if x % 32 < 1 or y % 32 < 1: c = Color(0.15, 0.13, 0.12)
			c = c.darkened(r.randf() * 0.08)
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	var m := StandardMaterial3D.new(); m.albedo_texture = ImageTexture.create_from_image(img); m.roughness = 0.55
	m.uv1_triplanar = true; m.uv1_world_triplanar = true; m.uv1_scale = Vector3.ONE * 0.6
	_cache["tiles"] = m
	return m

## дерматин на квартирной двери: стёжка ромбами и гвоздики с шляпками
static func dermatin(key: String, color: Color) -> StandardMaterial3D:
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(128, 128, false, Image.FORMAT_RGB8)
	var nimg := Image.create(128, 128, false, Image.FORMAT_RGB8)
	for y in 128:
		for x in 128:
			var u := float(x) / 128.0; var v := float(y) / 128.0
			var d1 := absf(fmod(u + v, 0.5) - 0.25) * 4.0
			var d2 := absf(fmod(u - v + 1.0, 0.5) - 0.25) * 4.0
			var puff := minf(d1, d2)
			var c := color * (0.75 + 0.35 * puff)
			var st := Vector2(fmod(u + 0.25, 0.5) - 0.25, fmod(v, 0.5) - 0.25).length()
			var st2 := Vector2(fmod(u, 0.5) - 0.25, fmod(v + 0.25, 0.5) - 0.25).length()
			if minf(st, st2) < 0.025: c = Color(0.7, 0.6, 0.35)
			img.set_pixel(x, y, Color(c, 1.0))
			nimg.set_pixel(x, y, Color(puff, puff, puff))
	img.generate_mipmaps()
	nimg.bump_map_to_normal_map(6.0); nimg.generate_mipmaps()
	var m := StandardMaterial3D.new(); m.albedo_texture = ImageTexture.create_from_image(img); m.roughness = 0.45
	m.normal_enabled = true; m.normal_texture = ImageTexture.create_from_image(nimg); m.normal_scale = 0.8
	m.uv1_scale = Vector3(2.5, 4.0, 1)
	_cache[key] = m
	return m

## снег: белый с голубым, мягкий рельеф
static func snow() -> StandardMaterial3D: return surface("snow", Color(0.8, 0.83, 0.88), 0.85, 0.0, 0.35, 0.25, 2.0, 61, 0.03)

## ящики: доски
static func crate() -> StandardMaterial3D: return surface("crate", Color(0.36, 0.28, 0.18), 0.9, 0.0, 2.0, 0.6, 3.0, 21, 0.05)
