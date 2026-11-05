extends SceneTree
var failures: Array[String] = []
var clip_count := 0
var texture_count := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var priority := "--priority" in OS.get_cmdline_user_args()
	var ids := ["toad_spitter","goblin_archer"] if priority else ["toad_spitter","goblin_archer","swamp_leech","goblin_thief","goblin_bomber","swamp_spider","frost_slime","crocodile","toad_witch","toad_witch_giant","fairy_fickle","fairy_crow"]
	for id in ids:
		var rig := CharacterRig.new()
		root.add_child(rig)
		rig.setup(id,-1)
		var meta: JSON = load("res://assets/characters/%s/anim/anim.json" % id)
		if meta == null:
			failures.append(id+" metadata missing")
			rig.free()
			continue
		for clip: String in meta.data.clips:
			for wear in 3:
				rig.wear = wear
				if not rig.has_clip(StringName(clip)):
					failures.append("%s/%s wear %d missing" % [id,clip,wear])
			rig._start_clip(StringName(clip))
			if rig._clip_sheet == null:
				failures.append(id+" texture "+clip)
			clip_count += 1
		rig.free()
	if priority:
		print("G2 priority smoke: %d actor clips, 3 wear fallbacks each; %d failures" % [clip_count,failures.size()])
		quit(0 if failures.is_empty() else 1)
		return
	var tile := TileArt.new("swamp")
	for color in 4:
		if tile.tile(color)==null:
			failures.append("tile %d missing" % color)
	for color in ["red","green","yellow","purple"]:
		var frames: SpriteFrames = load("res://assets/tiles/swamp/sprite_frames_%s.tres" % color)
		if frames==null or frames.get_animation_names().size()!=12:
			failures.append(color+" SpriteFrames")
	var manifest: JSON = load("res://assets/tiles/animation_pack.json")
	var tiles := 0
	for entry: Dictionary in manifest.data.atlases:
		if entry.family!="swamp":continue
		if load("res://"+String(entry.file))==null:
			failures.append(String(entry.file))
		tiles += 1
	if tiles!=48:failures.append("expected 48 tile atlases")
	for family in ["swamp","goblin_camp"]:
		for layer in ["sky","far","mid","ground","firefly","bubble","lotus"]:
			if load("res://assets/bg/%s/%s.png" % [family,layer])==null:
				failures.append(family+"/"+layer)
			texture_count += 1
	for id in ["swamp_old_man","bin"]:
		for pose in (["idle","talk","cheer"] if id=="bin" else ["idle","talk"]):
			if load("res://assets/characters/%s/%s.png" % [id,pose])==null:
				failures.append(id+"/"+pose)
	var obstacles: JSON = load("res://assets/board/obstacles/obstacles.json")
	for entry: String in obstacles.data.clips:
		if load("res://assets/board/obstacles/"+entry+".png")==null:
			failures.append(entry)
	if load("res://assets/bg/campaign/segment_03.png")==null:failures.append("map3")
	print("G2 smoke: %d actor clips with 3 wear fallbacks, %d tile atlases, 4 SpriteFrames, %d backdrop/ambient textures; %d failures" % [clip_count,tiles,texture_count,failures.size()])
	for failure in failures:printerr(failure)
	quit(0 if failures.is_empty() else 1)
