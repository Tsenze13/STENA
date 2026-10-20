@tool
## Корень уровня главы 0 (scenes/levels/chapter0.tscn). Сами части уровня — дочерние узлы сцены
## (подъезд, коридор, ниша, двери…), их видно и можно править в редакторе. Здесь — общие размеры
## и ссылки, которые нужны игре: дверь, решётка, щиток, пульт, лампы.
## Оси: коридор уходит в -Z, пол на y=0, площадка z∈[0,4], дверь на z=0, переборка ГД-6 на z=GATE_Z.
class_name World
extends Node3D

const CORR_W := 4.0
const CORR_H := 9.0
const HW := 2.0
const LEN := 2000.0
const GATE_Z := -20.0
const NICHE := [-6.0, -10.0]
const NICHE_H := 3.2
const DET := 260.0           # дальше этого мелкие детали не строим: туман всё равно скрывает
const CW_Y := 4.2            # высота мостков
const SHAFT := [-29.6, -37.4]  # проём в правой стене на участке 7: балкон над колодцем Стены
const SHAFT_H := 7.2

var lamps: Array = []        # {kind, pos, grp, lvl, on, fl, delay, dead, inst}
var door := {}               # pivot, open, target, shape
var gate := {}               # node, open, moving, lift, shape
var beacon := {}
var panel: Props.PanelModel
var console := {}
var term_viewport: SubViewport
var bulb: MeshInstance3D
var lamp_mm := {}            # kind → MultiMesh светящихся частей
var star_mm: MultiMesh
var shaft: Shaft
var panel_node: Node3D
var console_node: Node3D
var spawn := Vector3(-1.4, 0, 2.7)
var _stars: MultiMeshInstance3D

func _ready() -> void:
	collect()

## собрать ссылки с частей уровня (части к этому времени уже построены)
func collect() -> void:
	var landing = get_node_or_null("Landing")
	var lamps_node = get_node_or_null("Lamps")
	var ed = get_node_or_null("EntryDoor")
	door = ed.state if ed else {}
	var bh = get_node_or_null("Bulkhead")
	if bh:
		gate = bh.gate; beacon = bh.beacon
	var pn = find_child("PanelSHR6", true, false)
	if pn: panel = pn.model; panel_node = pn
	var cn = find_child("Console", true, false)
	if cn: console = cn.data; term_viewport = cn.viewport; console_node = cn
	shaft = get_node_or_null("Shaft") as Shaft
	var sp = get_node_or_null("PlayerSpawn")
	if sp: spawn = sp.position
	lamps = []
	if landing:
		bulb = landing.bulb
		lamps.append(landing.lamp)
	if lamps_node:
		lamps.append_array(lamps_node.lamps)
		lamp_mm = lamps_node.lamp_mm
	_build_stars()
	if Engine.is_editor_hint():
		_editor_lights()

## «звёздочки»: свечение ламп постоянного экранного размера — видно до горизонта
func _build_stars() -> void:
	if is_instance_valid(_stars): _stars.queue_free()
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var r := Vector2(x - 31.5, y - 31.5).length() / 32.0
			img.set_pixel(x, y, Color(1, 1, 1, pow(maxf(1.0 - r, 0.0), 2.2)))
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; sm.vertex_color_use_as_albedo = true
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; sm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	sm.albedo_texture = ImageTexture.create_from_image(img); sm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	sm.fixed_size = true; sm.no_depth_test = false; sm.set("disable_fog", true)
	var q := QuadMesh.new(); q.size = Vector2(0.035, 0.035)
	star_mm = MultiMesh.new(); star_mm.transform_format = MultiMesh.TRANSFORM_3D; star_mm.use_colors = true; star_mm.mesh = q
	star_mm.instance_count = lamps.size()
	for j in lamps.size():
		var L: Dictionary = lamps[j]
		var gp: Vector3 = L.get("glow", L.pos)
		var sz: float = {"wall": 1.0, "dome": 1.6, "em": 0.35, "bulb": 0.6}[L.kind]
		star_mm.set_instance_transform(j, Transform3D(Basis().scaled(Vector3.ONE * sz), gp))
		star_mm.set_instance_color(j, Color(0, 0, 0, 0))
		L["star"] = j
	_stars = MultiMeshInstance3D.new(); _stars.multimesh = star_mm; _stars.material_override = sm
	_stars.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; _stars.extra_cull_margin = 16384
	add_child(_stars, false, Node.INTERNAL_MODE_FRONT)

## в редакторе лампы светятся, чтобы было видно, где они
func _editor_lights() -> void:
	for L in lamps:
		if L.has("inst") and lamp_mm.has(L.kind):
			lamp_mm[L.kind].set_instance_color(L.inst, Color(2.2, 2.2, 2.0))
		star_mm.set_instance_color(L.star, Color(0.8, 0.7, 0.5, 1))
