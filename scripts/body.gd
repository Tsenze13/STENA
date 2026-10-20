## Тело героя. Ноги — в мире (видно, если посмотреть вниз). Руки — «вьюмодель» в стиле Mortuus:
## крупные угловатые блоки, рисуются той же камерой со сжатием глубины (не проваливаются в стены).
## Правая рука: кулак сжимает фонарик (корпус проходит сквозь ладонь). Левая: ПТ-1 на запястье.
## Анимации: дыхание, покачивание при ходьбе (восьмёрка), бег, инерция при повороте, тянуться к объекту,
## щелчок кнопки фонарика большим пальцем, подъём левой руки к лицу.
class_name Body
extends Node3D

var player: Player
var wrist: Wrist
var vm := Node3D.new()          # корень рук; каждый кадр встаёт на место камеры
var R := Node3D.new()           # правая рука (плечо → локоть → кисть)
var L := Node3D.new()           # левая рука
var r_thumb: Node3D
var legs := []
var legs_root := Node3D.new()
var lens: MeshInstance3D
var screen: MeshInstance3D
var wrist_glow := OmniLight3D.new()
var reach_t := 0.0
var click_t := 0.0
var sway := Vector2.ZERO
var last_yaw := 0.0
var last_pitch := 0.0
var t := 0.0
var run_k := 0.0
var busy := false
var tip := Vector3.ZERO
var P_R := {}
var P_L := {}

func _m(key: String, c: Color, rough := 0.85, metal := 0.0) -> StandardMaterial3D:
	return Tex.plain("vm_" + key, c, rough, metal)

