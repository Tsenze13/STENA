## Предмет крупно с четырёх сторон: res://tests/console_preview.tscn -- --out=/папка [--scene=res://scenes/props/x.tscn --y=1.0 --dist=1.1]
extends Node3D
func _ready() -> void:
	var out := "."
	var scn := "res://scenes/props/console.tscn"; var y := 1.0; var dd := 1.1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
		if a.begins_with("--scene="): scn = a.substr(8)
		if a.begins_with("--y="): y = a.substr(4).to_float()
		if a.begins_with("--dist="): dd = a.substr(7).to_float()
	var env := WorldEnvironment.new(); env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color(0.3, 0.3, 0.33)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.environment.ambient_light_color = Color(0.6, 0.6, 0.6)
	add_child(env)
	var sun := DirectionalLight3D.new(); sun.rotation = Vector3(-0.7, 0.5, 0); add_child(sun)
	var c: Node3D = load(scn).instantiate(); add_child(c)
	var cam := Camera3D.new(); add_child(cam)
	for v in [["front", Vector3(0, y + 0.25, dd)], ["left", Vector3(-dd, y + 0.25, 0.1)], ["right", Vector3(dd, y + 0.25, 0.1)], ["back", Vector3(0, y + 0.25, -dd)]]:
		cam.position = v[1]; cam.look_at(Vector3(0, y, 0))
		for f in 3: await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(out.path_join("c_%s.png" % v[0]))
	get_tree().quit()
