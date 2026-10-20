## Манекен Quaternius (CC0) для тела героя: один и тот же скелет даёт и ноги/туловище (в мире), и руки
## от первого лица (у камеры). Раскраска и «что показывать» — по костям, в шейдере:
## спецовка синяя, перчатки коричневые, ботинки чёрные; у тела спрятаны руки и голова, у рук — всё, кроме рук.
class_name Mannequin
extends RefCounted

const PATH := "res://assets/anim/Godot/AnimationLibrary_Godot_Standard.glb"
## группы костей: 0 — туловище/ноги, 1 — рукав, 2 — перчатка, 3 — ботинок, 4 — голова/шея
const G_BODY := 0; const G_ARM := 1; const G_HAND := 2; const G_BOOT := 3; const G_HEAD := 4

static var _shader: Shader

static func available() -> bool:
	return ResourceLoader.exists(PATH)

static func _group(bone: String) -> int:
	if bone.begins_with("DEF-f_") or bone.begins_with("DEF-thumb") or bone.begins_with("DEF-hand"): return G_HAND
	## плечо прячем и у рук у камеры: вблизи оно закрывало экран ПТ-1 — видны только предплечья
	if bone.begins_with("DEF-upper_arm") or bone.begins_with("DEF-shoulder"): return G_HEAD
	if bone.begins_with("DEF-forearm"): return G_ARM
	if bone.begins_with("DEF-foot") or bone.begins_with("DEF-toe"): return G_BOOT
	if bone.begins_with("DEF-neck") or bone.begins_with("DEF-head"): return G_HEAD
	return G_BODY

## mode 0 — тело (без рук и головы), 1 — только руки; z_clip — руки не проваливаются в стены
static func make(mode: int, z_clip := 0.0) -> Node3D:
	var ps = load(PATH)
	if ps == null: return null
	var root: Node3D = ps.instantiate()
	if _shader == null:
		_shader = Shader.new()
		_shader.code = """
shader_type spatial;
render_mode cull_back;
uniform vec4 cloth : source_color = vec4(0.16, 0.21, 0.3, 1.0);
uniform vec4 glove : source_color = vec4(0.36, 0.25, 0.15, 1.0);
uniform vec4 boot : source_color = vec4(0.07, 0.07, 0.065, 1.0);
uniform float grp[64];
uniform int mode = 0;
uniform float z_clip = 0.0;
varying float g;
varying float hide;
void vertex() {
	float best = -1.0; int bi = 0;
	for (int i = 0; i < 4; i++) { if (BONE_WEIGHTS[i] > best) { best = BONE_WEIGHTS[i]; bi = int(BONE_INDICES[i]); } }
	g = grp[bi];
	if (mode == 0) hide = (g > 0.5 && g < 2.5) || g > 3.5 ? 1.0 : 0.0;
	else hide = (g > 0.5 && g < 2.5) ? 0.0 : 1.0;
	if (z_clip > 0.0) {
		POSITION = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
		POSITION.z = mix(POSITION.w, POSITION.z, z_clip);
	}
}
void fragment() {
	if (hide > 0.5) discard;
	vec3 c = cloth.rgb;
	if (g > 1.5 && g < 2.5) c = glove.rgb;
	else if (g > 2.5 && g < 3.5) c = boot.rgb;
	ALBEDO = c;
	ROUGHNESS = g > 2.5 ? 0.55 : 0.92;
}
"""
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var skel := mi.get_node_or_null(mi.skeleton) as Skeleton3D
		var arr := PackedFloat32Array(); arr.resize(64)
		if mi.skin and skel:
			for i in mini(mi.skin.get_bind_count(), 64):
				var bn := mi.skin.get_bind_name(i)
				if bn == "" and mi.skin.get_bind_bone(i) >= 0: bn = skel.get_bone_name(mi.skin.get_bind_bone(i))
				arr[i] = _group(bn)
		elif skel:
			for i in mini(skel.get_bone_count(), 64): arr[i] = _group(skel.get_bone_name(i))
		var m := ShaderMaterial.new(); m.shader = _shader
		m.set_shader_parameter("grp", arr); m.set_shader_parameter("mode", mode); m.set_shader_parameter("z_clip", z_clip)
		mi.material_override = m
	return root