func setup(p: Player, w: Wrist, wrist_tex: Texture2D) -> void:
	player = p; wrist = w
	var cloth := Tex.surface("cloth", Color(0.17, 0.23, 0.33), 0.95, 0.0, 6.0, 0.4, 1.0, 31, 0.08)
	var cloth_d := Tex.surface("cloth_d", Color(0.12, 0.16, 0.23), 0.95, 0.0, 6.0, 0.4, 1.0, 32, 0.08)
	var glove := Tex.surface("glove", Color(0.4, 0.28, 0.17), 0.75, 0.0, 8.0, 0.3, 1.0, 33, 0.1)
	var glove_d := _m("glove_d", Color(0.28, 0.19, 0.11), 0.8)
	var boot := _m("boot", Color(0.1, 0.1, 0.09), 0.6)
	## ---------- ноги ----------
	add_child(legs_root)
	for s in [-1.0, 1.0]:
		var hip := Node3D.new(); hip.position = Vector3(s * 0.1, 0.9, -0.04); legs_root.add_child(hip)
		Geo.box_node(hip, Vector3(0.14, 0.44, 0.15), cloth, Vector3(0, -0.21, 0))
		var knee := Node3D.new(); knee.position.y = -0.43; hip.add_child(knee)
		Geo.box_node(knee, Vector3(0.125, 0.4, 0.13), cloth, Vector3(0, -0.19, 0))
		Geo.box_node(knee, Vector3(0.135, 0.06, 0.14), cloth_d, Vector3(0, -0.33, 0))
		Geo.box_node(knee, Vector3(0.13, 0.11, 0.28), boot, Vector3(0, -0.4, -0.05))
		Geo.box_node(knee, Vector3(0.135, 0.03, 0.29), _m("sole", Color(0.04, 0.04, 0.04)), Vector3(0, -0.455, -0.05))
		legs.append({"hip": hip, "knee": knee, "s": s})

	add_child(vm)
	vm.add_child(R); vm.add_child(L)
	## ---------- правая рука с фонариком ----------
	## узел R — это кисть: фонарик смотрит вперёд, предплечье уходит назад-вниз-вправо к углу экрана
	var hand := Node3D.new(); R.add_child(hand)
	_limb(R, Vector3(0.0, -0.01, 0.06), Vector3(0.13, -0.19, 0.3), 0.1, cloth)
	_limb(R, Vector3(0.0, -0.01, 0.06), Vector3(0.02, -0.035, 0.1), 0.115, cloth_d)       # манжета
	_limb(R, Vector3(0.13, -0.19, 0.3), Vector3(0.22, -0.4, 0.5), 0.12, cloth)            # плечо
	## кулак: ладонь, ряд костяшек сверху-снаружи, пальцы обхватывают корпус снизу
	Geo.box_node(hand, Vector3(0.09, 0.09, 0.1), glove)
	Geo.box_node(hand, Vector3(0.105, 0.035, 0.115), glove_d, Vector3(0, 0.045, 0))           # костяшки
	for i in 4:
		Geo.box_node(hand, Vector3(0.026, 0.05, 0.024), glove, Vector3(0.0, -0.035, -0.04 + i * 0.026), Vector3(0, 0, 0))  # пальцы снизу
	Geo.box_node(hand, Vector3(0.11, 0.04, 0.03), glove_d, Vector3(0, 0, 0.065))               # манжета перчатки
	## большой палец лежит на кнопке сверху — им щёлкаем
	r_thumb = Node3D.new(); r_thumb.position = Vector3(-0.045, 0.045, -0.02); hand.add_child(r_thumb)
	Geo.box_node(r_thumb, Vector3(0.03, 0.028, 0.065), glove, Vector3(0.012, 0.0, -0.03))
	## фонарик: корпус проходит сквозь кулак, голова впереди, хвост сзади
	var fl := Node3D.new(); fl.position = Vector3(-0.005, 0.0, -0.02); hand.add_child(fl)
	var body_m := _m("flash", Color(0.13, 0.13, 0.12), 0.45, 0.6)
	Geo.cyl_node(fl, 0.032, 0.032, 0.27, body_m, Vector3(0, 0, 0.01), Vector3(PI / 2, 0, 0), 8)
	Geo.cyl_node(fl, 0.05, 0.034, 0.08, _m("flash_head", Color(0.2, 0.2, 0.18), 0.35, 0.7), Vector3(0, 0, -0.16), Vector3(-PI / 2, 0, 0), 8)
	Geo.cyl_node(fl, 0.052, 0.052, 0.014, _m("flash_ring", Color(0.45, 0.42, 0.36), 0.3, 0.8), Vector3(0, 0, -0.2), Vector3(PI / 2, 0, 0), 8)
	var lm := StandardMaterial3D.new(); lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; lm.albedo_color = Color(0.12, 0.12, 0.12)
	lens = Geo.cyl_node(fl, 0.043, 0.043, 0.004, lm, Vector3(0, 0, -0.208), Vector3(PI / 2, 0, 0), 8)
	Geo.cyl_node(fl, 0.022, 0.026, 0.03, _m("flash_tail", Color(0.08, 0.08, 0.08), 0.6), Vector3(0, 0, 0.15), Vector3(PI / 2, 0, 0), 8)
	Geo.box_node(fl, Vector3(0.016, 0.012, 0.022), _m("flash_btn", Color(0.65, 0.15, 0.08), 0.5), Vector3(0, 0.03, -0.06))
	tip = hand.position + fl.position + Vector3(0, 0, -0.22)

	## ---------- левая рука с ПТ-1 ----------
	_arm(L, cloth, cloth_d)
	var lh := Node3D.new(); lh.position = Vector3(0, 0, -0.33); L.add_child(lh)
	Geo.box_node(lh, Vector3(0.1, 0.07, 0.11), glove)
	for i in 4:   # пальцы чуть согнуты
		Geo.box_node(lh, Vector3(0.022, 0.03, 0.06), glove, Vector3(-0.036 + i * 0.024, -0.008, -0.075), Vector3(-0.35, 0, 0))
	Geo.box_node(lh, Vector3(0.028, 0.03, 0.06), glove, Vector3(0.06, 0, -0.03), Vector3(0, 0.5, 0))
	Geo.box_node(lh, Vector3(0.11, 0.04, 0.03), glove_d, Vector3(0, 0, 0.065))
	## прибор на предплечье, экраном вверх
	var dev := Node3D.new(); dev.position = Vector3(0, 0.07, -0.17); L.add_child(dev)
	Geo.box_node(dev, Vector3(0.14, 0.045, 0.2), Tex.metal("dev", Color(0.36, 0.37, 0.33)))
	Geo.box_node(dev, Vector3(0.118, 0.006, 0.16), _m("dev_bezel", Color(0.05, 0.05, 0.05), 0.3), Vector3(0, 0.024, 0))
	var sm := StandardMaterial3D.new(); sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; sm.albedo_texture = wrist_tex
	screen = MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(0.15, 0.1); screen.mesh = pm; screen.material_override = sm
	screen.position = Vector3(0, 0.0275, 0); screen.rotation.y = PI / 2; dev.add_child(screen)
	for tg in [[0.07, Color(0.75, 0.22, 0.17)], [0.045, Color(0.88, 0.69, 0.13)]]:
		Geo.box_node(dev, Vector3(0.016, 0.014, 0.014), _m("tog%s" % tg[1].to_html(), tg[1]), Vector3(0.076, 0, tg[0]))
	Geo.box_node(dev, Vector3(0.016, 0.02, 0.02), _m("jack", Color(0.55, 0.52, 0.48), 0.35, 0.8), Vector3(-0.076, 0, 0.07))
	Geo.box_node(dev, Vector3(0.006, 0.06, 0.006), _m("ant", Color(0.05, 0.05, 0.05)), Vector3(0.05, 0.05, 0.095), Vector3(0.4, 0, 0))
	for z in [-0.075, 0.075]:
		Geo.box_node(L, Vector3(0.11, 0.11, 0.022), _m("strap", Color(0.1, 0.1, 0.09), 0.6), Vector3(0, 0.0, -0.17 + z))
	wrist_glow.light_color = Color(0.43, 1, 0.54); wrist_glow.omni_range = 4.5; wrist_glow.light_energy = 0
	wrist_glow.light_volumetric_fog_energy = 0.5
	add_child(wrist_glow)

	## позы (позиция и поворот в пространстве камеры)
	P_R = {
		"rest": _pose(Vector3(0.15, -0.19, -0.42), Vector3(0.04, 0.07, -0.05)),
		"reach": _pose(Vector3(0.09, -0.14, -0.55), Vector3(0.1, 0.04, -0.15)),
		"run": _pose(Vector3(0.19, -0.23, -0.38), Vector3(-0.35, 0.4, -0.45)),
		"low": _pose(Vector3(0.2, -0.55, -0.3), Vector3(-0.6, 0.2, 0)),
	}
	var raised_b := Basis(Vector3(0, -1, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0))
	raised_b = Basis(Vector3.RIGHT, -0.3) * raised_b
	P_L = {
		"rest": _pose(Vector3(-0.3, -0.55, -0.2), Vector3(0.1, -0.25, 0.2)),
		"raised": {"p": Vector3(-0.08, -0.22, -0.58), "q": raised_b.get_rotation_quaternion()},
	}
	R.position = P_R.rest.p; R.quaternion = P_R.rest.q
	L.position = P_L.rest.p; L.quaternion = P_L.rest.q
	_viewmodel(vm)
	## тело не отбрасывает теней: иначе в объёмном тумане над головой видны тёмные «лучи» от ног
	for n in legs_root.find_children("*", "GeometryInstance3D", true, false):
		n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for n in vm.find_children("*", "GeometryInstance3D", true, false):
		n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _pose(p: Vector3, r: Vector3) -> Dictionary:
	return {"p": p, "q": Basis.from_euler(r, EULER_ORDER_YXZ).get_rotation_quaternion()}

