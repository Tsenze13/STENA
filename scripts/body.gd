## Тело героя. Ноги — в мире (видно, если посмотреть вниз). Руки — в слое 2: их рисует отдельная камера
## поверх мира, чтобы они не проваливались в стены. Правая рука держит фонарик, на левой — ПТ-1.
class_name Body
extends Node3D

var player: Player
var wrist: Wrist
var vm := Node3D.new()          # руки; каждый кадр встаёт на место камеры
var R := Node3D.new()           # правая рука
var L := Node3D.new()           # левая рука
var legs := []
var legs_root := Node3D.new()
var lens: MeshInstance3D
var screen: MeshInstance3D
var wrist_glow := OmniLight3D.new()
var reach_t := 0.0
var sway := Vector2.ZERO
var last_yaw := 0.0
var last_pitch := 0.0
var busy := false
var tip := Vector3.ZERO

var P_R := {}
var P_L := {}

func _mat(c: Color, rough := 0.85, metal := 0.0) -> StandardMaterial3D:
	return Tex.plain("body_%s" % c.to_html(), c, rough, metal)

func setup(p: Player, w: Wrist, wrist_tex: Texture2D) -> void:
	player = p; wrist = w
	var cloth := Tex.surface("cloth", Color(0.17, 0.23, 0.33), 0.95, 0.0, 6.0, 0.4, 1.0, 31, 0.08)
	var cloth_d := Tex.surface("cloth_d", Color(0.13, 0.17, 0.24), 0.95, 0.0, 6.0, 0.4, 1.0, 32, 0.08)
	var glove := Tex.surface("glove", Color(0.42, 0.29, 0.18), 0.75, 0.0, 8.0, 0.3, 1.5, 33, 0.1)
	var boot := _mat(Color(0.1, 0.1, 0.09), 0.6)
	## ---------- ноги ----------
	add_child(legs_root)
	for s in [-1.0, 1.0]:
		var hip := Node3D.new(); hip.position = Vector3(s * 0.1, 0.9, -0.04); legs_root.add_child(hip)
		var th := MeshInstance3D.new(); var c1 := CapsuleMesh.new(); c1.radius = 0.075; c1.height = 0.43; th.mesh = c1; th.material_override = cloth; th.position.y = -0.21; hip.add_child(th)
		var knee := Node3D.new(); knee.position.y = -0.43; hip.add_child(knee)
		var sh := MeshInstance3D.new(); var c2 := CapsuleMesh.new(); c2.radius = 0.065; c2.height = 0.41; sh.mesh = c2; sh.material_override = cloth; sh.position.y = -0.2; knee.add_child(sh)
		Geo.cyl_node(knee, 0.07, 0.072, 0.06, cloth_d, Vector3(0, -0.33, 0))
		Geo.box_node(knee, Vector3(0.12, 0.1, 0.27), boot, Vector3(0, -0.4, -0.05))
		Geo.box_node(knee, Vector3(0.125, 0.03, 0.28), _mat(Color(0.04, 0.04, 0.04)), Vector3(0, -0.445, -0.05))
		legs.append({"hip": hip, "knee": knee, "s": s})
	## ---------- руки ----------
	add_child(vm)
	vm.add_child(R); vm.add_child(L)
	_forearm(R, cloth, cloth_d)
	var rh := _hand(R, glove, true, -1.0); rh.position = Vector3(0, 0, -0.34)
	var fl := Node3D.new(); fl.position = Vector3(0, 0.005, -0.36); R.add_child(fl)
	Geo.cyl_node(fl, 0.022, 0.022, 0.2, _mat(Color(0.16, 0.16, 0.15), 0.4, 0.6), Vector3(0, 0, -0.03), Vector3(PI / 2, 0, 0), 14)
	Geo.cyl_node(fl, 0.034, 0.024, 0.06, _mat(Color(0.22, 0.22, 0.2), 0.3, 0.7), Vector3(0, 0, -0.15), Vector3(-PI / 2, 0, 0), 14)
	lens = Geo.cyl_node(fl, 0.03, 0.03, 0.004, Tex.glow("lens_off", Color(0.12, 0.12, 0.12)), Vector3(0, 0, -0.181), Vector3(PI / 2, 0, 0), 16)
	Geo.box_node(fl, Vector3(0.01, 0.012, 0.02), _mat(Color(0.6, 0.16, 0.1)), Vector3(0, 0.024, 0))
	tip = Vector3(0, 0.005, -0.55)

	_forearm(L, cloth, cloth_d)
	var lh := _hand(L, glove, false, 1.0); lh.position = Vector3(0, 0, -0.34)
	var dev := Node3D.new(); dev.position = Vector3(0, 0.06, -0.16); dev.scale = Vector3.ONE * 1.3; L.add_child(dev)
	Geo.box_node(dev, Vector3(0.11, 0.035, 0.165), Tex.metal("dev", Color(0.36, 0.37, 0.33)))
	Geo.box_node(dev, Vector3(0.09, 0.004, 0.128), _mat(Color(0.05, 0.05, 0.05), 0.3), Vector3(0, 0.019, 0))
	var sm := StandardMaterial3D.new(); sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; sm.albedo_texture = wrist_tex
	screen = MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(0.11, 0.0733); screen.mesh = pm; screen.material_override = sm
	screen.position = Vector3(0, 0.0215, 0); screen.rotation.y = PI / 2; dev.add_child(screen)
	for t in [[0.065, Color(0.75, 0.22, 0.17)], [0.045, Color(0.88, 0.69, 0.13)]]:
		Geo.cyl_node(dev, 0.006, 0.006, 0.012, _mat(t[1]), Vector3(0.058, 0, t[0]), Vector3(0, 0, PI / 2), 8)
	Geo.cyl_node(dev, 0.01, 0.01, 0.014, _mat(Color(0.55, 0.52, 0.48), 0.35, 0.8), Vector3(-0.058, 0, 0.06), Vector3(0, 0, PI / 2), 10)
	Geo.cyl_node(dev, 0.004, 0.004, 0.05, _mat(Color(0.05, 0.05, 0.05)), Vector3(0.03, 0.03, 0.09), Vector3(0.4, 0, 0), 6)
	for z in [-0.06, 0.06]:
		Geo.cyl_node(L, 0.052, 0.052, 0.02, _mat(Color(0.1, 0.1, 0.09), 0.6), Vector3(0, 0, -0.16 + z), Vector3(PI / 2, 0, 0), 14)
	## спиральный кабель от разъёма назад
	var pts := PackedVector3Array()
	for i in 61:
		var tt := i / 60.0; var a := tt * 40.0
		pts.append(Vector3(-0.07 + cos(a) * 0.01, sin(a) * 0.01 - tt * 0.1, -0.1 + tt * 0.32))
	var coil := MeshInstance3D.new(); coil.mesh = Geo.tube(pts, 0.004, 5, 1); coil.material_override = Tex.cable(); L.add_child(coil)
	wrist_glow.light_color = Color(0.43, 1, 0.54); wrist_glow.omni_range = 4.5; wrist_glow.light_energy = 0
	wrist_glow.light_volumetric_fog_energy = 0.5
	add_child(wrist_glow)

	## позы рук в пространстве камеры
	P_R = {"rest": _pose(Vector3(0.24, -0.27, -0.1), Vector3(0.1, 0.06, 0)), "reach": _pose(Vector3(0.12, -0.2, -0.22), Vector3(0.2, 0.05, 0)), "low": _pose(Vector3(0.27, -0.5, -0.02), Vector3(-0.4, 0.1, 0))}
	var raised_b := Basis(Vector3(0, -1, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0))
	raised_b = Basis(Vector3.RIGHT, -0.32) * raised_b
	P_L = {"rest": _pose(Vector3(-0.27, -0.42, -0.06), Vector3(0.12, -0.18, 0.15)), "raised": {"p": Vector3(-0.2, -0.15, -0.38), "q": raised_b.get_rotation_quaternion()}}
	R.position = P_R.rest.p; R.quaternion = P_R.rest.q
	L.position = P_L.rest.p; L.quaternion = P_L.rest.q
	_viewmodel(vm)

