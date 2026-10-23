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
## высота модели в метрах (0 — как в файле). Модели с разных сайтов бывают в сантиметрах или огромные —
## здесь задаёшь настоящий размер, и модель сама масштабируется
@export var height := 0.0:
	set(v): height = v; _queue()
## поставить модель низом на пол и серединой в точку узла
@export var on_ground := false:
	set(v): on_ground = v; _queue()
## поворот самой модели внутри предмета (если в файле она лежит на боку или смотрит не туда), градусы
@export var model_rotation := Vector3.ZERO:
	set(v): model_rotation = v; _queue()

## для рук от первого лица: рисовать поверх стен (как руки) и без теней
@export var viewmodel := false:
	set(v): viewmodel = v; _queue()

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
	var inst: Node3D = model.instantiate()
	_gen.add_child(inst)
	inst.rotation_degrees = model_rotation
	var acc := [null]
	var refit := height > 0.0 or on_ground
	_walk(inst, inst.transform, acc, true, not refit)
	if acc[0] != null and refit:
		var b: AABB = acc[0]
		var k := height / maxf(b.size.y, 1e-4) if height > 0.0 else 1.0
		inst.scale = Vector3.ONE * k
		var c := b.get_center() * k
		inst.position = Vector3(-c.x, -b.position.y * k, -c.z) if on_ground else Vector3.ZERO
		acc = [null]
		_walk(inst, inst.transform, acc)
	if viewmodel:
		for mi in inst.find_children("*", "MeshInstance3D", true, false):
			var m3 := mi as MeshInstance3D
			m3.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			for si in m3.mesh.get_surface_count():
				var mt = m3.get_active_material(si)
				if mt is BaseMaterial3D:
					var c2: BaseMaterial3D = mt.duplicate(); c2.use_z_clip_scale = true; c2.z_clip_scale = 0.12
					m3.set_surface_override_material(si, c2)
	if collide and acc[0] != null:
		var b: AABB = acc[0]
		var body := StaticBody3D.new(); _gen.add_child(body)
		var cs := CollisionShape3D.new(); var sh := BoxShape3D.new()
		sh.size = b.size.max(Vector3.ONE * 0.05); cs.shape = sh; cs.position = b.get_center()
		body.add_child(cs)

## размеры модели (для коллайдера) и подкраска материалов
func _walk(n: Node, xf: Transform3D, acc: Array, first := true, do_tint := true) -> void:
	var t := xf
	if n is Node3D and not first: t = xf * (n as Node3D).transform
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		var mi := n as MeshInstance3D
		var b: AABB = t * mi.mesh.get_aabb()
		acc[0] = b if acc[0] == null else (acc[0] as AABB).merge(b)
		if do_tint and tint != Color(1, 1, 1):
			for s in mi.mesh.get_surface_count():
				var m = mi.get_active_material(s)
				if m is StandardMaterial3D:
					var c: StandardMaterial3D = m.duplicate()
					c.albedo_color = c.albedo_color * tint
					mi.set_surface_override_material(s, c)
	for c in n.get_children(): _walk(c, t, acc, false, do_tint)
