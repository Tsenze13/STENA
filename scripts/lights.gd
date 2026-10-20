## Свет: у каждой лампы уровень 0..1. Настоящих источников немного (POOL): каждый кадр они встают
## на самые заметные лампы рядом с игроком. Два ближайших — с тенями. Остальное делают свечение и «звёздочки».
class_name Lights
extends Node3D

const POOL := 8
const KIND := {
	"wall": {"col": Color(0.86, 0.92, 1.0), "I": 2.2, "range": 15.0, "glow": Color(2.2, 2.4, 2.8), "star": Color(0.55, 0.62, 0.72)},
	"dome": {"col": Color(1.0, 0.85, 0.62), "I": 5.0, "range": 26.0, "glow": Color(3.0, 2.5, 1.8), "star": Color(0.8, 0.62, 0.4)},
	"em":   {"col": Color(1.0, 0.16, 0.08), "I": 0.7, "range": 9.0, "glow": Color(3.0, 0.4, 0.2), "star": Color(0.9, 0.12, 0.05)},
	"bulb": {"col": Color(1.0, 0.78, 0.5), "I": 1.2, "range": 8.0, "glow": Color(1, 0.8, 0.5), "star": Color(0.9, 0.6, 0.3)},
	"tube": {"col": Color(0.95, 0.95, 0.9), "I": 2.4, "range": 10.0, "glow": Color(1, 1, 1), "star": Color(0.6, 0.7, 0.8)},
	"sodium": {"col": Color(1.0, 0.6, 0.28), "I": 4.0, "range": 20.0, "glow": Color(1, 0.6, 0.3), "star": Color(1.0, 0.55, 0.2)},
}

var W: World
var pool: Array[OmniLight3D] = []
var t := 0.0
var near := 0.0          # сколько света возле камеры (для пыли)
var on_relay: Callable    # щелчок реле, когда лампа включается

func setup(world: World) -> void:
	W = world
	for i in POOL:
		var l := OmniLight3D.new()
		l.light_energy = 0
		l.omni_attenuation = 1.6
		l.shadow_enabled = false
		l.light_volumetric_fog_energy = 1.5
		add_child(l)
		pool.append(l)

## включить/выключить группу; stagger — задержка между соседними (дальше — быстрее, свет «бежит» к горизонту)
func set_group(grp: String, on: bool, stagger := 0.0, from_z := 0.0) -> void:
	var list := W.lamps.filter(func(l): return l.grp == grp)
	list.sort_custom(func(a, b): return abs(a.pos.z - from_z) < abs(b.pos.z - from_z))
	var k := 0
	for l in list:
		if l.on == (1 if on else 0):
			continue
		l.on = 1 if on else 0
		l.delay = stagger * pow(k, 0.75)
		k += 1
		l.fl = 0.3 + randf() * 0.9 if on and (l.kind == "wall" or l.kind == "dome") else 0.0
		l.clicked = false

func update(dt: float, cam_pos: Vector3) -> void:
	t += dt
	for l in W.lamps:
		if l.delay > 0:
			l.delay -= dt
			continue
		if not l.get("clicked", true):
			l.clicked = true
			if l.on and on_relay.is_valid():
				on_relay.call(l)
		var target := float(l.on)
		if l.on and l.fl > 0:
			l.fl -= dt
			target = 1.0 if randf() < 0.45 else 0.05
		if (l.kind == "bulb" or l.kind == "tube") and l.on:
			target = 0.85 + sin(t * 13) * 0.04 + (-0.5 if randf() < 0.01 else 0.0)
			## старая лампа мигает
			if l.get("flicker", false) and randf() < 0.08: target = 0.05 if randf() < 0.6 else 1.0
		if l.kind == "em" and l.on:
			target = 0.75 + sin(t * 1.3 + l.pos.z) * 0.08
		if l.get("dead", false):
			target = 0.0
		var sp := 30.0 if (l.kind == "wall" or l.kind == "dome") else 8.0
		l.lvl += (target - l.lvl) * min(1.0, dt * sp)
		var K: Dictionary = KIND[l.kind]
		if l.has("inst"):
			var c: Color = K.glow * l.lvl if l.lvl > 0.05 else Color(0.03, 0.03, 0.03)
			W.lamp_mm[l.kind].set_instance_color(l.inst, c)
		W.star_mm.set_instance_color(l.star, Color(K.star.r, K.star.g, K.star.b, 1.0) * l.lvl)
	## лампочки с собственным мешем (подъезд, улица): яркость стекла
	for l in W.lamps:
		if l.has("mesh"):
			var c: Color = l.get("tint", Color(1, 0.85, 0.6))
			l.mesh.material_override.albedo_color = c * (0.08 + 4.0 * l.lvl)

	## выбор источников: заметность = сила / квадрат расстояния
	var best := []
	for l in W.lamps:
		if l.lvl < 0.02:
			continue
		var d2: float = (l.pos.x - cam_pos.x) ** 2 + ((l.pos.y - cam_pos.y) * 1.5) ** 2 + (l.pos.z - cam_pos.z) ** 2
		if d2 > 1600:
			continue
		var s: float = KIND[l.kind].I * l.lvl / (d2 + 4.0)
		if best.size() < POOL or s > best[best.size() - 1][1]:
			best.append([l, s])
			best.sort_custom(func(a, b): return a[1] > b[1])
			if best.size() > POOL:
				best.pop_back()
	near = 0.0
	for b in best:
		var l: Dictionary = b[0]
		near += KIND[l.kind].I * l.lvl / (l.pos.distance_squared_to(cam_pos) + 1.0)
	for i in POOL:
		var p := pool[i]
		if i >= best.size():
			p.light_energy = 0
			p.visible = false
			continue
		var l: Dictionary = best[i][0]
		var K: Dictionary = KIND[l.kind]
		p.visible = true
		p.position = l.pos
		p.light_color = K.col
		p.omni_range = K.range
		p.light_energy = K.I * l.lvl
		p.shadow_enabled = i < 2 and l.kind != "em"
