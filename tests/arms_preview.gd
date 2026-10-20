## Быстрый просмотр рук: пустая сцена со светом и стеной, несколько кадров в разных позах.
##   godot --path . --rendering-method gl_compatibility --resolution 800x450 res://tests/arms_preview.tscn -- --out=/папка
extends Node3D

func _ready() -> void:
	var out := "."
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
	var root := self
	var env := WorldEnvironment.new(); env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color(0.25, 0.25, 0.27)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.environment.ambient_light_color = Color(0.3, 0.3, 0.3)
	env.environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	root.add_child(env)
	var sun := DirectionalLight3D.new(); sun.rotation = Vector3(-0.8, 0.6, 0); sun.light_energy = 1.2; root.add_child(sun)
	var floor := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(20, 20); floor.mesh = pm; root.add_child(floor)
	var p := Player.new(); root.add_child(p); p.global_position = Vector3.ZERO
	p.set_physics_process(false)   # пола-коллайдера нет: без этого игрок падает
	var vp := SubViewport.new(); vp.size = Vector2i(384, 256); root.add_child(vp)
	var wr := Wrist.new(); vp.add_child(wr)
	var b := Body.new(); root.add_child(b); b.setup(p, wr, vp.get_texture())
	p.flash_on = true
	if "--rolls" in OS.get_cmdline_user_args():
		for r in [-90, 0, 90, 180]:
			b.roll_r = deg_to_rad(r); b.roll_l = deg_to_rad(r); wr.raised = false
			for i in 20:
				b.update(1.0 / 30.0, p.cam); await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(out.path_join("roll_r_%d.png" % (r + 180)))
			wr.raised = true
			for i in 30:
				b.update(1.0 / 30.0, p.cam); await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(out.path_join("roll_w_%d.png" % (r + 180)))
		get_tree().quit(); return
	for pose in ["rest", "walk", "run", "reach", "wrist"]:
		wr.raised = pose == "wrist"
		p.running_override = pose == "run"
		for i in 40:
			p.speed = 3.6 if pose == "run" else (1.9 if pose == "walk" else 0.0)
			p.bob += 0.12 if pose in ["walk", "run"] else 0.0
			if pose == "reach": b.reach()
			p.head.rotation = Vector3(0, p.yaw, 0)
			b.update(1.0 / 30.0, p.cam)
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		if b.arms_skel and "--debug" in OS.get_cmdline_user_args():
			var sk := b.arms_skel
			var hw := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("DEF-hand.R")).origin
			var sh := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("DEF-upper_arm.R")).origin
			print(pose, " cam ", p.cam.global_position, " wristT ", b.R.global_transform * Vector3(0, 0, 0.07), " hand ", hw, " shoulder ", sh)
		get_viewport().get_texture().get_image().save_png(out.path_join("arms_%s.png" % pose))
	get_tree().quit()
