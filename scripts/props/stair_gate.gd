@tool
## Решётка с электрозамком поперёк прохода (лестница, подвал). Замок с лампой: красная — заперто,
## зелёная — открыто. unlock() открывает замок (её зовёт игра — например, диспетчерская после взятой заявки).
class_name StairGate
extends LevelPart

@export var width := 1.0:
	set(v): width = v; changed()
@export var lock_name := "ЛК-1":
	set(v): lock_name = v; changed()
@export var locked := true
@export_multiline var locked_text := "Решётка заперта. Электрозамок ЛК-1"

var pivot: Node3D
var shape: CollisionShape3D
var lamp: MeshInstance3D
var open := 0.0
var target := 0.0

func _build() -> void:
	var w := width; var h := 2.05
	var bar := Tex.plain("gate", Color(0.22, 0.22, 0.2), 0.45, 0.6)
	B.box(Vector3(0.06, h, 0.06), bar, Vector3(-w / 2, h / 2, 0))
	B.box(Vector3(0.06, h, 0.06), bar, Vector3(w / 2, h / 2, 0))
	pivot = Node3D.new(); pivot.position = Vector3(-w / 2 + 0.03, 0, 0); gen.add_child(pivot)
	var x := 0.08
	while x < w - 0.08:
		Geo.cyl_node(pivot, 0.013, 0.013, h - 0.12, bar, Vector3(x, h / 2, 0), Vector3.ZERO, 5); x += 0.12
	for y in [0.08, 1.0, h - 0.08]:
		Geo.box_node(pivot, Vector3(w - 0.08, 0.04, 0.04), bar, Vector3((w - 0.06) / 2, y, 0))
	## электрозамок с лампой
	Geo.box_node(pivot, Vector3(0.1, 0.16, 0.08), Tex.metal("lock_box", Color(0.3, 0.32, 0.3)), Vector3(w - 0.12, 1.05, 0.05))
	lamp = Geo.cyl_node(pivot, 0.015, 0.015, 0.012, Tex.glow("gate_red", Color(1, 0.15, 0.08), 3.0), Vector3(w - 0.12, 1.1, 0.095), Vector3(PI / 2, 0, 0), 8)
	Geo.paint(pivot, lock_name, 0.05, Color(0.9, 0.85, 0.7), Vector3(w - 0.12, 0.98, 0.092), Vector3.ZERO, 0.2)
	shape = Geo.solid(solids, Vector3(w, h, 0.1), Vector3(0, h / 2, 0))
	var z := Geo.act_zone(pivot, Vector3(w, h, 0.3), Vector3(w / 2, h / 2, 0), "obj")
	z.set_meta("obj", self)
	_apply()

func _apply() -> void:
	pivot.rotation.y = -open * 1.6
	shape.disabled = open > 0.5
	lamp.material_override = Tex.glow("gate_red", Color(1, 0.15, 0.08), 3.0) if locked else Tex.glow("gate_green", Color(0.2, 1, 0.35), 3.0)

func unlock() -> void:
	locked = false; _apply()

func prompt_text() -> String:
	if target > 0.5: return "E — закрыть решётку"
	return locked_text if locked else "E — открыть решётку"

func use(_main) -> void:
	if locked:
		sfx("beep_low", -8.0); _main.G.toast(locked_text.split("\n")[0]); return
	if target < 0.5:
		target = 1.0; sfx("door", -6.0, 1.3)
	else:
		target = 0.0; sfx("door", -8.0, 1.45)

func _process(dt: float) -> void:
	if Engine.is_editor_hint() or pivot == null: return
	if absf(open - target) > 0.001:
		open += (target - open) * minf(1.0, dt * 3.0)
		_apply()
