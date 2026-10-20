## Игрок: CharacterBody3D, взгляд мышью, ходьба, шаги, покачивание головы, фонарик.
class_name Player
extends CharacterBody3D

var cam := Camera3D.new()
var head := Node3D.new()
var flash := SpotLight3D.new()
var flash_on := false
var yaw := -0.45
var pitch := 0.0
var sens := 1.0
var frozen := false
var bob := 0.0
var step_acc := 0.0
var speed := 0.0
var input_override = null   # для тестов: Vector2 направление движения
var running_override := false
const EYE := 1.65

func _ready() -> void:
	collision_layer = 1
	collision_mask = 1
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new(); cap.radius = 0.3; cap.height = 1.8
	cs.shape = cap; cs.position.y = 0.9
	add_child(cs)
	head.position.y = EYE
	add_child(head)
	cam.fov = 72
	cam.near = 0.04
	cam.far = 2500
	head.add_child(cam)
	flash.light_color = Color(1, 0.95, 0.84)
	flash.spot_range = 22
	flash.spot_angle = 24
	flash.spot_angle_attenuation = 1.2
	flash.light_energy = 0
	flash.shadow_enabled = true
	flash.light_volumetric_fog_energy = 2.0
	cam.add_child(flash)

func toggle_flash() -> void:
	flash_on = not flash_on
	Audio.play("click")

func _input(e: InputEvent) -> void:
	if e is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not frozen:
		var k := 0.0022 * sens
		yaw -= e.relative.x * k
		pitch = clamp(pitch - e.relative.y * k, -1.45, 1.45)

func _physics_process(dt: float) -> void:
	var dir := Vector2.ZERO
	if not frozen:
		if input_override != null:
			dir = input_override
		else:
			dir = Input.get_vector("left", "right", "forward", "back")
	var run := running_override or Input.is_action_pressed("run")
	var sp := 3.6 if run else 1.9
	var basis_y := Basis(Vector3.UP, yaw)
	var want := basis_y * Vector3(dir.x, 0, dir.y)
	if want.length() > 1: want = want.normalized()
	want *= sp
	var a: float = min(1.0, dt * 10.0)
	velocity.x += (want.x - velocity.x) * a
	velocity.z += (want.z - velocity.z) * a
	velocity.y = 0
	var before := global_position
	move_and_slide()
	var moved := Vector2(global_position.x - before.x, global_position.z - before.z).length()
	speed = moved / max(dt, 1e-4)
	if speed > 0.3:
		bob += dt * (11.0 if run else 7.5)
		step_acc += moved
		if step_acc > (0.85 if run else 0.7):
			step_acc = 0
			Audio.play("step", -8.0 if run else -11.0)
	else:
		bob += (round(bob / PI) * PI - bob) * min(1.0, dt * 6.0)
	var bob_a: float = min(speed / 3.6, 1.0) * 0.035
	head.position.y = EYE + abs(sin(bob)) * bob_a
	head.rotation = Vector3(0, yaw, 0)
	cam.rotation = Vector3(pitch, 0, sin(bob) * bob_a * 0.15)
	flash.light_energy += ((6.0 if flash_on else 0.0) - flash.light_energy) * min(1.0, dt * 20.0)

## телепорт (для тестов и отладки)
func tp(x: float, z: float, y_ := yaw, p := 0.0) -> void:
	global_position = Vector3(x, 0, z)
	velocity = Vector3.ZERO
	yaw = y_
	pitch = p
	head.rotation = Vector3(0, yaw, 0)
	cam.rotation = Vector3(pitch, 0, 0)