## брусок от точки a до точки b (рукав), толщина th
func _limb(parent: Node3D, a: Vector3, b: Vector3, th: float, mat: Material) -> void:
	var mi := Geo.box_node(parent, Vector3(th, th, a.distance_to(b)), mat, (a + b) / 2)
	mi.look_at_from_position((a + b) / 2, b, Vector3.UP)

## предплечье и плечо блоками: рукав спецовки, манжета, уходящее назад плечо
func _arm(parent: Node3D, cloth: Material, cloth_d: Material) -> void:
	Geo.box_node(parent, Vector3(0.1, 0.1, 0.3), cloth, Vector3(0, 0, -0.13))
	Geo.box_node(parent, Vector3(0.112, 0.112, 0.05), cloth_d, Vector3(0, 0, -0.26))           # манжета
	Geo.box_node(parent, Vector3(0.115, 0.115, 0.22), cloth, Vector3(0.015, -0.05, 0.09), Vector3(0.45, 0, 0.08))  # плечо
	Geo.box_node(parent, Vector3(0.102, 0.03, 0.2), cloth_d, Vector3(0, 0.051, -0.1))            # шов/складка сверху

## руки рисуются той же камерой, но их глубина «сжата» к камере — в стены они не проваливаются
func _viewmodel(n: Node) -> void:
	if n is MeshInstance3D and n.material_override:
		var m: BaseMaterial3D = n.material_override.duplicate()
		m.use_z_clip_scale = true
		if m.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED:
			m.emission_enabled = true; m.emission = m.albedo_color * 0.06
		m.z_clip_scale = 0.12
		n.material_override = m
		n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for c in n.get_children():
		_viewmodel(c)

func reach() -> void:
	reach_t = 0.45

