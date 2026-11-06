extends SceneTree

const FAMILIES := ["training_field", "orc_camp", "swamp", "goblin_camp"]
const HOURS := ["morning", "noon", "dusk", "night"]
var renders: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("render_all")

func sprite(parent: Node, path: String, at: Vector2, tint := Color.WHITE, zoom := 1.0) -> Sprite2D:
	var node := Sprite2D.new()
	node.texture = load(path)
	node.centered = false
	node.position = at
	node.modulate = tint
	node.scale = Vector2.ONE * zoom
	parent.add_child(node)
	return node

func render_all() -> void:
	DirAccess.make_dir_recursive_absolute("/workspace/issue49_sources/rendered")
	for family in FAMILIES:
		var metadata: JSON = load("res://assets/bg/%s/layers.json" % family)
		for hour in HOURS:
			var viewport := SubViewport.new()
			viewport.size = Vector2i(1080, 500)
			viewport.world_2d = World2D.new()
			viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			root.add_child(viewport)
			var stage := Node2D.new()
			viewport.add_child(stage)
			var values: Array = metadata.data["time_lighting"][hour]
			var tint := Color(values[0], values[1], values[2], values[3])
			sprite(stage, "res://assets/bg/%s/sky_%s.png" % [family, hour], Vector2(0, -80))
			for layer in ["far", "mid", "ground"]:
				sprite(stage, "res://assets/bg/%s/%s.png" % [family, layer], Vector2(0, -80), tint)
			for pair in [["hero_rookie", Vector2(270,405)], ["orc_shield", Vector2(810,405)]]:
				sprite(stage, "res://assets/characters/%s/fresh_idle.png" % pair[0], pair[1] - Vector2(256,500)*0.7, tint, 0.7)
			if hour == "night":
				var texture: Texture2D = load("res://assets/fx/weather/red_eyes.png")
				for point: Array in metadata.data["eyes"]:
					var eye := Sprite2D.new()
					eye.texture = texture
					eye.region_enabled = true
					eye.region_rect = Rect2(512,0,256,128)
					eye.scale = Vector2.ONE*0.16
					eye.position = Vector2(point[0],point[1]-80)
					stage.add_child(eye)
			renders.append({"viewport":viewport,"name":family+"_"+hour})
	for i in range(4):
		await process_frame
	await RenderingServer.frame_post_draw
	for result in renders:
		var viewport: SubViewport = result["viewport"]
		var image := viewport.get_texture().get_image()
		assert(not image.is_empty())
		assert(image.save_png("/workspace/issue49_sources/rendered/%s.png" % result["name"]) == OK)
	print("Rendered16day/night battle scenes; unchanged fresh_idle sprites, exact feet/0.7scale, runtime modulation.")
	quit()
