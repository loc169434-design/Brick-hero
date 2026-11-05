extends SceneTree
var failures: Array[String] = []
var atlas_count := 0
var animation_count := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var pack: JSON = load("res://assets/tiles/animation_pack.json")
	for entry: Dictionary in pack.data.atlases:
		if entry.family not in ["swamp","swamp_b"]:continue
		var texture: Texture2D = load("res://"+String(entry.file))
		if texture==null or texture.get_width()!=1536 or texture.get_height()!=192:failures.append(String(entry.file))
		atlas_count+=1
	for family in ["swamp","swamp_b"]:
		var art := TileArt.new(family)
		var colors := ["red","green","yellow","purple"]
		for color_index in range(4):
			var color: String = colors[color_index]
			var frames: SpriteFrames = load("res://assets/tiles/%s/sprite_frames_%s.tres" % [family,color])
			if frames==null:
				failures.append(family+"/"+color)
				continue
			if frames.get_animation_names().size()!=12:failures.append("animation count "+family+"/"+color)
			for clip: StringName in frames.get_animation_names():
				if frames.get_frame_count(clip)!=4:failures.append("frame count "+family+"/"+color+"/"+clip)
				if not art.ensure_clip(color_index,clip):failures.append("TileArt clip "+family+"/"+color+"/"+clip)
				if absf(art.clip_seconds(color_index,clip)-4.0/frames.get_animation_speed(clip))>.001:failures.append("TileArt timing "+family+"/"+color+"/"+clip)
				for i in range(4):
					var texture: Texture2D = frames.get_frame_texture(clip,i)
					if texture==null or texture.get_width()!=192:failures.append("frame texture "+family+"/"+color+"/"+clip)
				animation_count+=1
			var tile: Texture2D = load("res://assets/tiles/%s/tile_%s.png" % [family,color])
			if tile==null or tile.get_width()!=128:failures.append("tile "+family+"/"+color)
			var loaded: Texture2D = art.tile(color_index)
			if loaded==null or not loaded.resource_path.contains("/"+family+"/"):failures.append("TileArt tile path "+family+"/"+color)
			if art.expression(color_index,"fear")==null:failures.append("TileArt fear "+family+"/"+color)
	print("Swamp A/B smoke: %d atlases, 8 SpriteFrames, %d animations via TileArt, 8 static128 tiles; %d failures" % [atlas_count,animation_count,failures.size()])
	for failure in failures:printerr(failure)
	quit(0 if failures.is_empty() else 1)