## щелчок кнопки фонарика
func click() -> void:
	click_t = 0.18

func _wrap_lerp(cur: Node3D, target: Dictionary, off: Vector3, rot_off: Vector3, a: float) -> void:
	cur.position = cur.position.lerp(target.p + off, a)
	var q: Quaternion = target.q * Basis.from_euler(rot_off).get_rotation_quaternion()
	cur.quaternion = cur.quaternion.slerp(q, a)

## каждый кадр после игрока
func update(dt: float, cam: Camera3D) -> void:
	t += dt
	## ноги
	legs_root.global_position = player.global_position
	legs_root.rotation.y = player.yaw
	var k: float = min(1.0, player.speed / 2.2)
	for g in legs:
		var ph: float = player.bob + (PI if g.s > 0 else 0.0)
		g.hip.rotation.x = sin(ph) * 0.5 * k
		g.knee.rotation.x = -max(0.0, sin(ph + PI / 2)) * 0.75 * k
	## корень рук = камера
	vm.global_transform = cam.global_transform
	## инерция при повороте головы
	var dy: float = wrapf(player.yaw - last_yaw, -PI, PI)
	sway.x += (-dy * 0.9 - sway.x) * min(1.0, dt * 7.0)
	sway.y += ((player.pitch - last_pitch) * 0.9 - sway.y) * min(1.0, dt * 7.0)
	last_yaw = player.yaw; last_pitch = player.pitch
	var sx: float = clamp(sway.x, -0.07, 0.07)
	var sy: float = clamp(sway.y, -0.06, 0.06)
	## бег: руки уходят вниз и вбок, качаются сильнее
	var running: bool = player.speed > 2.8
	run_k += ((1.0 if running else 0.0) - run_k) * min(1.0, dt * 6.0)
	## покачивание при ходьбе: восьмёрка (вбок на каждый шаг, вниз на каждый шаг вдвое чаще)
	var amp := 0.014 + 0.02 * run_k
	var bx: float = sin(player.bob) * amp * k
	var by := -absf(sin(player.bob)) * amp * 0.8 * k
	var roll := sin(player.bob) * 0.04 * k
	## дыхание стоя
	var br := sin(t * 1.6) * 0.004 * (1.0 - k)
	var off := Vector3(sx + bx, sy + by + br, 0)
	var rot_off := Vector3(-sy * 2.0 + br * 2.0, sx * 2.0, roll + sx * 1.5)
	## правая рука
	reach_t = max(0.0, reach_t - dt)
	click_t = max(0.0, click_t - dt)
	var rt: Dictionary = P_R.rest
	if busy or (wrist.raised and run_k < 0.5): rt = P_R.low
	elif reach_t > 0: rt = P_R.reach
	elif run_k > 0.5: rt = P_R.run
	var a: float = min(1.0, dt * (14.0 if reach_t > 0 else 9.0))
	var click_dip := Vector3(0, -0.012, 0.01) * (click_t / 0.18)
	_wrap_lerp(R, rt, off + click_dip, rot_off, a)
	r_thumb.position.y = 0.045 - 0.012 * (click_t / 0.18)
	## левая рука с ПТ-1: при беге не поднимается
	var lt: Dictionary = P_L.raised if (wrist.raised and not busy and run_k < 0.5) else P_L.rest
	var b: float = min(1.0, dt * 9.0)
	_wrap_lerp(L, lt, Vector3(sx * 0.7 - bx * 0.6, sy * 0.7 + by, 0), rot_off * 0.6, b)
	## экран ПТ-1 и его свет
	var glow_k := 1.0 if wrist.raised else ((0.5 if sin(Time.get_ticks_msec() / 160.0) > 0 else 0.1) if wrist.unread else 0.15)
	screen.material_override.albedo_color = Color.WHITE * (0.55 + 0.45 * glow_k)
	wrist_glow.global_position = cam.global_transform * Vector3(-0.05, -0.2, -0.35)
	wrist_glow.light_energy += ((0.35 if wrist.raised else 0.0) - wrist_glow.light_energy) * min(1.0, dt * 6.0)
	lens.material_override.albedo_color = Color(4, 3.8, 3.4) if player.flash_on else Color(0.12, 0.12, 0.12)
	## луч фонарика выходит из головы фонарика и бьёт туда, куда смотришь
	player.flash.position = R.transform * tip
	player.flash.look_at(cam.global_transform * Vector3(0, -0.5, -8), cam.global_transform.basis.y)