func _pose(p: Vector3, r: Vector3) -> Dictionary:
	return {"p": p, "q": Basis.from_euler(r, EULER_ORDER_YXZ).get_rotation_quaternion()}

## руки рисуются той же камерой, но их глубина «сжата» к камере — в стены они не проваливаются
func _viewmodel(n: Node) -> void:
	if n is MeshInstance3D and n.material_override:
		var m: BaseMaterial3D = n.material_override.duplicate()
		m.use_z_clip_scale = true
		m.z_clip_scale = 0.12
		n.material_override = m
		n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for c in n.get_children():
		_viewmodel(c)

func _forearm(parent: Node3D, cloth: Material, cloth_d: Material) -> void:
	Geo.cyl_node(parent, 0.04, 0.047, 0.3, cloth, Vector3(0, 0, -0.15), Vector3(PI / 2, 0, 0), 12)
	Geo.cyl_node(parent, 0.05, 0.05, 0.04, cloth_d, Vector3(0, 0, -0.27), Vector3(PI / 2, 0, 0), 12)
	Geo.cyl_node(parent, 0.055, 0.05, 0.34, cloth, Vector3(0.03, -0.03, 0.15), Vector3(PI / 2 + 0.3, 0, 0.1), 12)

## перчатка: ладонь и пальцы; grip — сжатые в хват
func _hand(parent: Node3D, glove: Material, grip: bool, side: float) -> Node3D:
	var h := Node3D.new(); parent.add_child(h)
	Geo.box_node(h, Vector3(0.085, 0.032, 0.095), glove)
	for i in 4:
		var f := Node3D.new(); f.position = Vector3(-0.03 + i * 0.02, 0, -0.045); h.add_child(f)
		Geo.box_node(f, Vector3(0.017, 0.02, 0.045), glove, Vector3(0, 0, -0.022))
		var f2 := Node3D.new(); f2.position = Vector3(0, 0, -0.045); f.add_child(f2)
		Geo.box_node(f2, Vector3(0.016, 0.019, 0.035), glove, Vector3(0, 0, -0.016))
		f.rotation.x = -1.2 if grip else -0.25
		f2.rotation.x = -1.3 if grip else -0.3
	var th := Node3D.new(); th.position = Vector3(side * 0.045, 0, -0.01); h.add_child(th)
	Geo.box_node(th, Vector3(0.02, 0.022, 0.05), glove, Vector3(0, 0, -0.022))
	th.rotation = Vector3(-0.6 if grip else 0.0, side * 0.5, 0)
	Geo.cyl_node(h, 0.05, 0.048, 0.05, glove, Vector3(0, 0, 0.06), Vector3(PI / 2, 0, 0), 12)
	return h

