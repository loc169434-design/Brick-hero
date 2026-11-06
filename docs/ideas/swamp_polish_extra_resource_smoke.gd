extends SceneTree

func _initialize() -> void:
	var count := 0
	for character in ["toad_witch", "orc_shield", "orc_rock", "orc_drummer", "orc_boar"]:
		var clip := "lift" if character == "toad_witch" else "rage"
		var metadata: JSON = load("res://assets/characters/%s/anim/anim.json" % character)
		var entry: Dictionary = metadata.data["clips"][clip]
		var texture: Texture2D = load("res://assets/characters/%s/anim/fresh_%s.png" % [character, clip])
		assert(texture.get_size() == Vector2(2048, 1536))
		assert(int(entry["frames"]) == (12 if clip == "lift" else 10))
		assert(int(entry["fps"]) == (14 if clip == "lift" else 12))
		if clip == "lift":
			assert(int(entry["impact"]) == 6)
		for i in int(entry["frames"]):
			var frame := AtlasTexture.new()
			frame.atlas = texture
			frame.region = Rect2(i % 4 * 512, i / 4 * 512, 512, 512)
			assert(frame.get_width() == 512 and frame.region.end.y <= 1536)
			count += 1
	for pair in [["curse", "levitate"], ["combat/anim", "rage_steam"]]:
		var metadata: JSON = load("res://assets/fx/%s/anim.json" % pair[0])
		var texture: Texture2D = load("res://assets/fx/%s/%s.png" % pair)
		assert(texture.get_size() == Vector2(2048, 1024))
		assert(int(metadata.data[pair[1]]["frames"]) == 8 and metadata.data[pair[1]]["loop"])
		count += 8
	print("Issue48 addendum smoke: %d cels, five actors, two FX atlases; 0 failures" % count)
	quit()
