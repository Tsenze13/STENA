@tool
## Распашная дверь, которую можно открыть (E): коробка, полотно на петлях, надпись над дверью.
## style: steel — стальная серая, hermetic — тяжёлая гермодверь со штурвалом, wood — крашеная деревянная.
## locked — заперта (подсказка locked_text). Стену с проёмом под дверь строит часть уровня, дверь — только себя.
class_name SwingDoor
extends LevelPart

@export var label_text := "":
	set(v): label_text = v; changed()
@export_enum("steel", "hermetic", "wood") var style := "steel":
	set(v): style = v; changed()
@export var width := 1.2:
	set(v): width = v; changed()
@export var locked := false
@export var locked_text := "Заперто"
@export var start_open := false

var pivot: Node3D
var shape: CollisionShape3D
var open := 0.0
var target := 0.0

func _build() -> void:
	var w := width; var h := 2.1
	var frame := Tex.dark_metal()
	B.box(Vector3(0.08, h + 0.04, 0.26), frame, Vector3(-w / 2 - 0.04, (h + 0.04) / 2, 0))
	B.box(Vector3(0.08, h + 0.04, 0.26), frame, Vector3(w / 2 + 0.04, (h + 0.04) / 2, 0))
	B.box(Vector3(w + 0.16, 0.08, 0.26), frame, Vector3(0, h + 0.04, 0))
	pivot = Node3D.new(); pivot.position = Vector3(-w / 2, 0, 0); gen.add_child(pivot)
	var mat: Material
	match style:
		"hermetic": mat = Tex.metal("herm", Color(0.28, 0.33, 0.3))
		"wood": mat = Tex.plain("door_wood", Color(0.36, 0.25, 0.18), 0.65)
		_: mat = Tex.metal("door_steel", Color(0.4, 0.42, 0.4))
	var th := 0.14 if style == "hermetic" else 0.06
	Geo.box_node(pivot, Vector3(w, h, th), mat, Vector3(w / 2, h / 2, 0))
	var hm := Tex.plain("handle", Color(0.55, 0.52, 0.48), 0.35, 0.8)
	if style == "hermetic":
		var wheel := MeshInstance3D.new(); var tm := TorusMesh.new(); tm.inner_radius = 0.15; tm.outer_radius = 0.19; wheel.mesh = tm
		wheel.material_override = Tex.plain("wheel", Color(0.45, 0.15, 0.1), 0.4, 0.6); wheel.position = Vector3(w / 2, 1.15, th / 2 + 0.06); wheel.rotation.x = PI / 2
		pivot.add_child(wheel)
		for i in 3:
			Geo.box_node(pivot, Vector3(0.34, 0.022, 0.022), wheel.material_override, Vector3(w / 2, 1.15, th / 2 + 0.06), Vector3(0, 0, i * PI / 3))
		for s in [-1.0, 1.0]:
			Geo.box_node(pivot, Vector3(w + 0.0, 0.1, 0.012), Tex.hazard(), Vector3(w / 2, 0.08, s * (th / 2 + 0.006)))
	for s in [-1.0, 1.0]:
		Geo.box_node(pivot, Vector3(0.12, 0.03, 0.05), hm, Vector3(w - 0.15, 1.0, s * (th / 2 + 0.025)))
	if label_text != "":
		Geo.paint(gen, label_text, 0.11, Color(0.85, 0.83, 0.76), Vector3(0, h + 0.25, 0.14), Vector3.ZERO, 0.35)
	shape = Geo.solid(solids, Vector3(w, h, 0.12), Vector3(0, h / 2, 0))
	var z := Geo.act_zone(pivot, Vector3(w, h, 0.3), Vector3(w / 2, h / 2, 0), "obj")
	z.set_meta("obj", self)
	if start_open: open = 1.0; target = 1.0
	_apply()

func _apply() -> void:
	pivot.rotation.y = -open * 1.8
	## закрытая дверь — стена; при закрывании проход освобождается только почти в конце
	shape.disabled = open > (0.5 if target > 0.5 else 0.08)

func prompt_text() -> String:
	if target > 0.5: return "E — закрыть дверь"
	return ("%s · %s" % [label_text, locked_text] if label_text != "" else locked_text) if locked else "E — открыть дверь"

func use(_main) -> void:
	if locked:
		sfx("click"); _main.G.toast(locked_text); return
	if target < 0.5:
		target = 1.0; sfx("door", -4.0)
	else:
		target = 0.0; sfx("door", -6.0, 1.15)

func _process(dt: float) -> void:
	if Engine.is_editor_hint() or pivot == null: return
	if absf(open - target) > 0.001:
		open += (target - open) * minf(1.0, dt * 2.4)
		_apply()
