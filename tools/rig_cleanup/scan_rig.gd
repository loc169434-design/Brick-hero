extends SceneTree
## Renders the hero rig at canvas size over magenta, for every lab outfit at key poses.
const POSES := [[&"idle", 0.0], [&"idle", 1.2], [&"attack", 0.24], [&"attack", 0.34], [&"attack", 0.5], [&"hurt", 0.08], [&"cheer", 0.22]]

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	var outfits: Array = load("res://scripts/battle/rig_lab.gd").OUTFITS
	var view := SubViewport.new()
	view.size = Vector2i(640, 640)
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var bg := ColorRect.new()
	bg.color = Color(1, 0, 1)
	bg.size = Vector2(640, 640)
	view.add_child(bg)
	var rig := HeroRig.new()
	rig.scale = Vector2.ONE / HeroRig.DRAW_SCALE
	rig.position = Vector2(320, 600)
	view.add_child(rig)
	await process_frame
	rig.set_process(false)
	for o in outfits.size():
		rig.set_outfit(Gear.outfit(outfits[o]["gear"]))
		for p in POSES.size():
			rig.play(POSES[p][0])
			rig._player.speed_scale = 0.0
			rig._player.seek(POSES[p][1], true)
			await process_frame
			await RenderingServer.frame_post_draw
			view.get_texture().get_image().save_png("%s/o%d_p%d.png" % [out, o, p])
	quit()
