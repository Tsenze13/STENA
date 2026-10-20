## Просмотр моделей Sketchfab в ряд с подписями: -- res://tests/models_preview.tscn -- --out=/папка
extends Node3D
const H := {"breaker_panel": 0.8, "cell_door": 2.2, "extinguisher": 0.55, "flashlight": 0.12, "herm_door": 2.2,
	"hose_cabinet": 0.8, "kung_truck": 3.2, "lamps_soviet": 0.5, "metal_door": 2.1, "terminal_small": 0.5,
	"terminal_tall": 1.9, "tube_lamp": 0.12, "wall_lamp": 0.45, "wood_door": 2.1}
func _ready() -> void:
	var out := "."
	for a in OS.get_cmdline_user_args(): if a.begins_with("--out="): out = a.substr(6)
	var env := WorldEnvironment.new(); env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color(0.3, 0.3, 0.33)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.environment.ambient_light_color = Color(0.5, 0.5, 0.5)
	add_child(env)
	var sun := DirectionalLight3D.new(); sun.rotation = Vector3(-0.7, 0.5, 0); add_child(sun)
	var cam := Camera3D.new(); add_child(cam)
	for k in H:
		var mp := ModelProp.new(); mp.model = load("res://assets/sketchfab/%s/scene.gltf" % k)
		mp.height = H[k]; mp.on_ground = true; mp.collide = false
		add_child(mp)
		var h: float = H[k]
		var d := maxf(h, 0.5) * 1.6 + (3.0 if k == "kung_truck" else 0.0)
		cam.position = Vector3(d * 0.35, h * 0.6 + d * 0.15, d); cam.look_at(Vector3(0, h * 0.5, 0))
		for f in 3: await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out.path_join("m_%s.png" % k))
		mp.queue_free()
	get_tree().quit()
