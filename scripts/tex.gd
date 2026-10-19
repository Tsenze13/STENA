## Процедурные материалы и текстуры: всё генерируется при запуске, файлов-картинок в игре нет.
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

## материал «поверхность»: цвет × шум, шероховатость, рельеф; триплан — не нужны развёртки
static func surface(key: String, color: Color, rough := 0.9, metal := 0.0, scale := 0.5, contrast := 0.35, bump := 3.0, seed_v := 1, freq := 0.05) -> StandardMaterial3D:
	if _cache.has(key):
		return _cache[key]
	var m := StandardMaterial3D.new()
	var img := noise_image(256, seed_v, freq, contrast * 0.6, 1.05)
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
static func metal(key := "metal", color := Color(0.32, 0.33, 0.31)) -> StandardMaterial3D: return surface(key, color, 0.5, 0.6, 1.0, 0.35, 2.0, 17, 0.08)
static func rust() -> StandardMaterial3D: return surface("rust", Color(0.42, 0.24, 0.13), 0.85, 0.3, 1.2, 0.7, 3.0, 18, 0.04)
static func dark_metal() -> StandardMaterial3D: return surface("dmetal", Color(0.16, 0.16, 0.15), 0.55, 0.5, 1.0, 0.4, 2.0, 19, 0.03)
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

## ящики: доски
static func crate() -> StandardMaterial3D: return surface("crate", Color(0.36, 0.28, 0.18), 0.9, 0.0, 2.0, 0.6, 3.0, 21, 0.05)
