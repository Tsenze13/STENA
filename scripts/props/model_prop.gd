@tool
## Готовая 3D-модель из assets/models (Poly Haven, CC0) как предмет уровня.
## В инспекторе: Model — какая модель (перетащи .gltf из assets/models), Collide — твёрдая ли она
## (по ней нельзя пройти насквозь), Tint — подкрасить (белый = как есть).
## Двигать, поворачивать, копировать (Ctrl+D) — как любой предмет.
class_name ModelProp
extends Node3D

@export var model: PackedScene:
	set(v): model = v; _queue()
@export var collide := true:
	set(v): collide = v; _queue()
## подкраска: темнее/грязнее, чтобы модель не выбивалась из окружения
@export var tint := Color(1, 1, 1):
	set(v): tint = v; _queue()

var _gen: Node3D
var _queued := false

func _ready() -> void:
	_build()

func _queue() -> void:
	if not is_inside_tree() or _queued: return
	_queued = true
	_build.call_deferred()

func _build() -> void:
	_queued = false
	if is_instance_valid(_gen):
		remove_child(_gen); _gen.queue_free()
	_gen = Node3D.new(); _gen.name = "_gen"
	add_child(_gen, false, Node.INTERNAL_MODE_FRONT)
	if model == null: return
	var inst := model.instantiate()
	_gen.add_child(inst)
	var acc := [null]
	_walk(inst, Transform3D(), acc)
	if collide and acc[0] != null:
		var b: AABB = acc[0]
		var body := StaticBody3D.new(); _gen.add_child(body)
		var cs := CollisionShape3D.new(); var sh := BoxShape3D.new()
		sh.size = b.size.max(Vector3.ONE * 0.05); cs.shape = sh; cs.position = b.get_center()
		body.add_child(cs)

## размеры модели (для коллайдера) и подкраска материалов
func _walk(n: Node, xf: Transform3D, acc: Array) -> void:
	var t := xf
	if n is Node3D: t = xf * (n as Node3D).transform
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		var mi := n as MeshInstance3D
		var b: AABB = t * mi.mesh.get_aabb()
		acc[0] = b if acc[0] == null else (acc[0] as AABB).merge(b)
		if tint != Color(1, 1, 1):
			for s in mi.mesh.get_surface_count():
				var m = mi.get_active_material(s)
				if m is StandardMaterial3D:
					var c: StandardMaterial3D = m.duplicate()
					c.albedo_color = c.albedo_color * tint
					mi.set_surface_override_material(s, c)
	for c in n.get_children(): _walk(c, t, acc)