## Руки от первого лица: двухзвенная IK. Плечо — из позы манекена, запястье — в цель,
## локоть — ближе к подсказке (pole). Кисть повёрнута как цель (hand_basis).
class Arm:
	var skel: Skeleton3D
	var up_i: int; var fo_i: int; var ha_i: int
	var a := 0.0; var b := 0.0
	var side := 1.0
	func _init(sk: Skeleton3D, s: String) -> void:
		skel = sk
		side = 1.0 if s == "R" else -1.0
		up_i = sk.find_bone("DEF-upper_arm." + s); fo_i = sk.find_bone("DEF-forearm." + s); ha_i = sk.find_bone("DEF-hand." + s)
		var gu := sk.get_bone_global_rest(up_i); var gf := sk.get_bone_global_rest(fo_i); var gh := sk.get_bone_global_rest(ha_i)
		a = gu.origin.distance_to(gf.origin); b = gf.origin.distance_to(gh.origin)

	static func _aim(bs: Basis, dir: Vector3) -> Basis:
		var y := bs.y.normalized()
		var d := dir.normalized()
		if y.dot(d) > 0.99999: return bs
		var axis := y.cross(d)
		if axis.length() < 1e-6: return bs
		return Basis(axis.normalized(), y.angle_to(d)) * bs

	## wrist, pole — в мировых координатах; hand_b — желаемый поворот кисти (мир)
	## shoulder_off — сдвиг плеча (мир): плечо спрятано, его можно вынести вперёд, чтобы предплечье легло удобнее
	func solve(wrist: Vector3, pole: Vector3, hand_b: Basis, shoulder_off := Vector3.ZERO) -> void:
		var inv := skel.global_transform.affine_inverse()
		var W := inv * wrist; var P := inv * pole
		var hb := (inv.basis * hand_b).orthonormalized()
		var gu := skel.get_bone_global_pose(up_i)
		var S := gu.origin + inv.basis * shoulder_off
		var d := clampf(S.distance_to(W), 0.05, (a + b) * 0.999)
		var n := (W - S).normalized()
		var along := (a * a + d * d - b * b) / (2.0 * d)
		var h: float = sqrt(maxf(a * a - along * along, 0.0))
		var pdir := (P - S) - n * (P - S).dot(n)
		if pdir.length() < 1e-5: pdir = Vector3(0, -1, 0)
		var E := S + n * along + pdir.normalized() * h
		## плечо → локоть
		var ub := _aim(gu.basis, E - S)
		var up_g := Transform3D(ub, S)
		skel.set_bone_global_pose(up_i, up_g)
		## локоть → запястье
		var fo_g := up_g * skel.get_bone_pose(fo_i)
		var fb := _aim(fo_g.basis, W - fo_g.origin)
		## поворот предплечья вокруг своей оси — за кистью (половина), чтобы не перекручивалось
		fb = _twist_to(fb, hb, 0.5)
		fo_g = Transform3D(fb, fo_g.origin)
		skel.set_bone_global_pose(fo_i, fo_g)
		## кисть
		var ha_o := (fo_g * skel.get_bone_pose(ha_i)).origin
		skel.set_bone_global_pose(ha_i, Transform3D(hb, ha_o))

	## повернуть bs вокруг его оси Y так, чтобы ось Z смотрела как у target (доля k)
	static func _twist_to(bs: Basis, target: Basis, k: float) -> Basis:
		var y := bs.y.normalized()
		var z0 := (bs.z - y * bs.z.dot(y)).normalized()
		var zt := (target.z - y * target.z.dot(y))
		if zt.length() < 1e-4: return bs
		zt = zt.normalized()
		var ang := z0.signed_angle_to(zt, y) * k
		return Basis(y, ang) * bs

## согнуть пальцы: k = 0 прямые, 1 — кулак
static func curl(skel: Skeleton3D, s: String, k: float, thumb_k: float) -> void:
	for f in ["index", "middle", "ring", "pinky"]:
		for j in ["01", "02", "03"]:
			var i := skel.find_bone("DEF-f_%s.%s.%s" % [f, j, s])
			if i >= 0: skel.set_bone_pose_rotation(i, skel.get_bone_rest(i).basis.get_rotation_quaternion() * Quaternion(Vector3.RIGHT, k * (1.1 if j == "01" else 1.3)))
	for j in ["02", "03"]:
		var i := skel.find_bone("DEF-thumb.%s.%s" % [j, s])
		if i >= 0: skel.set_bone_pose_rotation(i, skel.get_bone_rest(i).basis.get_rotation_quaternion() * Quaternion(Vector3.RIGHT, thumb_k * 0.7))
