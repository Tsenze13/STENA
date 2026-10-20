@tool
## Основа для частей уровня. Каждая часть (подъезд, коридор, щиток, дверь…) — узел в сцене уровня
## scenes/levels/chapter0.tscn. Свою геометрию часть строит сама — и в игре, и прямо в редакторе Godot,
## поэтому уровень видно в редакторе: части можно двигать, копировать (Ctrl+D) и менять настройки в инспекторе.
## Сгенерированные детали лежат во внутреннем узле и в файл сцены не сохраняются.
## После запекания (baked) стены/полы лежат в сцене обычными узлами, код строит только живые детали.
class_name LevelPart
extends Node3D

var B: Geo.Batch
var solids: StaticBody3D
var gen: Node3D
var rng := RandomNumberGenerator.new()
var _queued := false
var _pieces := {}            # имя куска → {B, solids, node}

## «Запечено»: стены, полы и прочая геометрия этой части уже лежат в сцене обычными объектами
## (их можно двигать и удалять в редакторе). Тогда код строит только живое: лампы, надписи, экраны.
@export var baked := false:
	set(v): baked = v; changed()

func _ready() -> void:
	rebuild()

func rebuild() -> void:
	_queued = false
	if is_instance_valid(gen):
		remove_child(gen); gen.queue_free()
	gen = Node3D.new(); gen.name = "_gen"
	add_child(gen, false, Node.INTERNAL_MODE_FRONT)
	_pieces = {}
	piece("Main")
	rng.seed = 1337
	_build()
	for nm in _pieces:
		var pc: Dictionary = _pieces[nm]
		pc.B.build(pc.node)
		if baked and not String(nm).begins_with("Live"):
			gen.remove_child(pc.node); pc.node.queue_free()   # эти куски уже есть в сцене
	_after_build()

## начать именованный кусок: дальше B и solids пишут в него (стены этажа, марш, фасад…).
## Куски с именем на Live… не запекаются: их меняет игра (коллайдер решётки и т.п.)
func piece(name: String) -> void:
	if not _pieces.has(name):
		var n := Node3D.new(); n.name = name; gen.add_child(n)
		var sb := StaticBody3D.new(); sb.name = "Collision"; n.add_child(sb)
		_pieces[name] = {"B": Geo.Batch.new(), "solids": sb, "node": n}
	B = _pieces[name].B; solids = _pieces[name].solids

## куски для запекания (tests/bake.gd)
func pieces() -> Dictionary: return _pieces

## переопределяют части
func _build() -> void: pass
func _after_build() -> void: pass

## настройку поменяли в инспекторе — пересобрать
func changed() -> void:
	if not is_inside_tree() or _queued: return
	_queued = true
	rebuild.call_deferred()

func R(a: float, b: float) -> float: return rng.randf_range(a, b)

## звук (автозагрузка Audio есть только в игре — в редакторе молчим)
func sfx(name: String, db := 0.0, pitch := 1.0) -> void:
	var a = get_node_or_null("/root/Audio")
	if a: a.play(name, db, pitch)

## стена: меш + коллайдер
func wall(size: Vector3, pos: Vector3, mat: Material, collide := true, rot := Vector3.ZERO) -> void:
	B.box(size, mat, pos, rot)
	if collide:
		Geo.solid(solids, size, pos, rot)

func _multi(mesh: Mesh, mat: Material, xfs: Array) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	gen.add_child(mmi)
	return mmi