func reach() -> void:
	reach_t = 0.45

## каждый кадр после игрока
func update(dt: float, cam: Camera3D) -> void:
	## ноги
	legs_root.global_position = Vector3(player.global_position.x, 0, player.global_position.z)
	legs_root.rotation.y = player.yaw
	var k: float = min(1.0, player.speed / 2.2)
	for g in legs:
		var ph: float = player.bob + (PI if g.s > 0 else 0.0)
		g.hip.rotation.x = sin(ph) * 0.5 * k
		g.knee.rotation.x = -max(0.0, sin(ph + PI / 2)) * 0.75 * k
	## руки следуют за камерой
	vm.global_transform = cam.global_transform
	var dy: float = wrapf(player.yaw - last_yaw, -PI, PI)
	sway.x += (-dy * 0.6 - sway.x) * min(1.0, dt * 8.0)
	sway.y += ((player.pitch - last_pitch) * 0.6 - sway.y) * min(1.0, dt * 8.0)
	last_yaw = player.yaw; last_pitch = player.pitch
	var bx := sin(player.bob) * 0.012 * k
	var by := -absf(cos(player.bob)) * 0.012 * k
	var s := Vector3(clamp(sway.x, -0.06, 0.06) + bx, clamp(sway.y, -0.05, 0.05) + by, 0)
	reach_t = max(0.0, reach_t - dt)
	var rt: Dictionary = P_R.reach if reach_t > 0 else (P_R.low if busy else P_R.rest)
	var a: float = min(1.0, dt * (14.0 if reach_t > 0 else 8.0))
	R.position = R.position.lerp(rt.p + s, a)
	R.quaternion = R.quaternion.slerp(rt.q, a)
	var lt: Dictionary = P_L.raised if (wrist.raised and not busy) else P_L.rest
	var b: float = min(1.0, dt * 9.0)
	L.position = L.position.lerp(lt.p + s * 0.7, b)
	L.quaternion = L.quaternion.slerp(lt.q, b)
	## экран ПТ-1 и его свет
	var glow_k := 1.0 if wrist.raised else ((0.5 if sin(Time.get_ticks_msec() / 160.0) > 0 else 0.1) if wrist.unread else 0.15)
	screen.material_override.albedo_color = Color.WHITE * (0.55 + 0.45 * glow_k)
	wrist_glow.global_position = cam.global_transform * Vector3(-0.05, -0.2, -0.35)
	wrist_glow.light_energy += ((0.35 if wrist.raised else 0.0) - wrist_glow.light_energy) * min(1.0, dt * 6.0)
	lens.material_override.albedo_color = Color(4, 3.8, 3.4) if player.flash_on else Color(0.12, 0.12, 0.12)
	## луч фонарика выходит из фонарика в руке, бьёт туда, куда смотришь
	var tip_cam := R.transform * tip
	player.flash.position = tip_cam
	player.flash.look_at(cam.global_transform * Vector3(0, -0.6, -8), cam.global_transform.basis.y)
