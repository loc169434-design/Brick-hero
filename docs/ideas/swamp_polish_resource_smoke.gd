extends SceneTree

var failures := 0

func check(value: bool, description: String) -> void:
	if not value:
		failures += 1
		push_error(description)

func _initialize() -> void:
	var manifest: JSON = load("res://assets/tiles/swamp_b/swamp_manifest.json")
	var art := TileArt.new("swamp_b")
	var colors := ["red", "green", "yellow", "purple"]
	var count := 0
	for e: Dictionary in manifest.data["animations"]:
		var color: int = colors.find(e["color"])
		var clip := StringName(e["animation"])
		check(art.ensure_clip(color, clip), "TileArt loads " + str(e["file"]))
		var frames: SpriteFrames = art.frames(color)
		check(frames.get_frame_count(clip) == int(e["frames"]), "Runtime frame count " + str(clip))
		check(is_equal_approx(frames.get_animation_speed(clip), float(e["fps"])), "Runtime fps " + str(clip))
		check(frames.get_animation_loop(clip) == bool(e["loop"]), "Runtime loop " + str(clip))
		check(is_equal_approx(art.clip_seconds(color, clip), float(e["seconds"])), "Runtime seconds " + str(clip))
		for i in int(e["frames"]):
			var texture := frames.get_frame_texture(clip, i) as AtlasTexture
			check(texture != null, "AtlasTexture exists")
			if texture != null:
				check(texture.get_size() == Vector2(e["cell"], e["cell"]), "Runtime cell padding")
				check(texture.region.end.x <= texture.atlas.get_width() and texture.region.end.y <= texture.atlas.get_height(), "Atlas region stays inside texture")
		count += 1
	for c in range(4):
		var resource := load("res://assets/tiles/swamp_b/sprite_frames_%s.tres" % colors[c]) as SpriteFrames
		check(resource != null, "Exported SpriteFrames loads")
		check(resource.get_animation_names().size() == 12, "Exported SpriteFrames clip count")
		for pose in ["croak", "look_left", "look_right"]:
			var texture := art.expression(c, pose)
			check(texture != null and texture.get_size() == Vector2(128, 128), "New static expression " + pose)
	for family in ["swamp", "goblin_camp"]:
		for layer in ["sky", "far", "mid", "ground"]:
			var texture: Texture2D = load("res://assets/bg/%s/%s.png" % [family, layer])
			check(texture != null and texture.get_size() == Vector2(1080, 660), "Background layer " + family + "/" + layer)
	print("Issue48 smoke: %d clips via TileArt, 4 SpriteFrames, 12 new stills, 8 background layers; %d failures" % [count, failures])
	quit(1 if failures else 0)
