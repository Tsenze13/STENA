@tool
## Основа для частей уровня. Каждая часть (подъезд, коридор, щиток, дверь…) — узел в сцене уровня
## scenes/levels/chapter0.tscn. Свою геометрию часть строит сама — и в игре, и прямо в редакторе Godot,
## поэтому уровень видно в редакторе: части можно двигать, копировать (Ctrl+D) и менять настройки в инспекторе.
## Сгенерированные детали лежат во внутреннем узле и в файл сцены не сохраняются.
class_name LevelPart
extends Node3D

var B: Geo.Batch
var solids: StaticBody3D
var gen: Node3D
var rng := RandomNumberGenerator.new()
var _queued := false

func _ready() -> void:
	rebuild()

func rebuild() -> void:
	_queued = false
	if is_instance_valid(gen):
		remove_child(gen); gen.queue_free()
	gen = Node3D.new(); gen.name = "_gen"
	add_child(gen, false, Node.INTERNAL_MODE_FRONT)
	B = Geo.Batch.new()
	solids = StaticBody3D.new(); gen.add_child(solids)
	rng.seed = 1337
	_build()
	B.build(gen)
	_after_build()

## переопределяют части
func _build() -> void: pass
func _after_build() -> void: pass

## настройку поменяли в инспекторе — пересобрать
func changed() -> void:
	if not is_inside_tree() or _queued: return
	_queued = true
	rebuild.call_deferred()

func R(a: float, b: float) -> float: return rng.randf_range(a, b)

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
