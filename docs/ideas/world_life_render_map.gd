extends SceneTree

var scenes: Array[Dictionary] = []
var moving: Array[Dictionary] = []
var specification: Dictionary

func _initialize() -> void:
	call_deferred("render_all")

func art(parent: Node, texture: Texture2D, at: Vector2, size: Vector2, alpha := 1.0) -> Sprite2D:
	var node := Sprite2D.new()
	node.texture = texture
	node.position = at
	node.scale = size / texture.get_size()
	node.modulate.a = alpha
	parent.add_child(node)
	return node

func clip(parent: Node, name: String, at: Vector2, size: Vector2) -> Sprite2D:
	var entry: Dictionary = specification["textures"][name]
	var texture: Texture2D = load("res://assets/bg/campaign/" + str(entry["file"]))
	var node := art(parent, texture, at, size)
	node.hframes = int(entry["columns"])
	node.vframes = ceili(float(entry["frames"]) / float(entry["columns"]))
	node.scale = size / Vector2(entry["frame_size"][0], entry["frame_size"][1])
	return node

func render_all() -> void:
	var data: JSON = load("res://assets/bg/campaign/ambience.json")
	specification = data.data
	DirAccess.make_dir_recursive_absolute("/workspace/issue49_sources/rendered_map")
	for info in [["village",1,0],["orc_camp",2,750]]:
		var name: String = info[0]
		var segment: int = info[1]
		var viewport := SubViewport.new()
		viewport.size = Vector2i(540,560)
		viewport.world_2d = World2D.new()
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var stage := Node2D.new()
		stage.scale = Vector2.ONE*0.5
		stage.position.y = -float(info[2])*0.5
		viewport.add_child(stage)
		var painting := Image.load_from_file("/workspace/issue49_sources/map_segment_%02d.png" % segment)
		var texture := ImageTexture.create_from_image(painting)
		art(stage,texture,Vector2(540,960),Vector2(1080,1920))
		for entry: Dictionary in specification["smoke"]:
			if int(entry["segment"]) != segment: continue
			var at := Vector2(entry["local_position"][0],entry["local_position"][1])
			moving.append({"kind":"smoke","node":clip(stage,"smoke",at,Vector2.ONE*82),"base":at,"phase":entry["phase"]})
		for entry: Dictionary in specification["water_glint_sources"]:
			if int(entry["segment"]) != segment: continue
			var at := Vector2(entry["local_position"][0],entry["local_position"][1])
			moving.append({"kind":"sparkle","node":clip(stage,"sparkle",at,Vector2.ONE*22),"base":at,"phase":moving.size()*.37})
		for entry: Dictionary in specification["waterfalls"]:
			if int(entry["segment"]) != segment: continue
			var at := Vector2(entry["local_position"][0],entry["local_position"][1])
			var size := Vector2(entry["size_px"][0],entry["size_px"][1])
			moving.append({"kind":"waterfall","node":clip(stage,"waterfall",at,size),"base":at,"phase":entry["phase"]})
		for entry: Dictionary in specification["flags"]:
			if int(entry["segment"]) != segment: continue
			var at := Vector2(entry["local_position"][0],entry["local_position"][1])
			var size := Vector2(entry["size_px"][0],entry["size_px"][1])
			var node := clip(stage,"flag",at,size)
			node.centered = false
			node.position = at-Vector2(64,20)*node.scale
			moving.append({"kind":"flag","node":node,"base":node.position,"phase":entry["phase"]})
		var cloud: Texture2D = load("res://assets/bg/campaign/map_cloud_%d.png" % segment)
		var at := Vector2(720,240 if segment==1 else 1110)
		var shadow := art(stage,cloud,at+Vector2(90,260),Vector2(480,208))
		shadow.modulate = Color(.06,.10,.06,.13)
		moving.append({"kind":"cloud","node":shadow,"base":shadow.position})
		moving.append({"kind":"cloud","node":art(stage,cloud,at,Vector2(480,208),.45),"base":at})
		scenes.append({"name":name,"viewport":viewport})
	for i in range(4): await process_frame
	for i in range(12):
		var time := float(i)/12.0
		for entry: Dictionary in moving:
			var node: Sprite2D = entry["node"]
			var base: Vector2 = entry["base"]
			match entry["kind"]:
				"cloud": node.position=base+Vector2(time*22,0)
				"smoke":
					var phase:=fposmod(time/4.0+float(entry["phase"]),1.0)
					node.position=base+Vector2(sin(phase*TAU)*12,-phase*56)
					node.modulate=Color(.96,.94,.89,.72*sin(phase*PI))
					node.frame=mini(5,int(phase*6))
				"sparkle":
					var phase:=fposmod(time/2.0+float(entry["phase"]),1.0)
					node.position=base+Vector2(0,phase*8)
					node.modulate=Color(.74,.94,1.0,.55*sin(phase*PI))
				"waterfall", "flag": node.frame=(i+int(float(entry["phase"])*6))%6
		await process_frame
		await RenderingServer.frame_post_draw
		for entry: Dictionary in scenes:
			var viewport: SubViewport=entry["viewport"]
			var image:=viewport.get_texture().get_image()
			assert(image.save_png("/workspace/issue49_sources/rendered_map/%s_%02d.png" % [entry["name"],i])==OK)
	print("Rendered24map frames:unchanged segment paintings plus clouds/shadows/smoke/flags/waterfalls/glints.")
	quit()
